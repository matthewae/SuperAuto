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
import '../models/promo.dart';
import '../models/enums.dart';
import '../models/cart.dart';
import '../services/auth_service.dart';
import '../data/dao/product_dao.dart';
import '../data/dao/car_dao.dart';
import '../data/dao/user_dao.dart';
import '../data/dao/service_booking_dao.dart';
import '../data/db/app_database.dart';
import '../data/dao/order_dao.dart';
import '../data/dao/cart_dao.dart';
import '../data/dao/promo_dao.dart';
import '../utils/image_placeholder.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../services/car_service.dart';
import '../services/service_booking_service.dart';
import '../services/product_service.dart';
import '../services/cart_service.dart';
import '../services/promo_service.dart';
import '../services/order_service.dart';


const _uuid = Uuid();


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

final carServiceProvider = Provider<CarService>((ref) {
  final client = sb.Supabase.instance.client;
  final carDao = ref.watch(carDaoProvider);
  return CarService(client: client, carDao: carDao);
});

final productServiceProvider = Provider<ProductService>((ref) {
  final client = sb.Supabase.instance.client;
  final productDao = ref.watch(productDaoProvider);
  return ProductService(client: client, productDao: productDao);
});

final cartServiceProvider = Provider<CartService>((ref) {
  final client = sb.Supabase.instance.client;
  final cartDao = CartDao.instance;
  return CartService(client: client, cartDao: cartDao);
});

final promoServiceProvider = Provider<PromoService>((ref) {
  final client = sb.Supabase.instance.client;
  final promoDao = PromoDao.instance;
  return PromoService(client: client, promoDao: promoDao);
});

