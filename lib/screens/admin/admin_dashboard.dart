import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superauto/providers/app_providers.dart';
import 'admin_product.dart';
import 'admin_booking.dart';
import 'admin_history.dart';
import 'admin_profile.dart';
import 'admin_order_list_page.dart';
import 'admin_promo_page.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  int _selectedIndex = 0;


  final List<Widget> screens = [
    AdminProducts(),
    AdminOrderListPage(),
    AdminBookingPage(),
    AdminHistoryPage(),
    AdminPromoPage(),
    AdminProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: screens,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) {
          print('Navigating to index: $i');
          setState(() => _selectedIndex = i);
        },
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        elevation: 4.0,
        destinations: [
          NavigationDestination(icon: const Icon(Icons.shopping_bag), label: "Products"),
          NavigationDestination(
            icon: Consumer(
              builder: (context, ref, child) {
                final pendingOrdersCount = ref.watch(pendingOrdersCountProvider);
                return pendingOrdersCount.when(
                  data: (count) => Badge(
                    isLabelVisible: count > 0,
                    label: Text('$count'),
                    child: const Icon(Icons.receipt),
                  ),
                  loading: () => Icon(Icons.receipt),
                  error: (err, stack) => Icon(Icons.receipt),
                );
              },
            ),
            label: "Orders",
          ),
          NavigationDestination(
            icon: Consumer(
              builder: (context, ref, child) {
                final pendingBookingsCount = ref.watch(pendingBookingsCountProvider);
                return Badge(
                  isLabelVisible: pendingBookingsCount > 0,
                  label: Text('$pendingBookingsCount'),
                  child: Icon(Icons.calendar_month),
                );
              },
            ),
            label: "Bookings",
          ),
          NavigationDestination(icon: Icon(Icons.history), label: "History"),
          NavigationDestination(icon: Icon(Icons.local_offer), label: "Promo"),
          NavigationDestination(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
