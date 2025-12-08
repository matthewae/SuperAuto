import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import '../screens/tracking/tracking_page.dart';
import '../screens/history/history_page.dart';
import '../screens/catalog/catalog_page.dart';
import '../screens/catalog/product_detail_page.dart';
import '../screens/cart/cart_page.dart';
import '../screens/checkout/checkout_page.dart';
import '../screens/bundling/bundling_page.dart';
import '../screens/promo/promo_page.dart';
import '../screens/loyalty/loyalty_page.dart';
import '../screens/history/order_history_page.dart';
import '../screens/profile/profile_page.dart';
import '../screens/profile/edit_profile_page.dart';
import '../widgets/main_shell.dart';

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
          path: '/admin',
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
        path: '/booking',
        name: 'booking',
        builder: (context, state) => const BookingPage(),
      ),
      GoRoute(
        path: '/tracking',
        name: 'tracking',
        builder: (context, state) => const TrackingPage(),
      ),
      GoRoute(
        path: '/history',
        name: 'history',
        builder: (context, state) => const HistoryPage(),
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
        path: '/bundling',
        name: 'bundling',
        builder: (context, state) => const BundlingPage(),
      ),
      GoRoute(
        path: '/promo',
        name: 'promo',
        builder: (context, state) => const PromoPage(),
      ),
      GoRoute(
        path: '/loyalty',
        name: 'loyalty',
        builder: (context, state) => const LoyaltyPage(),
      ),
      GoRoute(
        path: '/order-history',
        name: 'order-history',
        builder: (context, state) => const OrderHistoryPage(),
      ),
      GoRoute(
        path: '/edit-profile',
        name: 'edit-profile',
        builder: (context, state) => const EditProfilePage(),
      ),
      // Rute lain akan ditambahkan seiring fitur dibangun
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Route error: ${state.error}')),
    ),
  );
});