final orderServiceProvider = Provider<OrderService>((ref) {
  final client = sb.Supabase.instance.client;
  final orderDao = ref.watch(orderDaoProvider);
  return OrderService(client: client, orderDao: orderDao);
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
    if (_isInitialized) return;
    try {
      final user = await _authService.init();
      print('AuthNotifier initialized. User: ${user?.email}');
      state = AsyncValue.data(user);
    } catch (e, stack) {
      print('Error initializing AuthNotifier: $e\n$stack');
      state = AsyncValue.error(e, stack);
    } finally {
      _isInitialized = true;
    }
  }

  Future<User?> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.signup(
        name: name,
        email: email,
        password: password,
      );

      if (user != null) {
        state = AsyncValue.data(user);
        return user;
      } else {
        state = const AsyncValue.data(null);
        return null;
      }
    } catch (e, stack) {
      print('Signup error: $e\n$stack');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
  Future<bool> verifyCurrentPassword(String password) async {
    try {
      final authService = _ref.read(authServiceProvider);
      final currentUser = authService.client.auth.currentUser;
      if (currentUser == null) return false;

      final response = await authService.client.auth.signInWithPassword(
        email: currentUser.email!,
        password: password,
      );
      return response.user != null;
    } catch (e) {
      return false;
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

  Future<void> logout() async {
    try {
      print('Starting logout process...');
      await _authService.logout();
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

  Future<void> updateProfile({
    required String name,
    required String email,
    String? currentPassword,
    String? newPassword,
  }) async {
    try {
      final user = state.when(
        data: (user) => user,
        loading: () => null,
        error: (_, __) => null,
      );

      if (user == null) {
        throw Exception('Pengguna tidak login');
      }

      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(email)) {
        throw Exception('Format email tidak valid');
      }

      final updatedUser = await _authService.updateProfile(
        user: user,
        name: name,
        email: email,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      state = AsyncValue.data(updatedUser);
    } catch (e, stack) {
      print('Error updating profile: $e\n$stack');
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

// Cars
final carsProvider = StateNotifierProvider<CarsNotifier, List<Car>>((ref) {
  final carService = ref.watch(carServiceProvider);
  return CarsNotifier(carService, ref);
});

class CarsNotifier extends StateNotifier<List<Car>> {
  final CarService _carService;
  final Ref _ref;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  CarsNotifier(this._carService, this._ref) : super(const []) {
    _loadCars();
    _ref.listen<AsyncValue<User?>>(authProvider, (previous, next) {
      _loadCars();
    });
  }

  Future<void> _loadCars() async {
    if (_isLoading) return;

    _isLoading = true;
    state = [...state];

    try {
      final user = _ref.read(authProvider).value;
      if (user?.id == null) {
        state = [];
        return;
      }

      print('Loading cars for user: ${user!.id}');

      try {
        final carsFromSupabase = await _carService.fetchAndCacheCars(user!.id);
        state = carsFromSupabase;
        print('Successfully loaded ${carsFromSupabase.length} cars from Supabase.');
      } catch (e) {
        print('Failed to fetch from Supabase, falling back to local cache. Error: $e');
        final cachedCars = await _carService.carDao.getCachedCarsByUserId(user!.id);
        state = cachedCars;
      }
    } catch (e) {
      print('Error in _loadCars: $e');
      state = [];
    } finally {
      _isLoading = false;
      state = [...state];
    }
  }

  Future<void> add(Car car) async {
    try {
      _isLoading = true;
      state = [...state];

      final newCar = await _carService.addCar(car);

      if (state.isEmpty) {
        print('First car added, setting as main car: ${newCar.id}');
        await setMainCar(newCar.id);
      } else {
        state = [newCar, ...state];
      }
    } catch (e) {
      print('Error adding car: $e');
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> updateCar(Car car) async {
    try {
      _isLoading = true;
      state = [...state];
      final updatedCar = await _carService.updateCar(car);
      state = state.map((c) => c.id == updatedCar.id ? updatedCar : c).toList();
    } catch (e) {
      print('Error updating car: $e');
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> remove(String id) async {
    try {
      _isLoading = true;
      state = [...state];

      await _carService.deleteCar(id);

      state = state.where((c) => c.id != id).toList();
    } catch (e) {
      print('Error removing car: $e');
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> setMainCar(String carId) async {
    final user = _ref.read(authProvider).value;
    if (user == null) return;

    await _carService.setMainCar(user.id, carId);
    await _loadCars();
  }
}

// Products
final productsProvider = StateNotifierProvider<ProductNotifier, List<Product>>((ref) {
  final productService = ref.watch(productServiceProvider);
  return ProductNotifier(productService);
});

class ProductNotifier extends StateNotifier<List<Product>> {
  final ProductService _productService;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  ProductNotifier(this._productService) : super([]) {
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (_isLoading) return;

    _isLoading = true;
    state = [...state];

    try {
      final productsFromSupabase = await _productService.fetchAndCacheProducts();
      state = productsFromSupabase;
      print('Successfully loaded ${productsFromSupabase.length} products from Supabase.');
    } catch (e) {
      print('Failed to fetch from Supabase, falling back to local cache. Error: $e');
      final cachedProducts = await _productService.productDao.getAll();
      state = cachedProducts;
    } finally {
      _isLoading = false;
      state = [...state];
    }
  }

  Future<void> addProduct(Product product) async {
    try {
      _isLoading = true;
      state = [...state];
      final newProduct = await _productService.addProduct(product);
      state = [newProduct, ...state];
    } catch (e) {
      print('Error adding product: $e');
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      _isLoading = true;
      state = [...state];

      final updatedProduct = await _productService.updateProduct(product);
      state = state.map((p) => p.id == updatedProduct.id ? updatedProduct : p).toList();
    } catch (e) {
      print('Error updating product: $e');
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      _isLoading = true;
      state = [...state];

      await _productService.deleteProduct(id);
      state = state.where((p) => p.id != id).toList();
    } catch (e) {
      print('Error deleting product: $e');
      rethrow;
    } finally {
      _isLoading = false;
    }
  }
}


// Cart Provider
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  final cartService = ref.watch(cartServiceProvider);
  return CartNotifier(cartService, ref);
});
class CartNotifier extends StateNotifier<CartState> {
  final CartService _cartService;
  final Ref _ref;
  bool _isLoading = false;

  CartNotifier(this._cartService, this._ref) : super(const CartState()) {
    _init();
  }

  Future<void> _init() async {
    await loadCart();
    _ref.listen<AsyncValue<User?>>(authProvider, (_, next) => loadCart());
  }

  String get _userId => _ref.read(authProvider).value?.id ?? 'guest';

  Future<void> loadCart() async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      final user = _ref.read(authProvider).value;
      if (user?.id == null) {
        state = const CartState();
        return;
      }

      try {
        final cartState = await _cartService.fetchAndCacheCart(user!.id);
        state = cartState;
        print('Successfully loaded cart from Supabase.');

        await _cartService.syncPromoDetails(user.id);

        final updatedCartState = await _cartService.cartDao.getCart(user.id);
        state = updatedCartState;
      } catch (e) {
        print('Failed to fetch cart from Supabase, falling back to local cache. Error: $e');
        final localCartState = await _cartService.cartDao.getCart(_userId);
        state = localCartState;
      }
    } finally {
      _isLoading = false;
    }
  }

  Future<void> addItem({
    required String productId,
    required String productName,
    required double price,
    int quantity = 1,
    String? imageUrl,
  }) async {
    final item = CartItem(
      productId: productId,
      productName: productName,
      price: price,
      quantity: quantity,
      userId: _userId,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
      appliedPromoId: state.appliedPromoId,
      discount: state.discount,
    );

    await _cartService.addItem(item);
    await loadCart();
  }

  Future<void> updateItemQuantity(String productId, int newQuantity) async {
    await _cartService.updateItemQuantity(
      userId: _userId,
      productId: productId,
      newQuantity: newQuantity,
    );
    await loadCart();
  }

  Future<void> removeItem(String productId) async {
    await _cartService.removeItem(_userId, productId);
    await loadCart();
  }

  Future<void> clear() async {
    await _cartService.clearCart(_userId);
    state = const CartState();
  }


  Future<void> applyPromo(String? promoId) async {
    if (promoId == null) {
      await _cartService.applyPromoToCart(_userId, null, 0.0);
      state = state.copyWith(appliedPromoId: null, discount: 0.0);
      return;
    }

    try {
      final promos = await _ref.read(promoServiceProvider).getPromosByType('product_discount');
      final promo = promos.where((p) => p.id == promoId).firstOrNull;

      if (promo == null || !promo.isActive()) {
        throw Exception('Promo tidak valid atau tidak aktif');
      }

      final discount = promo.calculateDiscount(state.subtotal);

      await _cartService.applyPromoToCart(_userId, promoId, discount);

      state = state.copyWith(appliedPromoId: promoId, discount: discount);
    } catch (e) {
      print('Error applying promo: $e');
      rethrow;
    }
  }

  Future<void> setDeliveryFee(double fee) async {
    state = state.copyWith(deliveryFee: fee);
  }

  double get subtotal => state.subtotal;
  double get total => state.total;
  int get itemCount => state.itemCount;
  List<CartItem> get items => state.items;
}

// Orders

class OrdersNotifier extends StateNotifier<List<Order>> {
  final Ref ref;
  bool _isLoading = false;

  OrdersNotifier(this.ref) : super(const []) {
    _loadOrders();
  }

  bool get isLoading => _isLoading;

  Future<void> _loadOrders() async {
    if (_isLoading) return;

    _isLoading = true;
    state = [...state];
    try {
      final user = ref.read(authProvider).valueOrNull;
      if (user == null) {
        state = [];
        return;
      }

      final orderService = ref.read(orderServiceProvider);

      print('Loading orders for user: ${user.id}');

      try {
        final orders = await orderService.fetchAndCacheOrders(user.id);

        state = orders;

        print('Successfully loaded ${orders.length} orders from Supabase.');
      } catch (e) {
        print('Failed to fetch from Supabase, falling back to local cache. Error: $e');
        final cachedOrders = await orderService.getCachedOrders(user.id);

        state = cachedOrders;

        print('Loaded ${cachedOrders.length} orders from local cache.');
      }
    } catch (e) {
      print('Error loading orders: $e');
      state = [];
    } finally {
      _isLoading = false;
      state = [...state];
    }
  }

  Future<void> refresh() async {
    print('Manual refresh triggered');
    await _loadOrders();
  }

  Future<Order> createOrder({
    required List<OrderItem> items,
    required String paymentMethod,
    String? shippingMethod,
    String? shippingAddress,
  }) async {
    try {
      _isLoading = true;
      state = [...state];

      final user = ref.read(authProvider).value;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final orderService = ref.read(orderServiceProvider);

      final cartState = ref.read(cartProvider);

      final subtotal = items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

      final discountedTotal = cartState.total;

      print('Creating order with subtotal: $subtotal, discount: ${cartState.discount}, total: $discountedTotal');

      final newOrder = await orderService.createOrder(
        userId: user.id,
        userName: user.name ?? 'Customer',
        items: items,
        total: discountedTotal,
        paymentMethod: paymentMethod,
        shippingMethod: shippingMethod,
        shippingAddress: shippingAddress,
      );

      print('Order created successfully: ${newOrder.id}');

      state = [newOrder, ...state];

      return newOrder;
    } catch (e) {
      print('Error creating order: $e');
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      _isLoading = true;
      state = [...state];

      final orderService = ref.read(orderServiceProvider);
      final updatedOrder = await orderService.updateOrderStatus(orderId, status);

      print('Order status updated: $orderId -> $status');

      state = state.map((order) => order.id == orderId ? updatedOrder : order).toList();
    } catch (e) {
      print('Error updating order status: $e');
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> updateTrackingNumber(String orderId, String trackingNumber) async {
    try {
      _isLoading = true;
      state = [...state];

      final orderService = ref.read(orderServiceProvider);
      final updatedOrder = await orderService.updateTrackingNumber(orderId, trackingNumber);

      print('Tracking number updated: $orderId -> $trackingNumber');

      state = state.map((order) => order.id == orderId ? updatedOrder : order).toList();
    } catch (e) {
      print('Error updating tracking number: $e');
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<Order?> getOrderById(String orderId) async {
    try {
      final orderService = ref.read(orderServiceProvider);

      final orderInState = state.firstWhere((order) => order.id == orderId, orElse: () => null as Order);
      if (orderInState != null) return orderInState;

      return await orderService.getCachedOrder(orderId);
    } catch (e) {
      print('Error getting order by ID: $e');
      return null;
    }
  }

  Future<void> cancelOrder(String orderId) async {
    try {
      await updateOrderStatus(orderId, 'cancelled');
      await refresh();
    } catch (e) {
      print('Error cancelling order: $e');
      rethrow;
    }
  }
}

final ordersProvider = StateNotifierProvider<OrdersNotifier, List<Order>>(
      (ref) => OrdersNotifier(ref),
);

final orderDaoProvider = Provider<OrderDao>((ref) {
  return OrderDao();
});

final allOrdersProvider = FutureProvider<List<Order>>((ref) async {
  try {
    final user = ref.read(authProvider).value;
    if (user == null) {
      return [];
    }

    final orderService = ref.read(orderServiceProvider);

    if (user.role == 'admin') {
      return await _fetchAllOrdersFromSupabase(orderService);
    } else {
      return await orderService.fetchAndCacheOrders(user.id);
    }
  } catch (e) {
    print('Error fetching all orders: $e');

    final dao = ref.watch(orderDaoProvider);
    try {
      return await dao.getAll();
    } catch (cacheError) {
      print('Error fetching from cache: $cacheError');
      return [];
    }
  }
});

Future<List<Order>> _fetchAllOrdersFromSupabase(OrderService orderService) async {
  try {
    final client = orderService.client;
    final response = await client
        .from('orders')
        .select()
        .order('created_at', ascending: false);

    print('Orders response from Supabase: $response');

    final orderIds = <String>[];
    for (final order in response) {
      final orderId = order['id'];
      if (orderId != null) {
        orderIds.add(orderId as String);
      }
    }

    final itemsResponse = await client
        .from('order_items')
        .select()
        .inFilter('order_id', orderIds);

    print('Order items response from Supabase: $itemsResponse');

    final Map<String, List<Map<String, dynamic>>> itemsByOrderId = {};
    for (final item in itemsResponse) {
      final orderId = item['order_id'] as String?;
      if (orderId != null) {
        itemsByOrderId.putIfAbsent(orderId, () => []).add(item);
      }
    }

    final List<Order> orders = [];
    for (final orderMap in response) {
      final orderId = orderMap['id'] as String?;
      if (orderId == null) continue;

      final itemsData = itemsByOrderId[orderId] ?? [];

      final items = itemsData.map((itemMap) {
        try {
          return OrderItem.fromMap(itemMap);
        } catch (e) {
          print('Error creating OrderItem from map: $e');
          return OrderItem(
            id: itemMap['id'] as String? ?? '',
            orderId: orderId,
            productId: itemMap['product_id'] as String? ?? '',
            productName: itemMap['product_name'] as String? ?? '',
            price: (itemMap['price'] as num?)?.toDouble() ?? 0.0,
            quantity: itemMap['quantity'] as int? ?? 0,
            imageUrl: itemMap['image_url'] as String?,
          );
        }
      }).toList();

      try {
        orders.add(Order.fromMap(orderMap, items: items));
      } catch (e) {
        print('Error creating Order from map: $e');
        continue;
      }
    }

    print('Final orders list: ${orders.length} orders');

    final orderDao = orderService.orderDao;
    for (final order in orders) {
      try {
        await orderDao.insert(order);
      } catch (e) {
        print('Error caching order: $e');
        continue;
      }
    }

    return orders;
  } catch (e) {
    print('Error fetching all orders from Supabase: $e');
    rethrow;
  }
}

final pendingOrdersCountProvider = Provider<AsyncValue<int>>((ref) {
  final allOrdersAsync = ref.watch(allOrdersProvider);
  return allOrdersAsync.whenData((orders) {
    return orders.where((order) =>
        order.status == 'pending' ||
        order.status == 'processing' ||
        order.status == 'shipped'
    ).length;
  });
});

// Bookings
final bookingsProvider = StateNotifierProvider<BookingsNotifier, List<ServiceBooking>>((ref) {
  final service = ref.watch(serviceBookingServiceProvider);
  final dao = ref.watch(serviceBookingDaoProvider);
  return BookingsNotifier(service, ref);
});

final serviceBookingServiceProvider = Provider<ServiceBookingService>((ref) {
  final client = sb.Supabase.instance.client;
  final dao = ref.watch(serviceBookingDaoProvider);
  return ServiceBookingService(client: client, dao: dao);
});

final pendingBookingsCountProvider = Provider<int>((ref) {
  final bookings = ref.watch(bookingsProvider);
  return bookings.where((booking) =>
      booking.status == 'in_progress' ||
      booking.status == 'confirmed' ||
      booking.status == 'waiting_parts' ||
      booking.status == 'ready_for_pickup'
  ).length;
});

final historyFilterProvider = StateNotifierProvider<HistoryFilterNotifier, BookingFilter>((ref) {
  return HistoryFilterNotifier();
});

class HistoryFilterNotifier extends StateNotifier<BookingFilter> {
  HistoryFilterNotifier() : super(BookingFilter.all);

  void setFilter(BookingFilter filter) {
    state = filter;
  }
}

final historyBookingsProvider = FutureProvider.autoDispose<List<ServiceBooking>>((ref) async {
  final user = ref.watch(authProvider).valueOrNull;
  if (user == null) {
    return [];
  }

  final filter = ref.watch(historyFilterProvider);
  final notifier = ref.read(bookingsProvider.notifier);

  try {
    final allUserBookings = await notifier.getByUserId(user.idString);

    switch (filter) {
      case BookingFilter.completed:
        return allUserBookings.where((b) => b.status == 'completed').toList();
      case BookingFilter.cancelled:
        return allUserBookings.where((b) => b.status == 'cancelled').toList();
      case BookingFilter.all:
      default:
        return allUserBookings
            .where((b) => b.status == 'completed' || b.status == 'cancelled')
            .toList();
    }
  } catch (e) {
    print('Error fetching or filtering bookings: $e');
    return [];
  }
});


class BookingsNotifier extends StateNotifier<List<ServiceBooking>> {
  final ServiceBookingService _service;
  final Ref _ref;
  bool _isInitialized = false;

  BookingsNotifier(this._service, this._ref) : super([]) {
    _loadBookings();
    _ref.listen<AsyncValue<User?>>(authProvider, (previous, next) {
      print('🔄 Auth changed, reloading bookings...');
      _loadBookings();
    });
  }

  Future<void> refresh() async {
    print('🔄 Manual refresh triggered');
    await _loadBookings();
  }

  Future<void> _loadBookings() async {
    try {
      final user = _ref.read(authProvider).value;
      if (user == null) {
        print('No user logged in, clearing bookings');
        state = [];
        return;
      }

      List<ServiceBooking> bookings;

      if (user.role == 'admin') {
        print('Admin user detected, fetching ALL bookings...');

        try {
          bookings = await _service.fetchAndCacheAllBookings();
          print('oaded ${bookings.length} bookings from Supabase (admin)');
        } catch (e) {
          print('Failed to fetch from Supabase, using cache: $e');
          bookings = await _service.dao.getAllCachedBookings();
          print('Loaded ${bookings.length} bookings from cache (admin)');
        }

      } else {
        print('Regular user detected, fetching user bookings...');

        try {
          bookings = await _service.fetchAndCacheBookings(user.id);
          print('Loaded ${bookings.length} bookings from Supabase (user)');
        } catch (e) {
          print('Failed to fetch from Supabase, using cache: $e');
          bookings = await _service.dao.getCachedBookingsByUserId(user.id);
          print('Loaded ${bookings.length} bookings from cache (user)');
        }
      }

      state = bookings;
      _isInitialized = true;

      await _service.dao.debugPrintAllBookings();

    } catch (e, stack) {
      print('❌ Error in _loadBookings: $e');
      print('Stack trace: $stack');
      state = [];
      _isInitialized = false;
    }
  }

  Future<void> add(ServiceBooking booking) async {
    try {
      print('➕ Adding new booking: ${booking.id}');
      final newBooking = await _service.addBooking(booking);
      state = [newBooking, ...state];
      print('Booking added to state');
    } catch (e) {
      print('Error adding booking: $e');
      rethrow;
    }
  }

  Future<void> updateStatus(String id, String status, {String? notes}) async {
    try {
      print('📝 Updating status for $id to $status');
      final updatedBooking = await _service.updateStatus(
        bookingId: id,
        newStatus: status,
        adminNotes: notes,
      );
      state = state.map((b) => b.id == id ? updatedBooking : b).toList();
      print('✅ Status updated in state');
    } catch (e) {
      print(' Error updating booking status: $e');
      rethrow;
    }
  }

  Future<void> updateServiceDetails({
    required String id,
    required List<String> jobs,
    required List<String> parts,
    required int km,
    required double totalCost,
    required String notes,
  }) async {
    try {
      print(' Updating service details for $id');
      final booking = state.firstWhere((b) => b.id == id);
      final updatedBooking = await _service.updateBooking(
        booking.copyWith(
          jobs: jobs,
          parts: parts,
          km: km,
          totalCost: totalCost,
          adminNotes: notes,
        ),
      );
      state = state.map((b) => b.id == id ? updatedBooking : b).toList();
      print(' Service details updated');
    } catch (e) {
      print('Error updating service details: $e');
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
      print('Updating status and details for $id');
      final booking = state.firstWhere((b) => b.id == id);
      final now = DateTime.now();

      final List<Map<String, dynamic>> newStatusHistory = List<Map<String, dynamic>>.from(
        booking.statusHistory ?? [],
      );

      newStatusHistory.add({
        'status': status,
        'updatedAt': now.toIso8601String(),
        'notes': adminNotes,
      });

      double finalTotalCost = totalCost ?? booking.totalCost ?? booking.estimatedCost;
      if (booking.promoId != null && totalCost != null) {
        final discount = await calculateDiscount(id);
        finalTotalCost = (totalCost - discount).clamp(0, double.infinity);
      }

      final updatedBooking = booking.copyWith(
        status: status,
        jobs: jobs ?? booking.jobs,
        parts: parts ?? booking.parts,
        km: km ?? booking.km,
        totalCost: finalTotalCost,
        adminNotes: adminNotes ?? booking.adminNotes,
        updatedAt: now,
        statusHistory: newStatusHistory,
      );

      await _service.updateBooking(updatedBooking);

      state = state.map((b) => b.id == id ? updatedBooking : b).toList();
      print('Status and details updated');

    } catch (e) {
      print('Error updating booking status and details: $e');
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      print('Deleting booking: $id');
      await _service.deleteBooking(id);
      state = state.where((b) => b.id != id).toList();
      print('Booking deleted from state');
    } catch (e) {
      print('Error deleting booking: $e');
      rethrow;
    }
  }

  Future<double> calculateFinalCost(String bookingId) async {
    try {
      final booking = state.firstWhere((b) => b.id == bookingId);
      double finalCost = booking.totalCost ?? booking.estimatedCost;

      if (booking.promoId != null) {
        final discount = await calculateDiscount(bookingId);
        finalCost = (finalCost - discount).clamp(0, double.infinity);
      }

      return finalCost;
    } catch (e) {
      print('Error calculating final cost: $e');
      rethrow;
    }
  }

  Future<double> calculateDiscount(String bookingId) async {
    try {
      final booking = state.firstWhere((b) => b.id == bookingId);
      if (booking.promoId == null) return 0.0;

      final promo = await _ref.read(promoDaoProvider).getById(booking.promoId!);
      if (promo == null || !promo.isActive()) return 0.0;

      final double amount = booking.totalCost ?? booking.estimatedCost;
      return promo.calculateDiscount(amount);
    } catch (e) {
      print('❌ Error calculating discount: $e');
      return 0.0;
    }
  }

  Future<void> update(ServiceBooking booking) async {
    try {
      print('Updating booking: ${booking.id}');
      await _service.updateBooking(booking);
      state = state.map((b) => b.id == booking.id ? booking : b).toList();
      print('Booking updated');
    } catch (e) {
      print('Error updating booking: $e');
      rethrow;
    }
  }

  Future<List<ServiceBooking>> getByUserId(String userId) async {
    return state.where((b) => b.userId == userId).toList();
  }
}

// Promos
final promosProvider = StateNotifierProvider<PromosNotifier, List<Promo>>((ref) {final promoService = ref.watch(promoServiceProvider);
  return PromosNotifier(promoService, ref);
});

class PromosNotifier extends StateNotifier<List<Promo>> {
  final PromoService _promoService;
  final Ref _ref;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  PromosNotifier(this._promoService, this._ref) : super([]) {
    _loadPromos();

    _ref.listen<AsyncValue<User?>>(authProvider, (previous, next) {
      print('Auth state changed, reloading promos...');
      _loadPromos();
    });
  }

  Future<void> _loadPromos() async {
    if (_isLoading) return;

    _isLoading = true;
    state = [...state];

    try {
      final promosFromSupabase = await _promoService.fetchAndCachePromos();
      state = promosFromSupabase;
      print('Successfully loaded ${promosFromSupabase.length} promos from Supabase.');
    } catch (e) {
      print('Failed to fetch from Supabase, falling back to local cache. Error: $e');
      final cachedPromos = await _promoService.promoDao.getAll();
      state = cachedPromos;
    } finally {
      _isLoading = false;
      state = [...state];
    }
  }
  Future<void> add(Promo promo) async {
    await _promoService.addPromo(promo);
    await _loadPromos();
    try {
      _isLoading = true;
      state = [...state];
    } catch (e) {
      print('Error adding promo: $e');
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> update(Promo promo) async {
    try {
      _isLoading = true;
      state = [...state];

      final updatedPromo = await _promoService.updatePromo(promo);
      state = state.map((p) => p.id == updatedPromo.id ? updatedPromo : p).toList();
    } catch (e) {
      print('Error updating promo: $e');
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> delete(String id) async {
    try {
      _isLoading = true;
      state = [...state]; // Trigger loading state

      await _promoService.deletePromo(id);
      state = state.where((p) => p.id != id).toList();
    } catch (e) {
      print('Error deleting promo: $e');
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  Future<List<Promo>> getActivePromos() async {
    try {
      return await _promoService.getActivePromos();
    } catch (e) {
      print('Error getting active promos: $e');
      return [];
    }
  }

  Future<List<Promo>> getActivePromosByType(String type) async {
    try {
      return await _promoService.getPromosByType(type);
    } catch (e) {
      print('Error getting active promos by type: $e');
      return [];
    }
  }
}

// Add promoDaoProvider
final promoDaoProvider = Provider<PromoDao>((ref) {
  return PromoDao.instance;
});


