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
      extendBody: true, // WAJIB! Biar bottom nav nembus & header bisa nembus status bar
      body: Column(
        children: [
          // HEADER + STATUS BAR PADDING
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).viewPadding.top, // ini yang bikin nggak kepotong!
              left: 16,
              right: 16,
              bottom: 8,
            ),
            child: NeumorphicHeader(
              title: _getTitleForIndex(_currentIndex),
              subtitle: _currentIndex == 0 ? 'Selamat datang kembali!' : null,
            ),
          ),
          // ISI HALAMAN
          Expanded(child: widget.child),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewPadding.bottom, // biar nggak ketutup notch
          left: 16,
          right: 16,
        ),
        child: NeumorphicBottomNav(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
            _onItemTapped(index, context);
          },
        ),
      ),
    );
  }

  String _getTitleForIndex(int index) {
    const titles = ['Home', 'Riwayat', 'Catalog', 'Profile'];
    return titles[index];
  }

  void _onItemTapped(int index, BuildContext context) {
    const paths = ['/home', '/history', '/catalog', '/profile'];
    GoRouter.of(context).go(paths[index]);
  }
}