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

const _uuid = Uuid();

// Auth
final authProvider = StateProvider<User?>((ref) => null);
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Provider untuk menyimpan user aktif
final userStateProvider = StateProvider<User?>((ref) => null);
final productDaoProvider = Provider<ProductDao>((ref) => ProductDao());


// Cars
class CarsNotifier extends StateNotifier<List<Car>> {
  CarsNotifier() : super(const []);
  void add(Car car) => state = [...state, car];
  void remove(String id) => state = state.where((c) => c.id != id).toList();
  void update(Car car) => state = [for (final c in state) if (c.id == car.id) car else c];
}

final carsProvider = StateNotifierProvider<CarsNotifier, List<Car>>((ref) => CarsNotifier());
final mainCarIdProvider = StateProvider<String>((ref) => '');

// Products
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
  void addItem(Product product, {int quantity = 1}) {
    final existing = state.items.where((i) => i.productId == product.id).toList();
    List<CartItem> newItems = [...state.items];
    if (existing.isEmpty) {
      newItems.add(CartItem(productId: product.id, quantity: quantity, price: product.price));
    } else {
      final idx = newItems.indexWhere((i) => i.productId == product.id);
      final curr = newItems[idx];
      newItems[idx] = CartItem(productId: curr.productId, quantity: curr.quantity + quantity, price: curr.price);
    }
    state = Cart(items: newItems, appliedPromoId: state.appliedPromoId);
  }
  void removeItem(String productId) {
    state = Cart(items: state.items.where((i) => i.productId != productId).toList(), appliedPromoId: state.appliedPromoId);
  }
  void clear() => state = const Cart();
  void applyPromo(String? promoId) => state = Cart(items: state.items, appliedPromoId: promoId);
}
final cartProvider = StateNotifierProvider<CartNotifier, Cart>((ref) => CartNotifier());

// Orders (simple list)
class OrdersNotifier extends StateNotifier<List<Order>> {
  OrdersNotifier() : super(const []);
  void add(Order order) => state = [...state, order];
}
final ordersProvider = StateNotifierProvider<OrdersNotifier, List<Order>>((ref) => OrdersNotifier());

// Bookings
class BookingsNotifier extends StateNotifier<List<ServiceBooking>> {
  BookingsNotifier() : super(const []);
  void add(ServiceBooking b) => state = [...state, b];
  void updateStatus(String id, ServiceStatus status) => state = [
        for (final b in state)
          if (b.id == id)
            ServiceBooking(
              id: b.id,
              userId: b.userId,
              carId: b.carId,
              type: b.type,
              workshop: b.workshop,
              scheduledAt: b.scheduledAt,
              estimatedCost: b.estimatedCost,
              status: status,
            )
          else
            b
      ];
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
