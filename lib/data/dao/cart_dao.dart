
import 'package:sqflite/sqflite.dart';
import '../../models/cart.dart';
import '../db/app_database.dart';
import '../../models/cart.dart' show CartItem, CartState;

class CartDao {
  static final CartDao instance = CartDao._internal();
  CartDao._internal();

  Future<Database> get _db async => await AppDatabase.instance.database;

  Future<CartState> getCart(String userId) async {
    final items = await getCartItems(userId);

    String? appliedPromoId;
    double discount = 0.0;
    if (items.isNotEmpty) {
      appliedPromoId = items.first.appliedPromoId;
      discount = items.first.discount;
    }

    return CartState(
      items: items,
      appliedPromoId: appliedPromoId,
      discount: discount,
    );
  }

  Future<List<CartItem>> getCartItems(String userId) async {
    final db = await _db;
    final result = await db.query(
      'cart_items',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    return result.map((e) => CartItem.fromMap(e)).toList();
  }

  Future<void> upsertItem(CartItem item) async {
    final db = await _db;

    final existing = await db.query(
      'cart_items',
      where: 'userId = ? AND productId = ?',
      whereArgs: [item.userId, item.productId],
    );

    if (existing.isNotEmpty) {
      final currentQuantity = existing.first['quantity'] as int;
      await db.update(
        'cart_items',
        {
          'quantity': currentQuantity + item.quantity,
          'updatedAt': DateTime.now().toIso8601String(),
          'appliedPromoId': item.appliedPromoId,
          'discount': item.discount,
        },
        where: 'userId = ? AND productId = ?',
        whereArgs: [item.userId, item.productId],
      );
    } else {
      await db.insert(
        'cart_items',
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> updatePromoDetails(String userId, String? promoId, double discount) async {
    final db = await _db;
    await db.update(
      'cart_items',
      {
        'appliedPromoId': promoId,
        'discount': discount,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  Future<void> updateItemQuantity({
    required String userId,
    required String productId,
    required int newQuantity,
  }) async {
    if (newQuantity <= 0) {
      await deleteItem(userId, productId);
      return;
    }

    final db = await _db;
    await db.update(
      'cart_items',
      {
        'quantity': newQuantity,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'userId = ? AND productId = ?',
      whereArgs: [userId, productId],
    );
  }

  Future<void> deleteItem(String userId, String productId) async {
    final db = await _db;
    await db.delete(
      'cart_items',
      where: 'userId = ? AND productId = ?',
      whereArgs: [userId, productId],
    );
  }

  Future<void> clearCart(String userId) async {
    final db = await _db;
    await db.delete(
      'cart_items',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  Future<int> getCartItemCount(String userId) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT SUM(quantity) as count FROM cart_items WHERE userId = ?',
      [userId],
    );
    return result.first['count'] as int? ?? 0;
  }
}