import '../../../data/db/app_database.dart';
import '../../models/order.dart';

class OrderDao {
  Future<int> insert(Order order) async {
    final db = await AppDatabase.instance.database;
    return await db.insert('orders', order.toMap());
  }

  Future<List<Order>> getAll() async {
    final db = await AppDatabase.instance.database;
    final results = await db.query('orders', orderBy: 'orderDate DESC');
    return results.map((e) => Order.fromMap(e)).toList();
  }

  Future<List<Order>> getByUserId(int userId) async {
    final db = await AppDatabase.instance.database;
    final results = await db.query(
      'orders',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'orderDate DESC',
    );
    return results.map((e) => Order.fromMap(e)).toList();
  }

  Future<Order?> getById(int id) async {
    final db = await AppDatabase.instance.database;
    final results = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isNotEmpty) {
      return Order.fromMap(results.first);
    }
    return null;
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

  Future<int> updateStatus(int id, String status) async {
    final db = await AppDatabase.instance.database;
    return await db.update(
      'orders',
      {'status': status},
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
      orderBy: 'orderDate DESC',
    );
    return results.map((e) => Order.fromMap(e)).toList();
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