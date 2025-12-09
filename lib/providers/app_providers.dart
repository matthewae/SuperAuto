import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/car.dart';
import '../models/product.dart';
import '../models/cart.dart';
import '../models/order.dart';
import '../models/service_booking.dart';
import '../models/service_history.dart';
import '../models/bundling.dart';
import '../models/promo.dart';
import '../models/loyalty_points.dart';
import '../models/enums.dart';
import '../services/auth_service.dart';
import '../data/dao/product_dao.dart';
import '../data/dao/car_dao.dart';
import '../data/dao/user_dao.dart';
import '../data/dao/service_booking_dao.dart';
import '../data/db/app_database.dart';
import '../services/history_service.dart';


const _uuid = Uuid();


final userBookingsProviderAlt = FutureProvider.autoDispose<List<ServiceBooking>>((ref) async {
  final user = ref.watch(authProvider).valueOrNull;

  if (user == null) {
    return [];
  }

  final dao = ref.watch(serviceBookingDaoProvider);

  // Force reload when bookingsProvider changes
  ref.watch(bookingsProvider);

  return await dao.getByUserId(user.idString);
});




// Core Providers
final databaseProvider = Provider<Database>((ref) {
  throw UnimplementedError('Database provider not initialized');
});

// DAO Providers
final userDaoProvider = Provider<UserDao>((ref) {
  final db = ref.watch(databaseProvider);
  return UserDao(db);
});

final carDaoProvider = Provider<CarDao>((ref) {
  final db = ref.watch(databaseProvider);
  return CarDao(db);
});

final productDaoProvider = Provider<ProductDao>((ref) {
  final db = ref.watch(databaseProvider);
  return ProductDao(db);
});

final serviceBookingDaoProvider = Provider<ServiceBookingDao>((ref) {
  final db = ref.watch(databaseProvider);
  return ServiceBookingDao(db);
});

// Service Providers
final authServiceProvider = Provider<AuthService>((ref) {
  final userDao = ref.watch(userDaoProvider);
  return AuthService(userDao);
});

