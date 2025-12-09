import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../widgets/neumorphic_header.dart';

class OrderHistoryPage extends ConsumerWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);
    final bookings = ref.watch(bookingsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 150,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Riwayat Transaksi'),
              background: Container(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: NeumorphicHeader(
                title: 'Riwayat Pesanan & Layanan',
                subtitle: 'Lihat semua transaksi Anda sebelumnya',
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index < orders.length) {
                  final order = orders[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text('Pesanan #${order.id.substring(0, 8)}'),
                      subtitle: Text('Total: Rp ${order.total.toStringAsFixed(0)} - ${order.items.length} item'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // TODO: Navigate to order detail page
                      },
                    ),
                  );
                } else if (index < orders.length + bookings.length) {
                  final booking = bookings[index - orders.length];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text('Layanan: ${booking.serviceType}'),
                      subtitle: Text('Status: ${booking.status} - ${booking.scheduledAt.toLocal().toString().split(' ')[0]}'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // TODO: Navigate to booking detail page
                      },
                    ),
                  );
                }
                return null;
              },
              childCount: orders.length + bookings.length,
            ),
          ),
        ],
      ),
    );
  }
}
