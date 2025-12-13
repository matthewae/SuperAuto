
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/dao/cart_dao.dart';
import '../models/cart.dart' show CartItem, CartState;

class CartService {
  final SupabaseClient client;
  final CartDao cartDao;

  CartService({required this.client, required this.cartDao});

  // Mengambil keranjang dari Supabase dan menyinkronkannya ke cache lokal
  Future<CartState> fetchAndCacheCart(String userId) async {
    try {
      final response = await client
          .from('cart_items')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final List<CartItem> items = (response as List)
          .map((itemJson) => _mapSupabaseToCartItem(itemJson))
          .toList();

      // Bersihkan cache lama dan simpan yang baru
      await cartDao.clearCart(userId);
      for (final item in items) {
        await cartDao.upsertItem(item);
      }

      // Buat CartState dari item-item yang diambil
      String? promoId;
      double discount = 0.0;
      if (items.isNotEmpty) {
        promoId = items.first.appliedPromoId;
        discount = items.first.discount;
      }

      return CartState(
        items: items,
        appliedPromoId: promoId,
        discount: discount,
      );
    } catch (e) {
      print('Error fetching cart from Supabase: $e');
      rethrow;
    }
  }

  // Sinkronkan detail promo dari Supabase ke cache lokal
  Future<void> syncPromoDetails(String userId) async {
    try {
      // Dapatkan item keranjang dari Supabase
      final response = await client
          .from('cart_items')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1); // Cukup ambil satu item untuk mendapatkan detail promo

      if (response.isNotEmpty) {
        final item = response.first;
        final promoId = item['applied_promo_id'] as String?;
        final discount = (item['discount'] as num?)?.toDouble() ?? 0.0;

        // Update local cache dengan promo details
        await cartDao.updatePromoDetails(userId, promoId, discount);
      }
    } catch (e) {
      print('Error syncing promo details: $e');
    }
  }

  // Menambah item ke Supabase dan cache
  Future<void> addItem(CartItem item) async {
    final existing = await client
        .from('cart_items')
        .select('id, quantity')
        .eq('user_id', item.userId)
        .eq('product_id', item.productId)
        .maybeSingle();

    if (existing != null) {
      await client
          .from('cart_items')
          .update({
        'quantity': (existing['quantity'] as int) + item.quantity,
        'updated_at': DateTime.now().toIso8601String(),
        'applied_promo_id': item.appliedPromoId,
        'discount': item.discount,
      })
          .eq('id', existing['id']);
    } else {
      await client.from('cart_items').insert({
        'user_id': item.userId,
        'product_id': item.productId,
        'product_name': item.productName,
        'price': item.price,
        'quantity': item.quantity,
        'image_url': item.imageUrl,
        'created_at': DateTime.now().toIso8601String(),
        'applied_promo_id': item.appliedPromoId,
        'discount': item.discount,
      });
    }

    await cartDao.upsertItem(item);
  }

  // Mengupdate quantity item di Supabase dan cache
  Future<void> updateItemQuantity({
    required String userId,
    required String productId,
    required int newQuantity,
  }) async {
    try {
      if (newQuantity <= 0) {
        await removeItem(userId, productId);
        return;
      }

      await client
          .from('cart_items')
          .update({
        'quantity': newQuantity,
        'updated_at': DateTime.now().toIso8601String()
      })
          .eq('user_id', userId)
          .eq('product_id', productId);

      await cartDao.updateItemQuantity(
        userId: userId,
        productId: productId,
        newQuantity: newQuantity,
      );
    } catch (e) {
      print('Error updating item quantity in Supabase: $e');
      rethrow;
    }
  }

  // Menghapus item dari Supabase dan cache
  Future<void> removeItem(String userId, String productId) async {
    try {
      await client
          .from('cart_items')
          .delete()
          .eq('user_id', userId)
          .eq('product_id', productId);

      await cartDao.deleteItem(userId, productId);
    } catch (e) {
      print('Error removing item from cart in Supabase: $e');
      rethrow;
    }
  }

  // Mengosongkan keranjang di Supabase dan cache
  Future<void> clearCart(String userId) async {
    try {
      await client.from('cart_items').delete().eq('user_id', userId);

      await cartDao.clearCart(userId);
    } catch (e) {
      print('Error clearing cart in Supabase: $e');
      rethrow;
    }
  }

  // Apply promo to all items in cart
  Future<void> applyPromoToCart(String userId, String? promoId, double discount) async {
    try {
      if (promoId == null) {
        // Remove promo from all items
        await client
            .from('cart_items')
            .update({
          'applied_promo_id': null,
          'discount': 0.0,
          'updated_at': DateTime.now().toIso8601String(),
        })
            .eq('user_id', userId);
      } else {
        // Apply promo to all items
        await client
            .from('cart_items')
            .update({
          'applied_promo_id': promoId,
          'discount': discount,
          'updated_at': DateTime.now().toIso8601String(),
        })
            .eq('user_id', userId);
      }

      // Update local cache
      await cartDao.updatePromoDetails(userId, promoId, discount);
    } catch (e) {
      print('Error applying promo to cart: $e');
      rethrow;
    }
  }

  // --- Helper Functions ---
  CartItem _mapSupabaseToCartItem(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as int?,
      userId: json['user_id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      appliedPromoId: json['applied_promo_id'] as String?,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}