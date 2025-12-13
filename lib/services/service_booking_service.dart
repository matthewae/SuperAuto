
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/dao/service_booking_dao.dart';
import '../models/service_booking.dart';
import 'package:uuid/uuid.dart';

class ServiceBookingService {
  final SupabaseClient client;
  final ServiceBookingDao dao;

  ServiceBookingService({required this.client, required this.dao});

  // ✅ Fetch ALL bookings (untuk admin)
  Future<List<ServiceBooking>> fetchAndCacheAllBookings() async {
    try {
      print('🔄 [ADMIN] Fetching all bookings from Supabase...');

      final response = await client
          .from('service_bookings')
          .select()
          .order('scheduled_at', ascending: false);

      final List<ServiceBooking> bookings = (response as List)
          .map((json) => mapSupabaseToBooking(json))
          .toList();

      print('✅ [ADMIN] Fetched ${bookings.length} bookings from Supabase');

      // Clear all cache and save new data
      await dao.clearAllCache();
      for (final booking in bookings) {
        await dao.cacheBooking(booking);
      }

      print('✅ [ADMIN] All bookings cached successfully');
      return bookings;
    } catch (e) {
      print('❌ [ADMIN] Error fetching all bookings: $e');
      // Fallback to cache
      return await dao.getAllCachedBookings();
    }
  }

  // ✅ Fetch user bookings (untuk user biasa)
  Future<List<ServiceBooking>> fetchAndCacheBookings(String userId) async {
    try {
      print('🔄 [USER] Fetching bookings for user: $userId');

      final response = await client
          .from('service_bookings')
          .select()
          .eq('user_id', userId)
          .order('scheduled_at', ascending: false);

      final List<ServiceBooking> bookings = (response as List)
          .map((json) => mapSupabaseToBooking(json))
          .toList();

      print('✅ [USER] Fetched ${bookings.length} bookings from Supabase');

      // Hapus cache lama user ini dan simpan yang baru
      await dao.clearCacheForUser(userId);
      for (final booking in bookings) {
        await dao.cacheBooking(booking);
      }

      print('✅ [USER] User bookings cached successfully');
      return bookings;
    } catch (e) {
      print('❌ [USER] Error fetching bookings: $e');
      // Fallback to cache
      return await dao.getCachedBookingsByUserId(userId);
    }
  }

  // ✅ Add booking
  Future<ServiceBooking> addBooking(ServiceBooking booking) async {
    try {
      print('➕ Adding booking to Supabase: ${booking.id}');

      final response = await client
          .from('service_bookings')
          .insert(_mapBookingToSupabase(booking))
          .select()
          .single();

      final newBooking = mapSupabaseToBooking(response);
      await dao.cacheBooking(newBooking);

      print('✅ Booking added successfully');
      return newBooking;
    } catch (e) {
      print('❌ Error adding booking: $e');
      rethrow;
    }
  }

  // ✅ Update booking
  Future<ServiceBooking> updateBooking(ServiceBooking booking) async {
    try {
      print('📝 Updating booking in Supabase: ${booking.id}');

      final response = await client
          .from('service_bookings')
          .update(_mapBookingToSupabase(booking))
          .eq('id', booking.id)
          .select()
          .single();

      final updatedBooking = mapSupabaseToBooking(response);
      await dao.cacheBooking(updatedBooking);

      print('✅ Booking updated successfully');
      return updatedBooking;
    } catch (e) {
      print('❌ Error updating booking: $e');
      rethrow;
    }
  }

