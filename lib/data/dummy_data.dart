import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../models/enums.dart';
import '../models/user.dart';
import '../models/car.dart';
import '../providers/app_providers.dart';
import '../utils/image_placeholder.dart';
import '../models/promo.dart';


const _uuid = Uuid();
final _random = Random();

/// Fungsi utama untuk menjalankan seeding data dummy.
/// Fungsi ini hanya akan dijalankan sekali, ditandai dengan flag di SharedPreferences.
Future<void> seedDummyData(FutureProviderRef ref) async {
  try {
    if (kDebugMode) {
      debugPrint('🚀 Memulai proses seeding data dummy...');
    }

    final prefs = await SharedPreferences.getInstance();
    final isSeeded = prefs.getBool('dummy_seeded') ?? false;

    if (isSeeded) {
      if (kDebugMode) {
        debugPrint('ℹ Data dummy sudah di-seed sebelumnya. Melewati...');
      }
      return;
    }

    if (kDebugMode) {
      debugPrint('🌱 Menyiapkan data awal...');
    }

    // Jalankan seeding
    await _seedUsers(ref);
    await _seedProducts(ref);
    await _seedCars(ref);
    await _seedPromos(ref);

    // Tandai bahwa seeding sudah pernah dilakukan
    await prefs.setBool('dummy_seeded', true);

    if (kDebugMode) {
      debugPrint('✅ Proses seeding data dummy selesai dengan sukses!');
    }
  } catch (e, stackTrace) {
    debugPrint('❌ Gagal melakukan seeding data: $e');
    debugPrint('Stack trace: $stackTrace');
    rethrow;
  }
}

Future<void> _seedProducts(FutureProviderRef ref) async {
  final dao = ref.read(productDaoProvider);
  final existing = await dao.getAll();

  if (existing.isNotEmpty) {
    if (kDebugMode) {
      debugPrint('ℹ Produk sudah ada di database. Melewati proses seeding produk.');
    }
    return;
  }

  if (kDebugMode) {
    debugPrint('📦 Menyiapkan data produk...');
  }

  final products = [
    Product(
      id: _uuid.v4(),
      name: 'Oli Mesin Synthetic 5W-30',
      category: ProductCategory.oil,
      description: 'Oli mesin sintetik full synthetic dengan teknologi terbaru untuk performa optimal dan perlindungan mesin maksimal.',
      price: 185000,
      compatibleModels: ['Civic', 'Avanza', 'Yaris', 'Xpander', 'Jazz'],
      imageUrl: ImagePlaceholder.generate(),
    ),
    Product(
      id: _uuid.v4(),
      name: 'Filter Oli Original',
      category: ProductCategory.engineParts,
      description: 'Filter oli asli dengan kualitas terjamin. Mampu menyaring kotoran hingga 15 mikron.',
      price: 75000,
      compatibleModels: ['Civic', 'Avanza', 'Xenia', 'Ertiga'],
      imageUrl: ImagePlaceholder.generate(),
    ),
    Product(
      id: _uuid.v4(),
      name: 'Kampas Rem Depan',
      category: ProductCategory.brakes,
      description: 'Kampas rem depan dengan material ceramic untuk pengereman lebih halus dan awet.',
      price: 350000,
      compatibleModels: ['Civic', 'HRV', 'CRV', 'Fortuner'],
      imageUrl: ImagePlaceholder.generate(),
    ),
    Product(
      id: _uuid.v4(),
      name: 'Aki GS Maintenance Free',
      category: ProductCategory.electronics,
      description: 'Aki kering maintenance free dengan garansi 1 tahun. Kapasitas 40Ah, 12V.',
      price: 1250000,
      compatibleModels: ['Semua Model'],
      imageUrl: ImagePlaceholder.generate(),
    ),
    Product(
      id: _uuid.v4(),
      name: 'Ban Michelin Pilot Sport 4',
      category: ProductCategory.tiresWheels,
      description: 'Ban premium dengan daya cengkeram maksimal di berbagai kondisi jalan.',
      price: 1850000,
      compatibleModels: ['Civic', 'HRV', 'CRV', 'CX-5'],
      imageUrl: ImagePlaceholder.generate(),
    ),
  ];

  try {
    for (final product in products) {
      await dao.insert(product);
    }

    if (kDebugMode) {
      debugPrint('✅ Berhasil menambahkan ${products.length} produk');
    }
  } catch (e) {
    debugPrint('❌ Gagal menambahkan produk: $e');
    rethrow;
  }
}

