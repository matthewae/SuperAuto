import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/order.dart';
import '../../providers/app_providers.dart';
import 'package:collection/collection.dart';

class OrderDetailPage extends ConsumerWidget {
  final String orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);
    final isLoading = ref.watch(ordersProvider.notifier).isLoading;

    final order = orders.firstWhereOrNull((o) => o.id == orderId);

    if (isLoading && order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Pesanan')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Pesanan')),
        body: const Center(child: Text('Pesanan tidak ditemukan.')),
      );
    }

    return _buildOrderDetails(context, ref, order);
  }

  Widget _buildOrderDetails(BuildContext context, WidgetRef ref, Order order) {
    final canCancel = order.status == 'pending' || order.status == 'processing';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pesanan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/order-history');
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Informasi Pesanan'),

          _infoRow('ID Pesanan', '#${order.id.substring(0, 8)}...'),
          _infoRow('Status', _mapStatus(order.status)),
          _infoRow('Tanggal', _formatDate(order.createdAt)),
          if (order.status == 'shipped' || order.status == 'delivered')
            _infoRow('Nomor Resi', order.trackingNumber ?? 'Belum ada'),

          const SizedBox(height: 24),
          _sectionTitle('Daftar Produk'),

          if (order.items.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Tidak ada item dalam pesanan ini'),
              ),
            )
          else
            ...order.items.map((item) => _OrderItemTile(item: item)),

          const SizedBox(height: 24),
          _sectionTitle('Ringkasan Harga'),

          Builder(
            builder: (context) {
              final subtotal = order.items.fold<double>(
                0.0,
                (sum, item) => sum + (item.price * item.quantity),
              );
              final discountAmount = subtotal - order.total;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _infoRow('Subtotal', 'Rp ${subtotal.toStringAsFixed(0)}'),
                  if (discountAmount > 0)
                    _infoRow(
                      'Diskon',
                      '-Rp ${discountAmount.toStringAsFixed(0)}',
                      isDiscount: true,
                    ),
                  _infoRow(
                    'Total',
                    'Rp ${order.total.toStringAsFixed(0)}',
                    bold: true,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),
          _sectionTitle('Informasi Pengiriman & Pembayaran'),
          if (order.shippingAddress != null &&
              order.shippingAddress!.isNotEmpty)
            _infoRow('Alamat Pengiriman', order.shippingAddress!),
          if (order.paymentMethod != null && order.paymentMethod!.isNotEmpty)
            _infoRow(
              'Metode Pembayaran',
              _mapPaymentMethod(order.paymentMethod!),
            ),

          const SizedBox(height: 32),
          if (canCancel)
            ElevatedButton(
              onPressed: () async {
                final confirmed = await _confirmCancel(context);
                if (!confirmed) return;

                try {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 16),
                            Text('Membatalkan pesanan...'),
                          ],
                        ),
                      ),
                    );
                  }

                  await ref.read(ordersProvider.notifier).cancelOrder(order.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pesanan berhasil dibatalkan'),
                      ),
                    );
                    context.go('/order-history');
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal membatalkan pesanan: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
              content: const Text(
                'Apakah Anda yakin ingin membatalkan pesanan ini?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Tidak'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Ya'),
                ),
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

  Widget _infoRow(
    String label,
    String value, {
    bool bold = false,
    bool isDiscount = false,
  }) {
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
              color: isDiscount ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown date';
    try {
      return '${date.day}-${date.month}-${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  String _mapStatus(String? status) {
    if (status == null) return 'Unknown';
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'processing':
        return 'Diproses';
      case 'shipped':
        return 'Dikirim';
      case 'delivered':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  String _mapPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'transfer_bank':
        return 'Transfer Bank';
      case 'credit_card':
        return 'Kartu Kredit';
      case 'ewallet':
        return 'E-Wallet';
      case 'cod':
        return 'Cash on Delivery (COD)';
      default:
        return method
            .split(' ')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
    }
  }
}

class _OrderItemTile extends StatelessWidget {
  final OrderItem item;

  const _OrderItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: item.imageUrl != null && item.imageUrl!.isNotEmpty
            ? Image.network(
                item.imageUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 48,
                    height: 48,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported, size: 24),
                  );
                },
              )
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