  // ✅ Update status dengan history
  Future<ServiceBooking> updateStatus({
    required String bookingId,
    required String newStatus,
    String? adminNotes,
  }) async {
    try {
      print('📝 Updating status for booking: $bookingId to $newStatus');

      // Ambil booking lama untuk mendapatkan status history
      final oldBookingResponse = await client
          .from('service_bookings')
          .select('status_history')
          .eq('id', bookingId)
          .single();

      final oldHistory = List<Map<String, dynamic>>.from(
          oldBookingResponse['status_history'] ?? []);

      // Tambahkan status baru ke history
      final newHistory = [
        ...oldHistory,
        {
          'status': newStatus,
          'updatedAt': DateTime.now().toIso8601String(),
          'notes': adminNotes,
        }
      ];

      final response = await client
          .from('service_bookings')
          .update({
        'status': newStatus,
        'status_history': newHistory,
        'admin_notes': adminNotes,
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', bookingId)
          .select()
          .single();

      final updatedBooking = mapSupabaseToBooking(response);
      await dao.cacheBooking(updatedBooking);

      print('✅ Status updated successfully');
      return updatedBooking;
    } catch (e) {
      print('❌ Error updating status: $e');
      rethrow;
    }
  }

  // ✅ Delete booking
  Future<void> deleteBooking(String bookingId) async {
    try {
      print('🗑️ Deleting booking: $bookingId');

      await client.from('service_bookings').delete().eq('id', bookingId);
      await dao.delete(bookingId);

      print('✅ Booking deleted successfully');
    } catch (e) {
      print('❌ Error deleting booking: $e');
      rethrow;
    }
  }

  // ✅ Map Dart model to Supabase JSON (camelCase → snake_case)
  Map<String, dynamic> _mapBookingToSupabase(ServiceBooking booking) {
    return {
      'id': booking.id,
      'user_id': booking.userId,
      'car_id': booking.carId,
      'service_type': booking.serviceType,
      'scheduled_at': booking.scheduledAt.toIso8601String(),
      'estimated_cost': booking.estimatedCost,
      'status': booking.status,
      'workshop': booking.workshop,
      'notes': booking.notes,
      'admin_notes': booking.adminNotes,
      'status_history': booking.statusHistory,
      'jobs': booking.jobs,
      'parts': booking.parts,
      'km': booking.km,
      'total_cost': booking.totalCost,
      'created_at': booking.createdAt.toIso8601String(),
      'updated_at': booking.updatedAt?.toIso8601String(),
      'service_details': booking.serviceDetails,
      'mechanic_name': booking.mechanicName,
      'is_pickup_service': booking.isPickupService,
      'service_location': booking.serviceLocation,
      'promo_id': booking.promoId,
    };
  }

  // ✅ Map Supabase JSON to Dart model (snake_case → camelCase)
  ServiceBooking mapSupabaseToBooking(Map<String, dynamic> json) {
    // Helper function to safely parse list fields
    List<T> _parseList<T>(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        if (T == String) {
          return value.map((e) => e.toString()).cast<T>().toList();
        } else if (T == Map<String, dynamic>) {
          return value.map((e) => e as Map<String, dynamic>).cast<T>().toList();
        }
        return List<T>.from(value);
      }
      if (value is String) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is List) {
            if (T == String) {
              return decoded.map((e) => e.toString()).cast<T>().toList();
            } else if (T == Map<String, dynamic>) {
              return decoded.map((e) => e as Map<String, dynamic>).cast<T>().toList();
            }
            return List<T>.from(decoded);
          }
        } catch (e) {
          print('⚠️ Error parsing list: $e');
          return [];
        }
      }
      return [];
    }

    // Helper to safely parse date
    DateTime _parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      try {
        return DateTime.parse(value.toString());
      } catch (e) {
        print('⚠️ Error parsing date: $e');
        return DateTime.now();
      }
    }

    // Helper to safely parse double
    double _parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    return ServiceBooking(
      id: json['id'] as String? ?? const Uuid().v4(),
      userId: json['user_id'] as String? ?? '',
      carId: json['car_id'] as String? ?? '',
      serviceType: json['service_type'] as String? ?? '',
      scheduledAt: _parseDate(json['scheduled_at']),
      estimatedCost: _parseDouble(json['estimated_cost']),
      status: json['status'] as String? ?? 'pending',
      workshop: json['workshop'] as String?,
      notes: json['notes'] as String?,
      adminNotes: json['admin_notes'] as String?,
      statusHistory: _parseList<Map<String, dynamic>>(json['status_history']),
      jobs: _parseList<String>(json['jobs']),
      parts: _parseList<String>(json['parts']),
      km: json['km'] as int?,
      totalCost: json['total_cost'] != null ? _parseDouble(json['total_cost']) : null,
      createdAt: _parseDate(json['created_at']),
      updatedAt: json['updated_at'] != null ? _parseDate(json['updated_at']) : null,
      serviceDetails: json['service_details'] as String?,
      mechanicName: json['mechanic_name'] as String?,
      isPickupService: json['is_pickup_service'] as bool? ?? false,
      serviceLocation: json['service_location'] as String?,
      promoId: json['promo_id'] as String?,
    );
  }
}