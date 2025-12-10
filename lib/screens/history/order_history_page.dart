import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../models/order.dart';
import 'package:go_router/go_router.dart';
class OrderHistoryPage extends ConsumerWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pesanan'),
      ),
      body: orders.isEmpty
          ? const Center(
        child: Text(
          'Belum ada riwayat pesanan',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _OrderTile(order: order);
        },
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final Order order;

  const _OrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final shortId = order.id.length > 8 ? order.id.substring(0, 8) : order.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text('Pesanan #$shortId'),
        subtitle: Text(
          'Total: Rp ${order.total.toStringAsFixed(0)} • '
              '${order.items.length} item • '
              '${order.status}',
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          context.go('/order-detail/${order.id}');
        },
      ),
    );
  }
}
