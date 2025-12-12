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

  // List of screens in the admin dashboard
  // Make sure the order matches the navigation indices
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
      // appBar: AppBar(
      //   title: const Text('Admin Panel'),
      //   centerTitle: true,
      //   leading: Builder(
      //     builder: (BuildContext context) {
      //       return IconButton(
      //         icon: const Icon(Icons.menu),
      //         onPressed: () {
      //           Scaffold.of(context).openDrawer();
      //         },
      //       );
      //     },
      //   ),
      // ),
      // drawer: Drawer(
      //   child: ListView(
      //     padding: EdgeInsets.zero,
      //     children: <Widget>[
      //       const DrawerHeader(
      //         decoration: BoxDecoration(
      //           color: Colors.blue,
      //         ),
      //         child: Text(
      //           'Admin Menu',
      //           style: TextStyle(
      //             color: Colors.white,
      //             fontSize: 24,
      //           ),
      //         ),
      //       ),
      //       ListTile(
      //         leading: const Icon(Icons.shopping_bag),
      //         title: const Text('Products'),
      //         onTap: () {
      //           Navigator.pop(context); // Close the drawer
      //           setState(() {
      //             _selectedIndex = 0;
      //           });
      //         },
      //       ),
      //       ListTile(
      //         leading: const Icon(Icons.receipt),
      //         title: Consumer(
      //           builder: (context, ref, child) {
      //             final pendingOrdersCount = ref.watch(pendingOrdersCountProvider);
      //             return pendingOrdersCount.when(
      //               data: (count) => Text('Orders (${count > 0 ? count : ''})'),
      //               loading: () => const Text('Orders (...)'),
      //               error: (err, stack) => const Text('Orders (Error)'),
      //             );
      //           },
      //         ),
      //         onTap: () {
      //           Navigator.pop(context); // Close the drawer
      //           setState(() {
      //             _selectedIndex = 1;
      //           });
      //         },
      //       ),
      //       ListTile(
      //         leading: const Icon(Icons.calendar_month),
      //         title: Consumer(
      //           builder: (context, ref, child) {
      //             final pendingBookingsCount = ref.watch(pendingBookingsCountProvider);
      //             return Text('Booking (${pendingBookingsCount > 0 ? pendingBookingsCount : ''})');
      //           },
      //         ),
      //         onTap: () {
      //           Navigator.pop(context); // Close the drawer
      //           setState(() {
      //             _selectedIndex = 2;
      //           });
      //         },
      //       ),
      //       ListTile(
      //         leading: const Icon(Icons.history),
      //         title: const Text('History'),
      //         onTap: () {
      //           Navigator.pop(context); // Close the drawer
      //           setState(() {
      //             _selectedIndex = 3;
      //           });
      //         },
      //       ),
      //       ListTile(
      //         leading: const Icon(Icons.local_offer),
      //         title: const Text('Promo'),
      //         onTap: () {
      //           Navigator.pop(context); // Close the drawer
      //           setState(() {
      //             _selectedIndex = 4;
      //           });
      //         },
      //       ),
      //       ListTile(
      //         leading: const Icon(Icons.person),
      //         title: const Text('Profile'),
      //         onTap: () {
      //           Navigator.pop(context); // Close the drawer
      //           setState(() {
      //             _selectedIndex = 5;
      //           });
      //         },
      //       ),
      //     ],
      //   ),
      // ),
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
