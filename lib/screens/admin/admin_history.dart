import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';
import '../../models/order.dart';
import '../../models/service_booking.dart';
import 'package:flutter/foundation.dart'; // for debugPrint

class AdminHistoryPage extends ConsumerStatefulWidget {
  const AdminHistoryPage({super.key});

  @override
  ConsumerState<AdminHistoryPage> createState() => _AdminHistoryPageState();
}

class _AdminHistoryPageState extends ConsumerState<AdminHistoryPage> {
  bool showDeliveredOrders = true;
  bool showCancelledOrders = true;
  bool showCompletedServices = true;
  bool showCancelledServices = true;

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(allOrdersProvider);
    final bookings = ref.watch(bookingsProvider);
    
    // Filter services based on status
    final serviceHistory = bookings.where((b) {
      if (showCompletedServices && b.status == "completed") return true;
      if (showCancelledServices && b.status == "cancelled") return true;
      return false;
    }).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Riwayat Transaksi Admin"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Produk"),
              Tab(text: "Servis"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ordersAsync.when(
              data: (orders) {
                debugPrint('Total orders: ${orders.length}');
                if (orders.isNotEmpty) {
                  debugPrint('Order statuses: ${orders.map((o) => o.status).toSet().toList()}');
                }
                return _buildOrderTab(orders);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text('Error loading orders: $error'),
              ),
            ),
            _buildServiceTab(serviceHistory),
          ],
        ),
      ),
    );
  }

  // ===========================================================
  // =============== TAB PRODUK (ORDERS) =======================
  // ===========================================================
  Widget _buildOrderTab(List<Order> orders) {
    return Column(
      children: [
        _buildOrderFilterChips(),
        const SizedBox(height: 8),
        Expanded(
          child: orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Belum ada pesanan"),
                      if (orders.isEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Total pesanan: 0',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        Text(
                          'Total pesanan: ${orders.length} • Status yang tersedia: ${orders.map((o) => o.status).toSet().join(', ')}',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                )
              : ListView(
            children: _applyOrderFilter(orders).map((order) {
              return Card(
                margin: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text("Pesanan #${order.id.substring(0, 8)}"),
                  subtitle: Text(
                    "${order.items.length} item • Rp ${order.total.toStringAsFixed(0)} • ${_statusLabel(order.status)}",
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    if (order.id != null) {
                      context.go('/admin/detail/${order.id}');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tidak dapat membuka detail order')),
                      );
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilterChip(
            label: const Text('Terkirim'),
            selected: showDeliveredOrders,
            onSelected: (bool selected) {
              setState(() {
                showDeliveredOrders = selected;
              });
            },
          ),
          FilterChip(
            label: const Text('Dibatalkan'),
            selected: showCancelledOrders,
            onSelected: (bool selected) {
              setState(() {
                showCancelledOrders = selected;
              });
            },
          ),
        ],
      ),
    );
  }

  List<Order> _applyOrderFilter(List<Order> orders) {
    return orders.where((o) {
      if (showDeliveredOrders && o.status == "delivered") return true;
      if (showCancelledOrders && o.status == "cancelled") return true;
      return false;
    }).toList();
  }

  // ===========================================================
  // =============== TAB SERVIS (BOOKINGS) ======================
  // ===========================================================
  Widget _buildServiceTab(List<ServiceBooking> bookings) {
    return Column(
      children: [
        _buildServiceFilterChips(),
        const SizedBox(height: 8),
        Expanded(
          child: bookings.isEmpty
              ? const Center(child: Text("Belum ada servis selesai/batal"))
              : ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final b = bookings[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                      "${_formatServiceType(b.serviceType)} • ${_getStatusText(b.status)}"),
                  subtitle: Text(
                    "Total: Rp ${(b.totalCost ?? b.estimatedCost).toStringAsFixed(0)}\n"
                        "${_formatDate(b.scheduledAt)}",
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.go('/service-detail/${b.id}');
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildServiceFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilterChip(
            label: const Text('Selesai'),
            selected: showCompletedServices,
            onSelected: (bool selected) {
              setState(() {
                showCompletedServices = selected;
              });
            },
          ),
          FilterChip(
            label: const Text('Dibatalkan'),
            selected: showCancelledServices,
            onSelected: (bool selected) {
              setState(() {
                showCancelledServices = selected;
              });
            },
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _formatServiceType(String type) {
    switch (type) {
      case 'regular':
        return 'Servis Berkala';
      case 'repair':
        return 'Perbaikan';
      case 'emergency':
        return 'Darurat';
      default:
        return type;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu Konfirmasi';
      case 'confirmed':
        return 'Dikonfirmasi';
      case 'in_progress':
        return 'Sedang Dikerjakan';
      case 'waiting_parts':
        return 'Menunggu Part';
      case 'ready_for_pickup':
        return 'Siap Diambil';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _statusLabel(String status) {
    switch (status) {
      case "pending":
        return "Menunggu Konfirmasi";
      case "processing":
        return "Diproses";
      case "shipped":
        return "Dikirim";
      case "delivered":
        return "Terkirim";
      case "cancelled":
        return "Dibatalkan";
      default:
        return status;
    }
  }
}