import 'package:sqflite/sqflite.dart';
import '../../models/cart.dart';
import '../db/app_database.dart';
import '../../models/cart.dart' show CartItem, CartState;
class CartDao {
  static final CartDao instance = CartDao._internal();
  CartDao._internal();

  Future<Database> get _db async => await AppDatabase.instance.database;

  /// Get a user's cart with all items
  /// Get a user's cart with all items as CartState
  Future<CartState> getCart(String userId) async {
    final items = await getCartItems(userId);
    return CartState(items: items);
  }

  /// Get all cart items for a user
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

  /// Add or update an item in the cart
  Future<void> upsertItem(CartItem item) async {
    final db = await _db;

    // Check if item already exists
    final existing = await db.query(
      'cart_items',
      where: 'userId = ? AND productId = ?',
      whereArgs: [item.userId, item.productId],
    );

    if (existing.isNotEmpty) {
      // Update quantity if item exists
      final currentQuantity = existing.first['quantity'] as int;
      await db.update(
        'cart_items',
        {
          'quantity': currentQuantity + item.quantity,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'userId = ? AND productId = ?',
        whereArgs: [item.userId, item.productId],
      );
    } else {
      // Insert new item
      await db.insert(
        'cart_items',
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// Update item quantity
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

  /// Remove an item from cart
  Future<void> deleteItem(String userId, String productId) async {
    final db = await _db;
    await db.delete(
      'cart_items',
      where: 'userId = ? AND productId = ?',
      whereArgs: [userId, productId],
    );
  }

  /// Clear all items from user's cart
  Future<void> clearCart(String userId) async {
    final db = await _db;
    await db.delete(
      'cart_items',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  /// Get the count of items in cart
  Future<int> getCartItemCount(String userId) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT SUM(quantity) as count FROM cart_items WHERE userId = ?',
      [userId],
    );
    return result.first['count'] as int? ?? 0;
  }
}
