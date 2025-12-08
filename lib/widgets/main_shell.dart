
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'neumorphic_bottom_nav.dart';
import 'neumorphic_header.dart';

class MainShell extends StatefulWidget {
  const MainShell({required this.child, super.key});

  final Widget child;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          NeumorphicHeader(
            title: _getTitleForIndex(_currentIndex),
          ),
          Expanded(child: widget.child),
        ],
      ),
      bottomNavigationBar: NeumorphicBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _onItemTapped(index, context);
        },
      ),
    );
  }

  String _getTitleForIndex(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Riwayat';
      case 2:
        return 'Catalog';
      case 3:
        return 'Booking';
      case 4:
        return 'Profile';
      default:
        return 'SuperAuto';
    }
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        GoRouter.of(context).go('/home');
        break;
      case 1:
        GoRouter.of(context).go('/history');
        break;
      case 2:
        GoRouter.of(context).go('/catalog');
        break;
      case 3:
        GoRouter.of(context).go('/booking');
        break;
      case 4:
        GoRouter.of(context).go('/profile');
        break;
    }
  }
}