import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/app_providers.dart';
import '../../models/order.dart';
import '../../models/service_booking.dart';
import '../../models/user.dart';
import '../../models/car.dart';
import '../booking/booking_detail_page.dart';
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              context.go('/admin');
            },
          ),
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


  Future<Map<String, dynamic>> _getUserAndCarDetails(
      WidgetRef ref,
      BuildContext context,
      String? userId,
      String? carId,
      ) async {
    try {
      if (userId == null || carId == null) {
        return {
          'userName': 'Data tidak lengkap',
          'userPhone': '-',
          'carInfo': 'Data kendaraan tidak tersedia',
        };
      }

      final user = await ref.read(userDaoProvider).getUserById(userId);
      final car = await ref.read(carDaoProvider).getById(carId);

      return {
        'userName': user?.name ?? 'Pelanggan',
        'userPhone': user?.email ?? '-',
        'carInfo': car != null
            ? '${car.brand} ${car.model} (${car.plateNumber})'
            : 'Mobil tidak ditemukan',
      };
    } catch (e) {
      debugPrint('❌ Error in _getUserAndCarDetails: $e');
      return {
        'userName': 'Error memuat data',
        'userPhone': '-',
        'carInfo': 'Error memuat data mobil',
      };
    }
  }

  Widget _buildServiceTab(List<ServiceBooking> bookings) {
    return Column(
      children: [
        _buildServiceFilterChips(),
        const SizedBox(height: 8),
        Expanded(
          child: bookings.isEmpty
              ? const Center(child: Text("Belum ada servis selesai/batal"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    final formattedDate = DateFormat('dd MMM yyyy HH:mm').format(booking.scheduledAt);

                    return FutureBuilder<Map<String, dynamic>>(
                      future: _getUserAndCarDetails(
                        ref,
                        context,
                        booking.userId,
                        booking.carId,
                      ),
                      builder: (context, snapshot) {
                        final details = snapshot.data ?? {
                          'userName': 'Loading...',
                          'userPhone': '-',
                          'carInfo': 'Mengambil data...',
                        };

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Booking #${booking.id.substring(0, 8)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            details['userName']!,
                                            style: const TextStyle(fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(booking.status),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _getStatusDisplayName(booking.status),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow('Nama', details['userName']!),
                                _buildInfoRow('E-Mail', details['userPhone']!),
                                _buildInfoRow('Mobil', details['carInfo']!),
                                const Divider(height: 20),
                                _buildInfoRow('Layanan', _formatServiceType(booking.serviceType)),
                                _buildInfoRow('Tanggal', formattedDate),
                                _buildInfoRow(
                                  'Biaya',
                                  'Rp${(booking.totalCost ?? booking.estimatedCost ?? 0).toStringAsFixed(0)}',
                                ),
                                if (booking.notes?.isNotEmpty ?? false) ...[
                                  const SizedBox(height: 4),
                                  _buildInfoRow('Catatan', booking.notes!, isMultiline: true),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => BookingDetailPage(bookingId: booking.id),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context).primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      ),
                                      child: const Text('Lihat Detail'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isMultiline = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          const Text(':  ', style: TextStyle(fontSize: 14)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
              maxLines: isMultiline ? 3 : 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'in_progress':
        return Colors.blue;
      case 'confirmed':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      case 'in_progress':
        return 'Dalam Proses';
      case 'confirmed':
        return 'Dikonfirmasi';
      default:
        return status;
    }
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