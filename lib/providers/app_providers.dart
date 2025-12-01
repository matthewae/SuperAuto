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

const _uuid = Uuid();

// Auth
final authProvider = StateProvider<AppUser?>((ref) => null);

void loginDummy(WidgetRef ref, {String? email}) {
  ref.read(authProvider.notifier).state = AppUser(
    id: _uuid.v4(),
    email: email ?? 'user@example.com',
    name: 'User',
  );
}

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
class ProductsNotifier extends StateNotifier<List<Product>> {
  ProductsNotifier() : super(const []);
  void set(List<Product> list) => state = list;
}
final productsProvider = StateNotifierProvider<ProductsNotifier, List<Product>>((ref) => ProductsNotifier());

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
