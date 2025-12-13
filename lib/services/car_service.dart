
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/dao/car_dao.dart';
import '../models/car.dart';

class CarService {
  final SupabaseClient client;
  final CarDao carDao;

  CarService({required this.client, required this.carDao});

  // Mengambil semua mobil pengguna dari Supabase dan menyinkronkannya ke SQLite
  Future<List<Car>> fetchAndCacheCars(String userId) async {
    try {
      final response = await client
          .from('cars')
          .select()
          .eq('user_id', userId)
          .order('createdAt', ascending: false);

      final List<Car> cars = (response as List)
          .map((carJson) => _mapSupabaseToCar(carJson))
          .toList();

      // Simpan semua mobil yang diambil ke cache lokal
      for (final car in cars) {
        await carDao.cacheCar(car);
      }

      return cars;
    } catch (e) {
      print('Error fetching cars from Supabase: $e');
      rethrow; // Lempar error agar Notifier bisa menanganinya (misal fallback ke cache)
    }
  }

  // ... (metode lain seperti addCar, updateCar, deleteCar, setMainCar tidak berubah)
  // Menambahkan mobil baru ke Supabase dan cache
  Future<Car> addCar(Car car) async {
    try {
      final response = await client.from('cars').insert(_mapCarToSupabase(car)).select();

      final newCar = _mapSupabaseToCar(response.first);

      // Simpan ke cache lokal setelah berhasil di Supabase
      await carDao.cacheCar(newCar);

      return newCar;
    } catch (e) {
      print('Error adding car to Supabase: $e');
      rethrow;
    }
  }

  // Mengupdate mobil di Supabase dan cache
  Future<Car> updateCar(Car car) async {
    try {
      final response = await client
          .from('cars')
          .update(_mapCarToSupabase(car))
          .eq('id', car.id)
          .select();

      final updatedCar = _mapSupabaseToCar(response.first);

      // Update cache lokal
      await carDao.cacheCar(updatedCar);

      return updatedCar;
    } catch (e) {
      print('Error updating car in Supabase: $e');
      rethrow;
    }
  }

  // Menghapus mobil dari Supabase dan cache
  Future<void> deleteCar(String carId) async {
    try {
      await client.from('cars').delete().eq('id', carId);

      // Hapus juga dari cache lokal
      await carDao.delete(carId);
    } catch (e) {
      print('Error deleting car from Supabase: $e');
      rethrow;
    }
  }

  // Menjadikan mobil sebagai mobil utama (menggunakan RPC)
  Future<void> setMainCar(String userId, String carId) async {
    try {
      // Panggil fungsi RPC yang sudah kita buat di Supabase
      await client.rpc('set_main_car', params: {
        'p_user_id': userId,
        'p_car_id': carId,
      });

      // Setelah berhasil di Supabase, update cache lokal
      await carDao.updateMainCarStatusInCache(userId, carId);
    } catch (e) {
      print('Error setting main car: $e');
      rethrow;
    }
  }

  // Helper: Mapping dari model Car (camelCase) ke Map untuk Supabase (snake_case)
  Map<String, dynamic> _mapCarToSupabase(Car car) {
    return {
      'id': car.id,
      'user_id': car.userId,
      'brand': car.brand,
      'model': car.model,
      'year': car.year,
      'plate_number': car.plateNumber,
      'vin': car.vin,
      'engine_number': car.engineNumber,
      'initial_km': car.initialKm,
      'is_main': car.isMain,
      'image_url': car.imageUrl,
    };
  }

  // PERBAIKAN UTAMA: Fungsi pemetaan yang sangat tangguh
  Car _mapSupabaseToCar(Map<String, dynamic> json) {
    // DEBUG: Cetak JSON untuk melihat data apa yang menyebabkan error
    print('Mapping Supabase JSON to Car: $json');

    // Gunakan helper untuk parsing tanggal agar lebih aman
    final createdAt = _parseDateTime(json['createdAt']);
    final updatedAt = _parseDateTime(json['updatedAt']);

    return Car(
      id: json['id']?.toString() ?? '',
      // PERBAIKAN: Gunakan kunci 'user_id' dari Supabase
      userId: json['user_id']?.toString() ?? '',
      brand: json['brand']?.toString() ?? 'Unknown',
      model: json['model']?.toString() ?? 'Unknown',
      year: (json['year'] is int) ? json['year'] as int : int.tryParse(json['year']?.toString() ?? '0') ?? 0,
      // PERBAIKAN: Gunakan kunci 'plate_number', 'engine_number', dll.
      plateNumber: json['plate_number']?.toString() ?? '',
      vin: json['vin']?.toString() ?? '',
      engineNumber: json['engine_number']?.toString() ?? '',
      initialKm: (json['initial_km'] is int) ? json['initial_km'] as int : int.tryParse(json['initial_km']?.toString() ?? '0') ?? 0,
      isMain: json['is_main'] is bool ? json['is_main'] as bool : (json['is_main'] == 1 || json['is_main'] == '1'),
      imageUrl: json['image_url'] as String?,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // Helper method untuk parsing tanggal dengan aman
  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('Error parsing date from string "$value": $e');
        return null;
      }
    }
    if (value is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } catch (e) {
        print('Error parsing date from int "$value": $e');
        return null;
      }
    }
    print('Unsupported date format: $value (${value.runtimeType})');
    return null;
  }
}