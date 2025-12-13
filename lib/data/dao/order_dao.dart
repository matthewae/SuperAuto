import 'package:uuid/uuid.dart';
import '../db/app_database.dart';
import '../../models/order.dart';
import 'package:sqflite/sqflite.dart';

class OrderDao {
  final Uuid _uuid = const Uuid();

  Future<String> insert(Order order) async {
    final db = await AppDatabase.instance.database;

    print('Inserting order to local database: ${order.id}');

    return await db.transaction<String>((txn) async {
      final existingOrder = await txn.query(
        'orders',
        where: 'id = ?',
        whereArgs: [order.id],
      );

      if (existingOrder.isNotEmpty) {
        print('Order already exists, skipping insert: ${order.id}');
      } else {
        print('Inserting new order: ${order.id}');
        await txn.insert(
          'orders',
          order.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }

      if (order.items.isNotEmpty) {
        final batch = txn.batch();

        for (final item in order.items) {
          final existingItem = await txn.query(
            'order_items',
            where: 'orderId = ? AND productId = ?',
            whereArgs: [order.id, item.productId],
          );

          if (existingItem.isNotEmpty) {
            print('Order item already exists, skipping: order ${order.id}, product ${item.productId}');
            continue;
          }

          batch.insert(
            'order_items',
            {
              'id': _uuid.v4(),
              'orderId': order.id,
              'productId': item.productId,
              'productName': item.productName,
              'price': item.price,
              'quantity': item.quantity,
              'imageUrl': item.imageUrl,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }

        await batch.commit(noResult: true);
      }

      return order.id;
    });
  }

  Future<List<Order>> getAll() async {
    final db = await AppDatabase.instance.database;
    final orders = await db.query('orders', orderBy: 'createdAt DESC');
    print('Found ${orders.length} orders in local database (getAll)');

    if (orders.isEmpty) return [];

    final orderIds = orders.map((o) => o['id'] as String).toList();
    final allItems = <String, List<Map<String, dynamic>>>{};

    final items = await db.query(
      'order_items',
      where: 'orderId IN (${List.filled(orderIds.length, '?').join(',')})',
      whereArgs: orderIds,
    );

    for (final item in items) {
      final orderId = item['orderId'] as String;
      allItems.putIfAbsent(orderId, () => []).add(item);
    }

    return orders.map((orderMap) {
      final orderId = orderMap['id'] as String;
      final orderItems = allItems[orderId] ?? [];
      return Order.fromMap(
        orderMap,
        items: orderItems.map((item) => OrderItem.fromMap(item)).toList(),
      );
    }).toList();
  }

  Future<List<Order>> getByUserId(String userId) async {
    final db = await AppDatabase.instance.database;
    final orders = await db.query(
      'orders',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );

    print('Found ${orders.length} orders for user $userId in local database');

    if (orders.isEmpty) return [];

    final orderIds = orders.map((o) => o['id'] as String).toList();
    final allItems = <String, List<Map<String, dynamic>>>{};

    final items = await db.query(
      'order_items',
      where: 'orderId IN (${List.filled(orderIds.length, '?').join(',')})',
      whereArgs: orderIds,
    );

    for (final item in items) {
      final orderId = item['orderId'] as String;
      allItems.putIfAbsent(orderId, () => []).add(item);
    }

    return orders.map((orderMap) {
      final orderId = orderMap['id'] as String;
      final orderItems = allItems[orderId] ?? [];
      return Order.fromMap(
        orderMap,
        items: orderItems.map((item) => OrderItem.fromMap(item)).toList(),
      );
    }).toList();
  }

  Future<Order?> getById(String id) async {
    final db = await AppDatabase.instance.database;
    final orderResults = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (orderResults.isEmpty) {
      print('Order not found in local database: $id');
      return null;
    }

    final itemsResults = await db.query(
      'order_items',
      where: 'orderId = ?',
      whereArgs: [id],
    );

    final items = itemsResults.map((itemMap) => OrderItem.fromMap(itemMap)).toList();
    return Order.fromMap(orderResults.first, items: items);
  }

  Future<int> update(Order order) async {
    final db = await AppDatabase.instance.database;
    final count = await db.update(
      'orders',
      order.toMap(),
      where: 'id = ?',
      whereArgs: [order.id],
    );
    print('Updated order ${order.id}, rows affected: $count');
    return count;
  }

  Future<int> updateStatus(String id, String status) async {
    final db = await AppDatabase.instance.database;
    final count = await db.update(
      'orders',
      {
        'status': status,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    print('Updated status for order $id to $status');
    return count;
  }

  Future<int> updateTrackingNumber(String orderId, String trackingNumber) async {
    final db = await AppDatabase.instance.database;
    final count = await db.update(
      'orders',
      {
        'trackingNumber': trackingNumber,
        'status': 'shipped',
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [orderId],
    );
    print('Updated tracking number for order $orderId');
    return count;
  }

  Future<List<Order>> getByStatus(String status) async {
    final db = await AppDatabase.instance.database;
    final results = await db.query(
      'orders',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'createdAt DESC',
    );
    return results.map((map) => Order.fromMap(map)).toList();
  }

  Future<int> delete(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('order_items', where: 'orderId = ?', whereArgs: [id]);
    final count = await db.delete('orders', where: 'id = ?', whereArgs: [id]);
    print('Deleted order $id');
    return count;
  }

  Future<void> clearAllOrders() async {
    final db = await AppDatabase.instance.database;
    await db.delete('order_items');
    await db.delete('orders');
    print('Cleared all orders from local database');
  }
}