// Auth
final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService: authService, ref: ref);
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthService _authService;
  final Ref _ref;

  bool _isInitialized = false;

  AuthNotifier({required AuthService authService, required Ref ref})
      : _authService = authService,
        _ref = ref,
        super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      await _authService.init();
      final user = _authService.currentUser();
      print('AuthNotifier initialized. User: $user');
      state = AsyncValue.data(user);
    } catch (e, stack) {
      print('Error initializing AuthNotifier: $e\n$stack');
      state = AsyncValue.error(e, stack);
    } finally {
      _isInitialized = true;
    }
  }

  Future<User?> login(String email, String password) async {
    try {
      state = const AsyncValue.loading();
      print('Attempting login for email: $email');
      final user = await _authService.login(email, password);

      if (user != null) {
        print('User logged in - ID: ${user.id}, Email: ${user.email}');
        state = AsyncValue.data(user);
        return user;
      } else {
        print('Login failed - Invalid credentials for email: $email');
        state = const AsyncValue.data(null);
        return null;
      }
    } catch (e, stack) {
      print('Login error: $e\n$stack');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  // In app_providers.dart, update the AuthNotifier class
  // In app_providers.dart, update the AuthNotifier class
  Future<void> logout() async {
    try {
      print('Starting logout process...');
      await _authService.logout();

      // Clear the main car ID when logging out
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('mainCarId');

      state = const AsyncValue.data(null);
      print('Logout successful');
    } catch (e, stack) {
      print('Error during logout: $e\n$stack');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  User? get currentUser => state.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );

  bool get isInitialized => _isInitialized;
}

// Cars
final carsProvider = StateNotifierProvider<CarsNotifier, List<Car>>((ref) {
  final dao = ref.watch(carDaoProvider);
  return CarsNotifier(dao, ref);
});

class CarsNotifier extends StateNotifier<List<Car>> {
  final CarDao _dao;
  final Ref _ref;

  CarsNotifier(this._dao, this._ref) : super(const []) {
    _loadCars();
    _ref.listen<AsyncValue<User?>>(authProvider, (previous, next) {
      _loadCars();
    });
  }

  Future<void> _loadCars() async {
    final user = _ref.read(authProvider).value;
    print('Loading cars. Current user: ${user?.id} (${user?.email})');

    if (user?.id != null) {
      try {
        print('Getting cars for user ID: ${user!.id}');
        final cars = await _dao.getByUserId(user!.idString);
        print('Successfully loaded ${cars.length} cars for user ${user!.id}');
        state = cars;
      } catch (e) {
        print('Error loading cars: $e');
        state = [];
      }
    } else {
      print('No user logged in, clearing car list');
      state = [];
    }
  }

  Future<void> add(Car car) async {
    await _dao.insert(car);
    await _loadCars();
  }

  Future<void> updateCar(Car car) async {
    await _dao.update(car);
    await _loadCars();
  }

  Future<void> remove(String id) async {
    await _dao.delete(id);
    await _loadCars();
  }
}

// Products
final productsProvider = StateNotifierProvider<ProductNotifier, List<Product>>((ref) {
  return ProductNotifier(ref.watch(productDaoProvider));
});

class ProductNotifier extends StateNotifier<List<Product>> {
  final ProductDao _dao;

  ProductNotifier(this._dao) : super([
    Product(
      id: _uuid.v4(),
      name: 'Ban Michelin Primacy 4',
      category: ProductCategory.tiresWheels,
      description: 'Ban touring premium dengan performa pengereman basah dan kering yang sangat baik.',
      price: 1200000,
      compatibleModels: ['Sedan', 'MPV'],
      imageUrl: 'https://via.placeholder.com/150/0000FF/FFFFFF?text=Ban+Michelin',
    ),
    Product(
      id: _uuid.v4(),
      name: 'Oli Mesin Castrol EDGE',
      category: ProductCategory.fluids,
      description: 'Oli mesin full sintetis untuk performa maksimal dan perlindungan mesin.',
      price: 150000,
      compatibleModels: ['Semua Model'],
      imageUrl: 'https://via.placeholder.com/150/FF0000/FFFFFF?text=Oli+Castrol',
    ),
    Product(
      id: _uuid.v4(),
      name: 'Filter Udara K&N',
      category: ProductCategory.accessories,
      description: 'Filter udara performa tinggi yang dapat dicuci dan digunakan kembali.',
      price: 750000,
      compatibleModels: ['Sport', 'SUV'],
      imageUrl: 'https://via.placeholder.com/150/00FF00/FFFFFF?text=Filter+K%26N',
    ),
    Product(
      id: _uuid.v4(),
      name: 'Klakson Hella Black Twin Tone',
      category: ProductCategory.accessories,
      description: 'Klakson mobil Hella Black Twin Tone, suara nyaring dan elegan.',
      price: 250000,
      compatibleModels: ['Semua Model'],
      imageUrl: 'https://via.placeholder.com/150/000000/FFFFFF?text=Klakson+Hella',
    ),
    Product(
      id: _uuid.v4(),
      name: 'Lampu LED Philips Ultinon Essential',
      category: ProductCategory.electronics,
      description: 'Lampu depan LED Philips Ultinon Essential, terang dan tahan lama.',
      price: 600000,
      compatibleModels: ['Semua Model'],
      imageUrl: 'https://via.placeholder.com/150/FFFF00/000000?text=Lampu+LED+Philips',
    ),
    Product(
      id: _uuid.v4(),
      name: 'Kamera Mundur Universal',
      category: ProductCategory.electronics,
      description: 'Kamera mundur universal dengan tampilan jernih untuk keamanan parkir.',
      price: 350000,
      compatibleModels: ['Semua Model'],
      imageUrl: 'https://via.placeholder.com/150/808080/FFFFFF?text=Kamera+Mundur',
    ),
  ]) {
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final items = await _dao.getAll();
      state = items;
    } catch (e) {
      print('Error loading products: $e');
      state = [];
    }
  }

  Future<void> save(
      String name,
      double price,
      String desc,
      ProductCategory category,
      List<String> compatibleModels,
      Product? existing,
      ) async {
    try {
      if (existing == null) {
        final newProduct = Product(
          id: _uuid.v4(),
          name: name,
          category: category,
          description: desc,
          price: price,
          compatibleModels: compatibleModels,
        );
        await _dao.insert(newProduct);
      } else {
        final updated = existing.copyWith(
          name: name,
          category: category,
          description: desc,
          price: price,
          compatibleModels: compatibleModels,
        );
        await _dao.update(updated);
      }
      // Reload products after any modification
      await _loadProducts();
    } catch (e) {
      print('Error saving product: $e');
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dao.delete(id);
      // Reload products after deletion
      await _loadProducts();
    } catch (e) {
      print('Error deleting product: $e');
      rethrow;
    }
  }
}
// Cart
final cartProvider = StateNotifierProvider<CartNotifier, Cart>((ref) {
  return CartNotifier();
});

class CartNotifier extends StateNotifier<Cart> {
  CartNotifier() : super(const Cart());

  void addItem({
    required String productId,
    required String productName,
    required double price,
    int quantity = 1,
    String? imageUrl,
  }) {
    final existingIndex = state.items.indexWhere((item) => item.productId == productId);

    if (existingIndex >= 0) {
      final existingItem = state.items[existingIndex];
      final updatedItems = List<CartItem>.from(state.items);
      updatedItems[existingIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + quantity,
      );
      state = state.copyWith(items: updatedItems);
    } else {
      final newItem = CartItem(
        productId: productId,
        productName: productName,
        price: price,
        quantity: quantity,
        imageUrl: imageUrl,
      );
      state = state.copyWith(items: [...state.items, newItem]);
    }
  }

  void updateQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(productId);
      return;
    }

    final index = state.items.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      final updatedItems = List<CartItem>.from(state.items);
      updatedItems[index] = updatedItems[index].copyWith(quantity: newQuantity);
      state = state.copyWith(items: updatedItems);
    }
  }

  void removeItem(String productId) {
    state = state.copyWith(
      items: state.items.where((item) => item.productId != productId).toList(),
    );
  }

  void clear() {
    state = const Cart();
  }

  void applyPromo(String? promoId) {
    state = state.copyWith(appliedPromoId: promoId);
  }
}