Future<void> _seedUsers(FutureProviderRef ref) async {
  final dao = ref.read(userDaoProvider);
  // PERBAIKAN: Gunakan DAO untuk konsistensi
  final existing = await dao.getAllUsers();

  if (existing.isNotEmpty) {
    if (kDebugMode) {
      debugPrint('ℹ Pengguna sudah ada di database. Melewati proses seeding pengguna.');
    }
    return;
  }

  if (kDebugMode) {
    debugPrint('👤 Menyiapkan data pengguna...');
  }

  // Catatan: Di production, gunakan hashing password yang tepat
  final users = [
    User(
      id: _uuid.v4(),
      name: 'Budi Santoso',
      email: 'budi@example.com',
      password: 'password1',
      role: 'user',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    User(
      id: _uuid.v4(),
      name: 'Adjie',
      email: 'adjie@example.com',
      password: 'password2',
      role: 'user',
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
    ),
    User(
      id: _uuid.v4(),
      name: 'Siti Rahayu',
      email: 'siti@example.com',
      password: 'password3',
      role: 'user',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
  ];

  try {
    for (final user in users) {
      await dao.insertUser(user);
    }

    if (kDebugMode) {
      debugPrint('✅ Berhasil menambahkan ${users.length} pengguna');
    }
  } catch (e) {
    debugPrint('❌ Gagal menambahkan pengguna: $e');
    rethrow;
  }
}

Future<void> _seedCars(FutureProviderRef ref) async {
  final userDao = ref.read(userDaoProvider);
  final carDao = ref.read(carDaoProvider);

  // PERBAIKAN: Gunakan DAO untuk konsistensi
  final users = await userDao.getAllUsers();
  final existingCars = await carDao.getAll();

  if (existingCars.isNotEmpty) {
    if (kDebugMode) {
      debugPrint('ℹ Data mobil sudah ada di database. Melewati proses seeding mobil.');
    }
    return;
  }

  if (users.isEmpty) {
    if (kDebugMode) {
      debugPrint('⚠ Tidak ada pengguna yang ditemukan. Harap seed pengguna terlebih dahulu.');
    }
    return;
  }

  if (kDebugMode) {
    debugPrint('🚗 Menyiapkan data mobil untuk ${users.length} pengguna...');
  }

  final carBrands = ['Toyota', 'Honda', 'Suzuki', 'Mitsubishi', 'Daihatsu'];
  final toyotaModels = ['Avanza', 'Innova', 'Rush', 'Fortuner', 'Alphard'];
  final hondaModels = ['Brio', 'Jazz', 'HRV', 'CRV', 'Civic'];
  final suzukiModels = ['Ertiga', 'XL7', 'Ignis', 'Baleno', 'S-Presso'];
  final colors = ['Hitam', 'Putih', 'Silver', 'Abu-abu', 'Merah', 'Biru'];

  final carModels = {
    'Toyota': toyotaModels,
    'Honda': hondaModels,
    'Suzuki': suzukiModels,
    'Mitsubishi': ['Xpander', 'Pajero', 'Triton', 'Xpander Cross'],
    'Daihatsu': ['Xenia', 'Terios', 'Ayla', 'Sigra'],
  };

  int carCount = 0;

  try {
    for (final user in users) {
      // Setiap pengguna mendapatkan 4 mobil
      for (var i = 0; i < 4; i++) {
        // Gunakan kombinasi user ID dan indeks mobil untuk variasi merek dan model
        final brand = carBrands[(user.id.hashCode + i) % carBrands.length];
        final models = carModels[brand] ?? ['${brand} Model'];
        final model = models[(user.id.hashCode + i) % models.length];
        final color = colors[(user.id.hashCode + i) % colors.length];
        final year = 2015 + (user.id.hashCode + i) % 9; // 2015-2023

        // Generate VIN (Vehicle Identification Number) dummy
        final vin = '${brand.substring(0, 3).toUpperCase()}${_random.nextInt(9000) + 1000}${_random.nextInt(9000) + 1000}${_random.nextInt(9000) + 1000}';

        // Generate nomor mesin dummy
        final engineNumber = 'ENG${brand.substring(0, 3).toUpperCase()}${_random.nextInt(900000) + 100000}';

        // Generate nomor polisi
        final plateNumber = _generatePlateNumber(user.id, i);

        final car = Car(
          id: _uuid.v4(),
          userId: user.id,
          brand: brand,
          model: model,
          year: year,
          plateNumber: plateNumber,
          vin: vin,
          engineNumber: engineNumber,
          initialKm: 1000 + (_random.nextInt(50) * 1000), // 1,000 - 50,000 km
          isMain: i == 0, // Mobil pertama adalah mobil utama
          imageUrl: 'assets/images/car_${brand.toLowerCase()}.png',
        );

        await carDao.insert(car);
        carCount++;
      }
    }

    if (kDebugMode) {
      debugPrint('✅ Berhasil menambahkan $carCount mobil untuk ${users.length} pengguna');
    }
  } catch (e) {
    debugPrint('❌ Gagal menambahkan mobil: $e');
    rethrow;
  }
}

Future<void> _seedPromos(FutureProviderRef ref) async {
  final dao = ref.read(promoDaoProvider);
  final existing = await dao.getAll();

  if (existing.isNotEmpty) {
    if (kDebugMode) {
      debugPrint('ℹ Promo sudah ada di database. Melewati proses seeding promo.');
    }
    return;
  }

  if (kDebugMode) {
    debugPrint('🎁 Menyiapkan data promo...');
  }

  final now = DateTime.now();
  final promos = [
    Promo.create(
      name: 'DISKON20',
      type: 'product_discount',
      value: 0.2, // 20% discount
      start: now.subtract(const Duration(days: 5)),
      end: now.add(const Duration(days: 30)),
    ),
    Promo.create(
      name: 'SERVIS50',
      type: 'service_discount',
      value: 50000.0, // Rp 50.000 discount
      start: now,
      end: now.add(const Duration(days: 60)),
    ),
  ];

  try {
    for (final promo in promos) {
      await dao.insert(promo);
    }

    if (kDebugMode) {
      debugPrint('✅ Berhasil menambahkan ${promos.length} promo');
    }
  } catch (e) {
    debugPrint('❌ Gagal menambahkan promo: $e');
    rethrow;
  }
}

String _generatePlateNumber(String userId, int index) {
  final areaCode = ['B', 'D', 'F', 'Z', 'N'];
  final letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  final area = areaCode[userId.codeUnits.fold(0, (a, b) => a + b) % areaCode.length];
  final number = (1000 + (userId.hashCode + index) % 9000).toString();
  final letter1 = letters[(userId.codeUnits[0] + index) % letters.length];
  final letter2 = letters[(userId.codeUnits[1] + index) % letters.length];
  final letter3 = letters[(userId.codeUnits[2] + index) % letters.length];

  return '$area $number $letter1$letter2$letter3';
}

