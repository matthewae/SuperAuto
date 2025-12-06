import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
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
import 'package:shared_preferences/shared_preferences.dart';

const _uuid = Uuid();

// Auth

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthService _authService = AuthService();
  bool _isInitialized = false;

  AuthNotifier() : super(const AsyncValue.loading()) {
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

      // Make sure to await the login operation
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

  // In AuthNotifier class
  Future<void> logout() async {
    try {
      print('Starting logout process...');
      // Clear any user data
      await _authService.logout();
      // Reset state
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
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Provider untuk menyimpan user aktif
final userStateProvider = StateProvider<User?>((ref) => null);
final productDaoProvider = Provider<ProductDao>((ref) => ProductDao());
final carDaoProvider = Provider<CarDao>((ref) => CarDao());


// Cars
class CarsNotifier extends StateNotifier<List<Car>> {
  final CarDao _dao;
  final Ref _ref;

  CarsNotifier(this._dao, this._ref) : super(const []) {
    _checkSchemaAndLoadCars();

    _loadCars();
    _ref.listen<AsyncValue<User?>>(authProvider, (previous, next) {
      _loadCars();
    });
  }

  Future<void> _checkSchemaAndLoadCars() async {
    await _dao.checkTableSchema();
    await _loadCars();
  }
  Future<void> _loadCars() async {
    final user = _ref.read(authProvider).value;
    print('Loading cars. Current user: ${user?.id} (${user?.email})');  // This line is already there

    if (user?.id != null) {
      try {
        print('Getting cars for user ID: ${user!.id}');  // Add this line
        final cars = await _dao.getByUserId(user.id!);
        print('Successfully loaded ${cars.length} cars for user ${user.id}');
        state = cars;
      } catch (e, stack) {
        print('Error loading cars: $e\n$stack');
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

final someOtherProvider = Provider<List<Car>>((ref) {
  // This should be using getByUserId, not getting all cars
  final user = ref.watch(authProvider).value;
  if (user == null) return [];
  return ref.watch(carsProvider);
});

final carsProvider = StateNotifierProvider<CarsNotifier, List<Car>>((ref) {
  return CarsNotifier(
    ref.read(carDaoProvider),
    ref,
  );
});


final mainCarIdProvider = StateNotifierProvider<MainCarNotifier, String>((ref) {
  return MainCarNotifier();
});

class MainCarNotifier extends StateNotifier<String> {
  MainCarNotifier() : super('') {
    _loadMainCarId();
  }

  Future<void> _loadMainCarId() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('mainCarId') ?? '';
  }

  Future<void> setMainCarId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mainCarId', id);
    state = id;
  }
}
// Products
class ProductNotifier extends StateNotifier<List<Product>> {
  final ProductDao dao;

  ProductNotifier(this.dao) : super([]) {
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final items = await dao.getAll();
    state = items;
  }

  Future<void> save(
      String name,
      double price,
      String desc,
      ProductCategory category,
      List<String> compatibleModels,
      Product? existing,
      ) async {
    if (existing == null) {
      // ADD
      final newProduct = Product(
        id: _uuid.v4(),
        name: name,
        category: category,
        description: desc,
        price: price,
        compatibleModels: compatibleModels,
      );

      await dao.insert(newProduct);
      state = [...state, newProduct];
    } else {
      // EDIT
      final updated = Product(
        id: existing.id,
        name: name,
        category: category,
        description: desc,
        price: price,
        compatibleModels: compatibleModels,
        imageUrl: existing.imageUrl,
      );

      await dao.update(updated);

      state = [
        for (final p in state)
          if (p.id == existing.id) updated else p
      ];
    }
  }

  Future<void> delete(String id) async {
    await dao.delete(id);
    state = state.where((p) => p.id != id).toList();
  }
}
final productsProvider = StateNotifierProvider<ProductNotifier, List<Product>>(
      (ref) => ProductNotifier(ref.read(productDaoProvider)),
);

// Cart
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
      // Update existing item
      final existingItem = state.items[existingIndex];
      final updatedItems = List<CartItem>.from(state.items);
      updatedItems[existingIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + quantity,
      );
      state = state.copyWith(items: updatedItems);
    } else {
      // Add new item
      final newItem = CartItem(
        productId: productId,
        productName: productName,
        price: price,
        quantity: quantity,
        imageUrl: imageUrl,
      );
      state = state.copyWith(
          items: [...state.items, newItem]
      );
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

// Provider
final cartProvider = StateNotifierProvider<CartNotifier, Cart>((ref) {
  return CartNotifier();
});
// Orders (simple list)
class OrdersNotifier extends StateNotifier<List<Order>> {
  OrdersNotifier() : super(const []);
  void add(Order order) => state = [...state, order];
}
final ordersProvider = StateNotifierProvider<OrdersNotifier, List<Order>>((ref) => OrdersNotifier());

// Bookings
// In app_providers.dart
class BookingsNotifier extends StateNotifier<List<ServiceBooking>> {
  BookingsNotifier() : super(const []);


  void add(ServiceBooking booking) => state = [...state, booking];

  void updateStatus(String id, String status) {
    state = [
      for (final booking in state)
        if (booking.id == id)
          booking.copyWith(
            status: status,
            updatedAt: DateTime.now(),
          )
        else
          booking,
    ];
  }
}
final bookingsProvider = StateNotifierProvider<BookingsNotifier, List<ServiceBooking>>((ref) => BookingsNotifier());

// Service History
class HistoryNotifier extends StateNotifier<List<ServiceHistoryItem>> {
  HistoryNotifier() : super(const []);
  void add(ServiceHistoryItem h) => state = [...state, h];
}
final historyProvider = StateNotifierProvider<HistoryNotifier, List<ServiceHistoryItem>>((ref) => HistoryNotifier());

// Bundlings
class BundlingsNotifier extends StateNotifier<List<Bundling>> {
  BundlingsNotifier() : super(const []);
  void set(List<Bundling> list) => state = list;
}
final bundlingsProvider = StateNotifierProvider<BundlingsNotifier, List<Bundling>>((ref) => BundlingsNotifier());

// Promos
class PromosNotifier extends StateNotifier<List<Promo>> {
  PromosNotifier() : super(const []);
  void set(List<Promo> list) => state = list;
}
final promosProvider = StateNotifierProvider<PromosNotifier, List<Promo>>((ref) => PromosNotifier());

// Loyalty
final loyaltyPointsProvider = StateProvider<int>((ref) => 0);