// Orders
final ordersProvider = StateNotifierProvider<OrdersNotifier, List<Order>>((ref) {
  return OrdersNotifier();
});

class OrdersNotifier extends StateNotifier<List<Order>> {
  OrdersNotifier() : super(const []);
  void add(Order order) => state = [...state, order];
}

// Bookings
final bookingsProvider = StateNotifierProvider<BookingsNotifier, List<ServiceBooking>>((ref) {
  return BookingsNotifier(ServiceBookingDao(ref.watch(databaseProvider)));
});

class BookingsNotifier extends StateNotifier<List<ServiceBooking>> {

  final ServiceBookingDao _dao;
  bool _isInitialized = false;

  BookingsNotifier(this._dao) : super([]) {
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    try {
      final bookings = await _dao.getAll();
      state = bookings;
      _isInitialized = true;
    } catch (e) {
      print('Error loading bookings: $e');
      state = [];
      _isInitialized = false;
    }
  }
  Future<void> refresh() async {
    await _loadBookings();
  }
  Future<void> add(ServiceBooking booking) async {
    try {
      await _dao.insert(booking);
      await _loadBookings();
    } catch (e) {
      print('Error adding booking: $e');
      rethrow;
    }
  }



  // Add this method to your BookingsNotifier if it doesn't exist
  Future<void> updateServiceDetails({
    required String id,
    required List<String> jobs,
    required List<String> parts,
    required int km,
    required double totalCost,
    required String notes,
  }) async {
    try {
      final booking = state.firstWhere((b) => b.id == id);
      final updatedBooking = booking.copyWith(
        jobs: jobs,
        parts: parts,
        km: km,
        totalCost: totalCost,
        adminNotes: notes,
      );
      await _dao.update(updatedBooking);
      state = [updatedBooking, ...state.where((b) => b.id != id)];
    } catch (e) {
      print('Error updating service details: $e');
      rethrow;
    }
  }
  Future<void> updateStatus(String id, String status, {String? notes}) async {
    try {
      final booking = state.firstWhere((b) => b.id == id);

      // Don't allow updating completed or cancelled bookings
      if (booking.status == 'completed' || booking.status == 'cancelled') {
        throw Exception('Tidak dapat mengubah status booking yang sudah selesai/dibatalkan');
      }

      final now = DateTime.now();

      // ✅ Build new status history
      final Map<String, dynamic> newStatusHistory = Map<String, dynamic>.from(
        booking.statusHistory ?? {},
      );

      // Add new status to history dengan format yang konsisten
      newStatusHistory[status] = now.toIso8601String();

      print('📝 Updating status from ${booking.status} to $status');
      print('📜 New status history: $newStatusHistory');

      final updatedBooking = booking.copyWith(
        status: status,
        adminNotes: notes ?? booking.adminNotes,
        updatedAt: now,
        statusHistory: newStatusHistory,
      );

      await _dao.update(updatedBooking);

      // Update state
      state = state.map((b) => b.id == id ? updatedBooking : b).toList();

      print('✅ Status updated successfully');
    } catch (e) {
      print('❌ Error updating status: $e');
      rethrow;
    }
  }

