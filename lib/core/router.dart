import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:superauto/screens/booking/booking_detail_page.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/admin_product.dart';
import '../screens/auth/login_page.dart';
import '../screens/auth/register_page.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/home/home_page.dart';
import '../screens/cars/cars_list_page.dart';
import '../screens/cars/car_detail_page.dart';
import '../screens/cars/car_scan_page.dart';
import '../screens/booking/booking_page.dart';
import '../screens/catalog/catalog_page.dart';
import '../screens/catalog/product_detail_page.dart';
import '../screens/cart/cart_page.dart';
import '../screens/checkout/checkout_page.dart';
import '../screens/promo/promo_page.dart';
import '../screens/history/order_history_page.dart';
import '../screens/profile/profile_page.dart';
import '../screens/profile/edit_profile_page.dart';
import '../widgets/main_shell.dart';
import '../screens/booking/bookings_page.dart';
import '../screens/cars/car_edit_page.dart';
import '../screens/checkout/order_confirmation_page.dart';
import '../screens/admin/order_detail_page.dart';
import '../providers/app_providers.dart';
import '../screens/admin/admin_order_list_page.dart';
import '../screens/admin/admin_order_detail_page.dart';
import '../screens/admin/admin_history.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/admin',
        name: 'admindashboard',
        builder: (_, __) => const AdminDashboard()),
      GoRoute(
          path: '/admin/products',
          name: 'adminproduct',
          builder: (_, __) => const AdminProducts()),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/cars',
            name: 'cars',
            builder: (context, state) => const CarsListPage(),
          ),
          GoRoute(
            path: '/catalog',
            name: 'catalog',
            builder: (context, state) => const CatalogPage(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),
      GoRoute(
        path: '/scan',
        name: 'scan',
        builder: (context, state) => const CarScanPage(),
      ),
      GoRoute(
        path: '/cars/:id',
        name: 'car-detail',
        builder: (context, state) => CarDetailPage(carId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/cars/:id/edit',
        name: 'car-edit',  // This is the name you're using in pushNamed
        builder: (context, state) {
          final carId = state.pathParameters['id']!;
          return CarEditPage(carId: carId);
        },
      ),
      GoRoute(
        path: '/booking',
        name: 'booking',
        builder: (context, state) => const BookingPage(),
      ),
      GoRoute(
        path: '/bookings',
        name: 'bookings',
        builder: (context, state) => const BookingsPage(),
      ),
      GoRoute(
        path: '/booking-detail/:id',
        name: 'booking-detail',
        builder: (context, state) {
          final bookingId = state.pathParameters['id']!;
          return BookingDetailPage(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: '/product/:id',
        name: 'product-detail',
        builder: (context, state) => ProductDetailPage(productId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/cart',
        name: 'cart',
        builder: (context, state) => const CartPage(),
      ),
      GoRoute(
        path: '/checkout',
        name: 'checkout',
        builder: (context, state) => const CheckoutPage(),
      ),
      GoRoute(
        path: '/order-confirmation',
        name: 'order-confirmation',
        builder: (context, state) {
          final orderId = state.extra as String? ?? '';
          return OrderConfirmationPage(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/admin/orders',
        name: 'admin-orders',
        builder: (context, state) => const AdminOrderListPage(),
      ),
      GoRoute(
        path: '/order-history',
        name: 'order-history',
        builder: (context, state) => const OrderHistoryPage(),
      ),

      GoRoute(
        path: '/order-detail/:id',
        name: 'order-detail',


        builder: (context, state) {
          final orderId = state.pathParameters['id']!;
          final container = ProviderScope.containerOf(context);
          final orders = container.read(ordersProvider);

          final order = orders.firstWhere(
                (o) => o.id == orderId,
            orElse: () => throw Exception('Order tidak ditemukan'),
          );

          return OrderDetailPage(order: order);
        },
      ),
      GoRoute(
        path: '/admin/detail/:id',
        name: 'admin-order-detail',
        builder: (context, state) {
          final orderId = state.pathParameters['id']!;
          return AdminOrderDetailPage(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/admin/history',
        name: 'admin-history',
        builder: (context, state) => const AdminHistoryPage(),
      ),
      GoRoute(
        path: '/promo',
        name: 'promo',
        builder: (context, state) => const PromoListPage(),
      ),
      GoRoute(
        path: '/edit-profile',
        name: 'edit-profile',
        builder: (context, state) => const EditProfilePage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Route error: ${state.error}')),
    ),
  );
});
