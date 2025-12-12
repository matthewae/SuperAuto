import '../../../data/db/app_database.dart';
import '../../models/service_booking.dart';
import 'dart:developer' as developer;
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../models/promo.dart';

class ServiceBookingDao {
  final Database db;

  ServiceBookingDao(this.db);
  static const String _tableName = 'service_bookings';

  void _log(String message, {bool isError = false}) {
    if (isError) {
      developer.log('❌ ServiceBookingDao: $message', error: message);
    } else {
      developer.log('ℹ️ ServiceBookingDao: $message');
    }
  }

  Future<int> insert(ServiceBooking booking) async {
    try {
      final db = await AppDatabase.instance.database;

      // Calculate final cost with promo discount
      double finalCost = booking.estimatedCost;
      if (booking.promoId != null) {
        final promoResult = await db.query(
          'promo',
          where: 'id = ? AND type = ? AND start <= ? AND end >= ?',
          whereArgs: [
            booking.promoId,
            'service_discount',
            DateTime.now().toIso8601String(),
            DateTime.now().toIso8601String(),
          ],
        );

        if (promoResult.isNotEmpty) {
          final promo = Promo.fromMap(promoResult.first);
          final discount = promo.calculateDiscount(finalCost);
          finalCost = finalCost - discount;
        }
      }

      // Create a new booking with the calculated final cost
      final updatedBooking = booking.copyWith(totalCost: finalCost);

      final id = await db.insert(
        _tableName,
        updatedBooking.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      _log('Inserted booking ${booking.id} with final cost $finalCost');
      return id;
    } catch (e, stack) {
      _log('Error inserting booking: $e\n$stack', isError: true);
      rethrow;
    }
  }

  Future<List<ServiceBooking>> getAll() async {
    try {
      final db = await AppDatabase.instance.database;
      final results = await db.query(
        _tableName,
        orderBy: 'scheduledAt DESC',
      );
      _log('Fetched ${results.length} bookings');
      return results.map((e) => ServiceBooking.fromMap(e)).toList();
    } catch (e, stack) {
      _log('Error fetching bookings: $e\n$stack', isError: true);
      rethrow;
    }
  }

  Future<void> debugPrintAllBookings() async {
    try {
      final db = await AppDatabase.instance.database;
      final results = await db.query(_tableName);
      _log('=== BOOKINGS IN DATABASE (${results.length}) ===');
      for (var item in results) {
        _log('Booking: ${item['id']} - ${item['status']} - Est: ${item['estimatedCost']} - Total: ${item['totalCost']}');
      }
    } catch (e) {
      _log('Error printing bookings: $e', isError: true);
    }
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

  Future<int> updateStatusAndDetails(ServiceBooking booking) async {
    try {
      // Calculate final cost with promo discount
      double finalCost = booking.estimatedCost;
      if (booking.promoId != null) {
        final promoResult = await db.query(
          'promo',
          where: 'id = ? AND type = ? AND start <= ? AND end >= ?',
          whereArgs: [
            booking.promoId,
            'service_discount',
            DateTime.now().toIso8601String(),
            DateTime.now().toIso8601String(),
          ],
        );

        if (promoResult.isNotEmpty) {
          final promo = Promo.fromMap(promoResult.first);
          final discount = promo.calculateDiscount(finalCost);
          finalCost = finalCost - discount;
        }
      }

      // Create a new booking with the calculated final cost
      final updatedBooking = booking.copyWith(totalCost: finalCost);

      final result = await db.update(
        'service_bookings',
        {
          'status': updatedBooking.status,
          'jobs': jsonEncode(updatedBooking.jobs),
          'parts': jsonEncode(updatedBooking.parts),
          'km': updatedBooking.km,
          'totalCost': updatedBooking.totalCost,
          'adminNotes': updatedBooking.adminNotes,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [updatedBooking.id],
      );
      _log('Updated booking ${updatedBooking.id} with status ${updatedBooking.status} and final cost $finalCost');
      return result;
    } catch (e, stack) {
      _log('Error updating booking: $e\n$stack', isError: true);
      rethrow;
    }
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

  // Method to calculate final cost with promo discount
  Future<double> calculateFinalCost(String bookingId) async {
    try {
      final booking = await getById(bookingId);
      if (booking == null) return 0.0;

      // Use totalCost if available, otherwise use estimatedCost
      double baseCost = booking.totalCost ?? booking.estimatedCost ?? 0.0;
      
      // If totalCost is already set, return it directly without applying promo
      if (booking.totalCost != null) {
        return baseCost;
      }

      // Only apply promo if we're using estimatedCost
      if (booking.promoId != null && baseCost > 0) {
        final db = await AppDatabase.instance.database;
        final result = await db.query(
          'promo',
          where: 'id = ? AND type = ? AND start <= ? AND end >= ?',
          whereArgs: [
            booking.promoId,
            'service_discount',
            DateTime.now().toIso8601String(),
            DateTime.now().toIso8601String(),
          ],
        );

        if (result.isNotEmpty) {
          final promo = Promo.fromMap(result.first);
          final discount = promo.calculateDiscount(baseCost);
          baseCost = baseCost - discount;
        }
      }

      return baseCost;
    } catch (e, stack) {
      _log('Error calculating final cost: $e\n$stack', isError: true);
      rethrow;
    }
  }

  // Method to calculate discount amount
  Future<double> calculateDiscount(String bookingId) async {
    try {
      final booking = await getById(bookingId);
      if (booking == null || booking.estimatedCost == null || booking.promoId == null) return 0.0;

      final db = await AppDatabase.instance.database;
      final result = await db.query(
        'promo',
        where: 'id = ? AND type = ? AND start <= ? AND end >= ?',
        whereArgs: [
          booking.promoId,
          'service_discount',
          DateTime.now().toIso8601String(),
          DateTime.now().toIso8601String(),
        ],
      );

      if (result.isNotEmpty) {
        final promo = Promo.fromMap(result.first);
        return promo.calculateDiscount(booking.estimatedCost!);
      }

      return 0.0;
    } catch (e, stack) {
      _log('Error calculating discount: $e\n$stack', isError: true);
      rethrow;
    }
  }
}