import 'package:uuid/uuid.dart';
import '../../../data/db/app_database.dart';
import '../../models/order.dart';
import '../../models/cart.dart';

class OrderDao {
  final Uuid _uuid = const Uuid();
  Future<String> insert(Order order) async {
    final db = await AppDatabase.instance.database;
    
    // Start a transaction
    return await db.transaction<String>((txn) async {
      // First, insert the order
      await txn.insert('orders', order.toMap());
      
      // Then insert all order items
      if (order.items.isNotEmpty) {
        final batch = txn.batch();
        
        for (final item in order.items) {
          batch.insert('order_items', {
            'id': _uuid.v4(),
            'orderId': order.id,
            'productId': item.productId,
            'productName': item.productName,
            'price': item.price,
            'quantity': item.quantity,
            'imageUrl': item.imageUrl,
          });
        }
        
        await batch.commit(noResult: true);
      }
      
      return order.id;
    });
  }

  Future<List<Order>> getAll() async {
    final db = await AppDatabase.instance.database;
    final orders = await db.query('orders', orderBy: 'createdAt DESC');
    
    if (orders.isEmpty) return [];
    
    // Get all order items for these orders in a single query
    final orderIds = orders.map((o) => o['id'] as String).toList();
    final allItems = <String, List<Map<String, dynamic>>>{};
    
    final items = await db.query(
      'order_items',
      where: 'orderId IN (${List.filled(orderIds.length, '?').join(',')})',
      whereArgs: orderIds,
    );
    
    // Group items by orderId
    for (final item in items) {
      final orderId = item['orderId'] as String;
      allItems.putIfAbsent(orderId, () => []).add(item);
    }
    
    // Combine orders with their items using Order.fromMap with items parameter
    return orders.map((orderMap) {
      final orderId = orderMap['id'] as String;
      final orderItems = allItems[orderId] ?? [];
      
      return Order.fromMap(
        orderMap,
        items: orderItems.map((item) => OrderItem(
          id: item['id'] as String,
          orderId: item['orderId'] as String,
          productId: item['productId'] as String,
          productName: item['productName'] as String,
          price: (item['price'] as num).toDouble(),
          quantity: item['quantity'] as int,
          imageUrl: item['imageUrl'] as String?,
        )).toList(),
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
    
    if (orders.isEmpty) return [];
    
    // Get all order items for these orders in a single query
    final orderIds = orders.map((o) => o['id'] as String).toList();
    final allItems = <String, List<Map<String, dynamic>>>{};
    
    final items = await db.query(
      'order_items',
      where: 'orderId IN (${List.filled(orderIds.length, '?').join(',')})',
      whereArgs: orderIds,
    );
    
    // Group items by orderId
    for (final item in items) {
      final orderId = item['orderId'] as String;
      allItems.putIfAbsent(orderId, () => []).add(item);
    }
    
    // Combine orders with their items using Order.fromMap with items parameter
    return orders.map((orderMap) {
      final orderId = orderMap['id'] as String;
      final orderItems = allItems[orderId] ?? [];
      
      return Order.fromMap(
        orderMap,
        items: orderItems.map((item) => OrderItem(
          id: item['id'] as String,
          orderId: item['orderId'] as String,
          productId: item['productId'] as String,
          productName: item['productName'] as String,
          price: (item['price'] as num).toDouble(),
          quantity: item['quantity'] as int,
          imageUrl: item['imageUrl'] as String?,
        )).toList(),
      );
    }).toList();
  }

  Future<Order?> getById(String id) async {
    final db = await AppDatabase.instance.database;
    
    // Get the order first
    final orderResults = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (orderResults.isEmpty) return null;
    
    // Get the order items
    final itemsResults = await db.query(
      'order_items',
      where: 'orderId = ?',
      whereArgs: [id],
    );
    
    // Convert results to OrderItem objects
    final items = itemsResults.map((itemMap) => OrderItem(
      id: itemMap['id'] as String,
      orderId: itemMap['orderId'] as String,
      productId: itemMap['productId'] as String,
      productName: itemMap['productName'] as String,
      price: (itemMap['price'] as num).toDouble(),
      quantity: itemMap['quantity'] as int,
      imageUrl: itemMap['imageUrl'] as String?,
    )).toList();
    
    // Create order with items using Order.fromMap with items parameter
    return Order.fromMap(orderResults.first, items: items);
  }

  Future<int> update(Order order) async {
    final db = await AppDatabase.instance.database;
    return await db.update(
      'orders',
      order.toMap(),
      where: 'id = ?',
      whereArgs: [order.id],
    );
  }

  Future<int> updateStatus(String id, String status) async {
    final db = await AppDatabase.instance.database;
    return await db.update(
      'orders',
      {
        'status': status,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateTrackingNumber(String orderId, String trackingNumber) async {
    final db = await AppDatabase.instance.database;
    return await db.update(
      'orders',
      {
        'trackingNumber': trackingNumber,
        'status': 'shipped',
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  Future<List<Order>> getByStatus(String status) async {
    final db = await AppDatabase.instance.database;
    final results = await db.query(
      'orders',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'createdAt DESC',
    );
    return results.map(Order.fromMap).toList();
  }

  Future<int> delete(String id) async {
    final db = await AppDatabase.instance.database;
    return await db.delete(
      'orders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }


}
