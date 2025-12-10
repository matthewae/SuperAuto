import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/order.dart';
import '../../providers/app_providers.dart';

class OrderDetailPage extends ConsumerWidget {
  final Order order;

  const OrderDetailPage({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canCancel = order.status == 'pending' || order.status == 'processing';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pesanan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Informasi Pesanan'),

          _infoRow('ID Pesanan', '#${order.id.substring(0, 8)}'),
          _infoRow('Status', _mapStatus(order.status)),
          _infoRow('Tanggal', order.createdAt.toLocal().toString().split(' ')[0]),
          _infoRow('Nomor Resi', order.trackingNumber ?? '-'),

          const SizedBox(height: 24),
          _sectionTitle('Daftar Produk'),

          ...order.items.map((item) => _OrderItemTile(item: item)),

          const SizedBox(height: 24),
          _sectionTitle('Ringkasan Harga'),

          _infoRow('Total', 'Rp ${order.total.toStringAsFixed(0)}', bold: true),

          const SizedBox(height: 32),
          if (canCancel)
            ElevatedButton(
              onPressed: () async {
                final confirmed = await _confirmCancel(context);
                if (!confirmed) return;

                await ref.read(ordersProvider.notifier).cancelOrder(order.id);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pesanan berhasil dibatalkan')),
                  );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Batalkan Pesanan'),
            ),
        ],
      ),
    );
  }

  Future<bool> _confirmCancel(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Batalkan Pesanan?'),
              content: const Text('Apakah Anda yakin ingin membatalkan pesanan ini?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Tidak')),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Ya')),
              ],
            );
          },
        ) ??
        false;
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _mapStatus(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'processing':
        return 'Diproses';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }
}

//
// ITEM TILE
//
class _OrderItemTile extends StatelessWidget {
  final OrderItem item;

  const _OrderItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: item.imageUrl != null
            ? Image.network(item.imageUrl!, width: 48, height: 48, fit: BoxFit.cover)
            : const Icon(Icons.image_not_supported, size: 40),
        title: Text(item.productName),
        subtitle: Text('Qty: ${item.quantity}'),
        trailing: Text(
          'Rp ${(item.price * item.quantity).toStringAsFixed(0)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
