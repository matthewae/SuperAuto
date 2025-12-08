import 'package:flutter/material.dart';
import 'admin_product.dart';
import 'admin_orders.dart';
import 'admin_booking.dart';
import 'admin_history.dart';
import 'admin_profile.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final screens = const [
    AdminProducts(),
    AdminOrdersPage(),
    AdminBookingPage(),
    AdminHistoryPage(),
    AdminProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Image.asset(
            'assets/images/Ori.png',
            height: 40, // Sesuaikan tinggi sesuai kebutuhan
          ),
        ),
      ),
      body: SafeArea(child: screens[_selectedIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.shopping_bag), label: "Products"),
          NavigationDestination(icon: Icon(Icons.receipt), label: "Orders"),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: "Booking"),
          NavigationDestination(icon: Icon(Icons.history), label: "History"),
          NavigationDestination(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
