import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/neumorphic_header.dart';
import '../../widgets/neumorphic_bottom_nav.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GFAppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Scan QR Registrasi Mobil',
            onPressed: () => context.push('/scan'),
            icon: const Icon(Icons.qr_code_scanner),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const NeumorphicHeader(title: 'Ringkasan', subtitle: 'Belum ada jadwal servis terdekat'),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('Mobil Utama'),
              subtitle: const Text('Pilih atau tambahkan mobil'),
              trailing: const Icon(Icons.directions_car),
              onTap: () => context.push('/cars'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('Jadwal Servis Terdekat'),
              subtitle: const Text('Belum ada jadwal'),
              trailing: const Icon(Icons.schedule),
              onTap: () => context.push('/booking'),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              GFButton(onPressed: () => context.push('/booking'), text: 'Booking Servis', icon: const Icon(Icons.build)),
              GFButton(onPressed: () => context.push('/catalog'), text: 'Katalog Produk', icon: const Icon(Icons.store)),
              GFButton(onPressed: () => context.push('/promo'), text: 'Promo', icon: const Icon(Icons.card_giftcard)),
              GFButton(onPressed: () => context.push('/loyalty'), text: 'Rewards', icon: const Icon(Icons.redeem)),
            ],
          ),
        ],
      ),
      bottomNavigationBar: NeumorphicBottomNav(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              context.push('/history');
              break;
            case 2:
              context.push('/cart');
              break;
            case 3:
              context.push('/profile');
              break;
          }
        },
      ),
    );
  }
}

// Shortcut buttons replaced with GFButton variants to meet UI rules
