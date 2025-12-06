import '../../../data/db/app_database.dart';
import '../../models/service_booking.dart';

class ServiceBookingDao {
  Future<int> insert(ServiceBooking booking) async {
    final db = await AppDatabase.instance.database;
    return await db.insert('service_bookings', booking.toMap());
  }

  Future<List<ServiceBooking>> getAll() async {
    final db = await AppDatabase.instance.database;
    final results = await db.query('service_bookings', orderBy: 'scheduledAt DESC');
    return results.map((e) => ServiceBooking.fromMap(e)).toList();
  }

  Future<List<ServiceBooking>> getByUserId(String userId) async {
    final db = await AppDatabase.instance.database;
    final results = await db.query(
      'service_bookings',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'scheduledAt DESC',
    );
    return results.map((e) => ServiceBooking.fromMap(e)).toList();
  }

  Future<ServiceBooking?> getById(String id) async {
    final db = await AppDatabase.instance.database;
    final results = await db.query(
      'service_bookings',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isNotEmpty) {
      return ServiceBooking.fromMap(results.first);
    }
    return null;
  }

  Future<int> update(ServiceBooking booking) async {
    final db = await AppDatabase.instance.database;
    return await db.update(
      'service_bookings',
      {
        ...booking.toMap(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [booking.id],
    );
  }

  Future<int> updateStatus(String id, String status) async {
    final db = await AppDatabase.instance.database;
    return await db.update(
      'service_bookings',
      {
        'status': status,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<ServiceBooking>> getByStatus(String status) async {
    final db = await AppDatabase.instance.database;
    final results = await db.query(
      'service_bookings',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'scheduledAt ASC',
    );
    return results.map((e) => ServiceBooking.fromMap(e)).toList();
  }

  Future<List<ServiceBooking>> getUpcoming() async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now();
    final results = await db.query(
      'service_bookings',
      where: 'scheduledAt >= ?',
      whereArgs: [now.toIso8601String()],
      orderBy: 'scheduledAt ASC',
    );
    return results.map((e) => ServiceBooking.fromMap(e)).toList();
  }

  Future<List<ServiceBooking>> getToday() async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final results = await db.query(
      'service_bookings',
      where: 'scheduledAt >= ? AND scheduledAt < ?',
      whereArgs: [
        today.toIso8601String(),
        tomorrow.toIso8601String(),
      ],
      orderBy: 'scheduledAt ASC',
    );
    return results.map((e) => ServiceBooking.fromMap(e)).toList();
  }

  Future<List<ServiceBooking>> getByCarId(String carId) async {
    final db = await AppDatabase.instance.database;
    final results = await db.query(
      'service_bookings',
      where: 'carId = ?',
      whereArgs: [carId],
      orderBy: 'scheduledAt DESC',
    );
    return results.map((e) => ServiceBooking.fromMap(e)).toList();
  }

  Future<int> delete(String id) async {
    final db = await AppDatabase.instance.database;
    return await db.delete(
      'service_bookings',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}