  Future<void> updateStatusAndDetails({
    required String id,
    required String status,
    List<String>? jobs,
    List<String>? parts,
    int? km,
    double? totalCost,
    String? adminNotes,
  }) async {
    try {
      final booking = state.firstWhere((b) => b.id == id);
      final updatedBooking = booking.copyWith(
        status: status,
        jobs: jobs,
        parts: parts,
        km: km,
        totalCost: totalCost,
        adminNotes: adminNotes,
        updatedAt: DateTime.now(),
      );

      await _dao.updateStatusAndDetails(updatedBooking);
      state = [updatedBooking, ...state.where((b) => b.id != id)];
    } catch (e) {
      print('Error updating booking details: $e');
      rethrow;
    }
  }
  Future<void> delete(String id) async {
    try {
      await _dao.delete(id);
      await _loadBookings();
    } catch (e) {
      print('Error deleting booking: $e');
      rethrow;
    }
  }

  Future<List<ServiceBooking>> getByUserId(String userId) async {
    try {
      return await _dao.getByUserId(userId);
    } catch (e) {
      print('Error getting bookings by user ID: $e');
      return [];
    }
  }
  final activeBookingsProvider = FutureProvider.autoDispose
      .family<List<ServiceBooking>, String>((ref, userId) async {
    final bookings = await ref.read(bookingsProvider.notifier).getByUserId(userId);
    return bookings
        .where((b) => b.status != 'completed' && b.status != 'cancelled')
        .toList();
  });
  Future<void> update(ServiceBooking booking) async {
    try {
      await _dao.update(booking);
      state = state.map((b) => b.id == booking.id ? booking : b).toList();
    } catch (e) {
      print('Error updating booking: $e');
      rethrow;
    }
  }
}

// Service History
// final historyProvider = StateNotifierProvider<HistoryNotifier, List<ServiceHistoryItem>>((ref) {
//   return HistoryNotifier();
// });
//
// class HistoryNotifier extends StateNotifier<List<ServiceHistoryItem>> {
//   HistoryNotifier() : super(const []);
//   void add(ServiceHistoryItem h) => state = [...state, h];
// }

// Bundlings
final bundlingsProvider = StateNotifierProvider<BundlingsNotifier, List<Bundling>>((ref) {
  return BundlingsNotifier();
});

class BundlingsNotifier extends StateNotifier<List<Bundling>> {
  BundlingsNotifier() : super(const []);
  void set(List<Bundling> list) => state = list;
}

// Promos
final promosProvider = StateNotifierProvider<PromosNotifier, List<Promo>>((ref) {
  return PromosNotifier();
});

class PromosNotifier extends StateNotifier<List<Promo>> {
  PromosNotifier() : super(const []);
  void set(List<Promo> list) => state = list;
}

