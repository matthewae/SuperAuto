import 'package:sqflite/sqflite.dart';
import '../../models/service_booking.dart';
import 'dart:convert';

class ServiceBookingDao {
  final Database db;
  ServiceBookingDao(this.db);

  Future<void> cacheBooking(ServiceBooking booking) async {
    print('Caching booking: ${booking.id} for user: ${booking.userId}');
    await db.insert(
      'service_bookings',
      booking.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('Booking cached successfully');
  }

  Future<List<ServiceBooking>> getAllCachedBookings() async {
    print('Getting all cached bookings...');
    final results = await db.query(
      'service_bookings',
      orderBy: 'scheduledAt DESC',
    );
    print('Found ${results.length} cached bookings');
    return results.map((e) => ServiceBooking.fromMap(e)).toList();
  }

  Future<List<ServiceBooking>> getCachedBookingsByUserId(String userId) async {
    print('Getting cached bookings for user: $userId');
    final results = await db.query(
      'service_bookings',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'scheduledAt DESC',
    );
    print('Found ${results.length} bookings for user $userId');
    return results.map((e) => ServiceBooking.fromMap(e)).toList();
  }

  Future<void> clearAllCache() async {
    print('Clearing all booking cache...');
    await db.delete('service_bookings');
    print('All booking cache cleared');
  }

  Future<void> clearCacheForUser(String userId) async {
    print('Clearing booking cache for user: $userId');
    await db.delete(
      'service_bookings',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    print('Cache cleared for user $userId');
  }

  Future<ServiceBooking?> getById(String id) async {
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

  Future<List<ServiceBooking>> getByUserId(String userId) async {
    return await getCachedBookingsByUserId(userId);
  }
  Future<List<ServiceBooking>> getAll() async {
    return await getAllCachedBookings();
  }

  Future<int> delete(String id) async {
    print('Deleting booking from cache: $id');
    final result = await db.delete(
      'service_bookings',
      where: 'id = ?',
      whereArgs: [id],
    );
    print('Booking deleted from cache');
    return result;
  }

  Future<int> update(ServiceBooking booking) async {
    print('Updating booking in cache: ${booking.id}');
    final result = await db.update(
      'service_bookings',
      booking.toMap(),
      where: 'id = ?',
      whereArgs: [booking.id],
    );
    print('Booking updated in cache');
    return result;
  }

  Future<int> updateStatusAndDetails(ServiceBooking booking) async {
    print('Updating booking status and details: ${booking.id}');
    final result = await db.update(
      'service_bookings',
      {
        'status': booking.status,
        'jobs': jsonEncode(booking.jobs),
        'parts': jsonEncode(booking.parts),
        'km': booking.km,
        'totalCost': booking.totalCost,
        'adminNotes': booking.adminNotes,
        'statusHistory': jsonEncode(booking.statusHistory ?? []),
        'updatedAt': booking.updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [booking.id],
    );
    print('Booking status and details updated');
    return result;
  }

  Future<void> debugPrintAllBookings() async {
    final results = await db.query('service_bookings');
    print('ALL BOOKINGS IN CACHE (${results.length}) ===');
    for (var item in results) {
      print('      ID: ${item['id']}');
      print('      User: ${item['userId']}');
      print('      Status: ${item['status']}');
      print('      Service: ${item['serviceType']}');
      print('      Scheduled: ${item['scheduledAt']}');
      print('   ---');
    }
  }

  Future<int> insert(ServiceBooking booking) async {
    await cacheBooking(booking);
    return 1;
  }
}