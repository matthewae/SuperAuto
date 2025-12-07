import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/neumorphic_header.dart';
import '../../widgets/neumorphic_bottom_nav.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    Widget _buildActionButton(BuildContext context, String text, IconData icon, VoidCallback onTap) {
      return SizedBox(
        width: (MediaQuery.of(context).size.width - 56) / 2,
        child: GFButton(
          onPressed: onTap,
          text: text,
          icon: Icon(icon),
          size: GFSize.SMALL,
          fullWidthButton: true,
          shape: GFButtonShape.pills,
          color: Theme.of(context).colorScheme.primaryContainer,
          textColor: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      );
    }
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
              title: const Text('Booking Servis'),
              subtitle: const Text('Jadwalkan servis mobil Anda'),
              trailing: const Icon(Icons.build),
              onTap: () => context.push('/booking'), // Add this route in your router
            ),
          ),

          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildActionButton(context, 'Booking History', Icons.history, () => context.push('/bookings')),
              _buildActionButton(context, 'Katalog Produk', Icons.store, () => context.push('/catalog')),
              _buildActionButton(context, 'Promo', Icons.card_giftcard, () => context.push('/promo')),
              _buildActionButton(context, 'Rewards', Icons.redeem, () => context.push('/loyalty')),
            ],
          ),
        ],
      ),
    );
  }
}