// Loyalty
final loyaltyPointsProvider = StateProvider<int>((ref) => 0);

// History Completed Service
// final serviceHistoryDaoProvider = Provider<ServiceHistoryDao>((ref) {
//   final db = ref.watch(databaseProvider);
//   return ServiceHistoryDao(db);
// });
//
// final historyServiceProvider = Provider<HistoryService>((ref) {
//   final dao = ref.watch(serviceHistoryDaoProvider);
//   return HistoryService(dao);
// });
//
// // Add this provider for the history page
// final userHistoryProvider = FutureProvider.autoDispose.family<List<ServiceHistoryItem>, String>((ref, userId) async {
//   final historyService = ref.watch(historyServiceProvider);
//   return await historyService.getUserHistory(userId);
// });

// final mainCarIdProvider = StateNotifierProvider<MainCarNotifier, String>((ref) {
//   final notifier = MainCarNotifier(ref: ref);
//
//   // Dengarkan perubahan auth
//   ref.listen<AsyncValue<User?>>(authProvider, (_, next) {
//     final user = next.value;
//     if (user != null) {
//       notifier._updateCurrentUser(user);
//     }
//   });
//
//   return notifier;
// });

// class MainCarNotifier extends StateNotifier<String> {
//   MainCarNotifier({required this.ref}) : super('') {
//     _init();
//   }
//
//   final Ref ref;
//   String? _currentUserId;
//   SharedPreferences? _prefs;
//   bool _isInitialized = false;
//
//   Future<void> _init() async {
//     if (_isInitialized) return;
//     try {
//       _prefs = await SharedPreferences.getInstance();
//       final currentUser = ref.read(authProvider).value;
//       if (currentUser != null) {
//         _currentUserId = currentUser.idString;
//         await _loadMainCarId();
//       }
//       _isInitialized = true;
//     } catch (e) {
//       print('Error initializing MainCarNotifier: $e');
//       _isInitialized = true;
//     }
//   }
//
//   Future<void> _updateCurrentUser(User? user) async {
//     final newUserId = user?.idString;
//     if (newUserId != _currentUserId) {
//       _currentUserId = newUserId;
//       if (_currentUserId != null) {
//         await _loadMainCarId();
//       } else {
//         state = ''; // Pengguna logout, hapus state
//       }
//     }
//   }
//
//   Future<void> _loadMainCarId() async {
//     if (_currentUserId == null || _prefs == null) {
//       state = '';
//       return;
//     }
//
//     try {
//       // Key tetap 'main_car_[userId]'
//       final mainCarId = _prefs!.getString('main_car_$_currentUserId');
//       if (mainCarId != null && mainCarId.isNotEmpty) {
//         state = mainCarId;
//       } else {
//         state = '';
//       }
//     } catch (e) {
//       print('Error loading main car ID: $e');
//       state = '';
//     }
//   }
//
//   // INI ADALAH FUNGSI YANG SUDAH DIPERBAIKI
//   Future<void> setMainCarId(String userId, String carId) async {
//     if (_prefs == null) return;
//
//     try {
//       // HANYA HAPUS MOBIL UTAMA LAMA UNTUK PENGGUNA YANG SAMA (userId)
//       // Ini mencegah bug di mana mobil utama user lain terhapus.
//       final oldMainCarId = _prefs!.getString('main_car_$userId');
//       if (oldMainCarId != null) {
//         print('Menghapus mobil utama lama untuk user $userId: $oldMainCarId');
//         await _prefs!.remove('main_car_$userId');
//       }
//
//       // Tetapkan mobil utama baru untuk pengguna ini
//       await _prefs!.setString('main_car_$userId', carId);
//       print('Menetapkan mobil utama baru untuk user $userId: $carId');
//
//       // Perbarui state jika ini untuk pengguna saat ini
//       if (userId == _currentUserId) {
//         print('Memperbarui state untuk pengguna saat ini ($userId) dengan mobil utama: $carId');
//         state = carId;
//       }
//     } catch (e) {
//       print('Error setting main car: $e');
//       rethrow;
//     }
//   }
// }
//

