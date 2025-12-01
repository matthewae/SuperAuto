import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/login_page.dart';
import '../features/home/home_page.dart';
import '../features/cars/cars_list_page.dart';
import '../features/cars/car_detail_page.dart';
import '../features/cars/car_scan_page.dart';
import '../features/booking/booking_page.dart';
import '../features/tracking/tracking_page.dart';
import '../features/history/history_page.dart';
import '../features/catalog/catalog_page.dart';
import '../features/catalog/product_detail_page.dart';
import '../features/cart/cart_page.dart';
import '../features/checkout/checkout_page.dart';
import '../features/bundling/bundling_page.dart';
import '../features/promo/promo_page.dart';
import '../features/loyalty/loyalty_page.dart';
import '../features/profile/profile_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/scan',
        name: 'scan',
        builder: (context, state) => const CarScanPage(),
      ),
      GoRoute(
        path: '/cars',
        name: 'cars',
        builder: (context, state) => const CarsListPage(),
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
        path: '/catalog',
        name: 'catalog',
        builder: (context, state) => const CatalogPage(),
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
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),
      // Rute lain akan ditambahkan seiring fitur dibangun
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Route error: ${state.error}')),
    ),
  );
});
