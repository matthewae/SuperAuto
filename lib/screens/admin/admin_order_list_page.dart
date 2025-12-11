import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/dao/order_dao.dart';
import '../../models/order.dart';
import '../../providers/app_providers.dart';
import 'admin_order_detail_page.dart';
import 'package:go_router/go_router.dart';

class AdminOrderListPage extends ConsumerWidget {
  const AdminOrderListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(allOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin - Order Management"),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allOrdersProvider);
        },
        child: ordersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  "Error loading orders",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          data: (orders) {
            // Debug log all orders and their statuses
            debugPrint('All orders statuses: ${orders.map((o) => o.status).toList()}');

            final filteredOrders = orders.where((order) {
              final shouldInclude = order.status != 'delivered' && order.status != 'cancelled';
              debugPrint('Order ${order.id} - status: ${order.status} - include: $shouldInclude');
              return shouldInclude;
            }).toList();

            debugPrint('Filtered orders count: ${filteredOrders.length}');
            debugPrint('Filtered orders statuses: ${filteredOrders.map((o) => o.status).toList()}');

            if (filteredOrders.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      "Tidak ada order yang sedang diproses.",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filteredOrders.length,
              itemBuilder: (context, i) {
                final order = filteredOrders[i];

                // Format tanggal
                final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
                final createdDate = order.createdAt != null
                    ? dateFormat.format(order.createdAt!)
                    : 'Unknown date';

                // Tentukan warna dan ikon status
                Color statusColor;
                IconData statusIcon;
                switch (order.status) {
                  case 'pending':
                    statusColor = Colors.orange;
                    statusIcon = Icons.pending;
                    break;
                  case 'processing':
                    statusColor = Colors.blue;
                    statusIcon = Icons.hourglass_empty;
                    break;
                  case 'shipped':
                    statusColor = Colors.purple;
                    statusIcon = Icons.local_shipping;
                    break;
                  case 'delivered':
                    statusColor = Colors.green;
                    statusIcon = Icons.check_circle;
                    break;
                  case 'cancelled':
                    statusColor = Colors.red;
                    statusIcon = Icons.cancel;
                    break;
                  default:
                    statusColor = Colors.grey;
                    statusIcon = Icons.help;
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      context.go('/admin/detail/${order.id}');
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Order ID dan Status
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  "Order #${order.id.substring(0, 8)}...",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(statusIcon, size: 16, color: statusColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      order.status,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Customer Info (PERUBAHAN DI SINI)
                          Row(
                            children: [
                              Icon(Icons.person, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  // Hanya tampilkan userName, dengan teks default jika null
                                  order.userName ?? 'Customer Name Not Set',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Date Info
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Text(
                                createdDate,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Footer: Total dan Arrow
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Rp ${order.total.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.black87,
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}