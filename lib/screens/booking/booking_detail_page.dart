import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/service_booking.dart';
import '../../models/car.dart';
import '../../providers/app_providers.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../models/promo.dart';

class BookingDetailPage extends ConsumerWidget {
  final String bookingId;

  const BookingDetailPage({Key? key, required this.bookingId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    initializeDateFormatting('id_ID', null);

    final isAdmin = ref.watch(authProvider).valueOrNull?.isAdmin ?? false;

    // For admin, we'll use the StateNotifier directly
    if (isAdmin) {
      final bookings = ref.watch(bookingsProvider);
      print('📋 BookingDetailPage (Admin): Loaded ${bookings.length} total bookings');
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Detail Booking'),
          centerTitle: true,
        ),
        body: _buildBookingList(bookings, context, ref),
      );
    }
    // For regular users, use the FutureProvider
    else {
      final bookingsAsync = ref.watch(userBookingsProviderAlt);
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Detail Booking'),
          centerTitle: true,
        ),
        body: bookingsAsync.when(
          data: (bookings) {
            print('📋 BookingDetailPage: Loaded ${bookings.length} bookings for current user');
            return _buildBookingList(bookings, context, ref);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) {
            print('❌ BookingDetailPage Error: $error');
            return Center(child: Text('Error: $error'));
          },
        ),
      );
    }
  }

  Widget _buildBookingList(List<ServiceBooking> bookings, BuildContext context, WidgetRef ref) {
    try {
      final booking = bookings.firstWhere((b) => b.id == bookingId);
      print('✅ Found booking: ${booking.id} - Status: ${booking.status}');
      print('📜 Status History: ${booking.statusHistory}');
      return _buildBookingDetails(booking, context, ref);
    } catch (e) {
      print('❌ Booking not found: $bookingId');
      print('   Available bookings: ${bookings.map((b) => b.id).join(", ")}');
      return const Center(child: Text('Booking tidak ditemukan'));
    }
  }

  Widget _buildBookingDetails(ServiceBooking booking, BuildContext context, WidgetRef ref) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadBookingDetails(booking, ref),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final details = snapshot.data!;
        final car = details['car'] as Car?;
        final promo = details['promo'] as Promo?;
        final finalCost = details['finalCost'] as double? ?? booking.totalCost ?? booking.estimatedCost ?? 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusTimeline(booking, context),
              const SizedBox(height: 16),
              _buildSectionTitle(context, 'Detail Servis'),
              _buildDetailCard(
                icon: Icons.calendar_today,
                title: 'Tanggal & Waktu',
                value: DateFormat('EEEE, d MMMM yyyy, HH:mm', 'id_ID')
                    .format(booking.scheduledAt),
              ),
              _buildDetailCard(
                icon: Icons.directions_car,
                title: 'Mobil',
                value: car != null
                    ? '${car.brand} ${car.model} (${car.plateNumber})'
                    : 'Mobil tidak ditemukan',
              ),
              _buildDetailCard(
                icon: Icons.build,
                title: 'Jenis Servis',
                value: _formatServiceType(booking.serviceType),
              ),
              if (booking.serviceDetails?.isNotEmpty ?? false)
                _buildDetailCard(
                  icon: Icons.description,
                  title: 'Detail Servis',
                  value: booking.serviceDetails!,
                ),
              if (booking.mechanicName?.isNotEmpty ?? false)
                _buildDetailCard(
                  icon: Icons.person,
                  title: 'Mekanik',
                  value: booking.mechanicName!,
                ),
              _buildDetailCard(
                icon: Icons.attach_money,
                title: 'Biaya Estimasi',
                value: 'Rp${booking.estimatedCost?.toStringAsFixed(0) ?? '0'}',
              ),
              if (booking.totalCost != null) ...[
                _buildDetailCard(
                  icon: Icons.attach_money,
                  title: 'Total Biaya',
                  value: 'Rp${booking.totalCost!.toStringAsFixed(0)}',
                ),
                if (promo != null) ...[
                  _buildDetailCard(
                    icon: Icons.local_offer,
                    title: 'Promo',
                    value: '${promo.name} (${promo.formattedValue})',
                  ),
                  _buildDetailCard(
                    icon: Icons.money_off,
                    title: 'Diskon',
                    value: '-Rp${promo.calculateDiscount(booking.totalCost!).toStringAsFixed(0)}',
                  ),
                  _buildDetailCard(
                    icon: Icons.attach_money,
                    title: 'Total Setelah Diskon',
                    value: 'Rp${finalCost.toStringAsFixed(0)}',
                  ),
                ],
              ],
              if (booking.isPickupService)
                _buildDetailCard(
                  icon: Icons.location_on,
                  title: 'Lokasi Penjemputan',
                  value: booking.serviceLocation ?? 'Lokasi belum ditentukan',
                ),
              if (booking.notes?.isNotEmpty ?? false)
                _buildDetailCard(
                  icon: Icons.note,
                  title: 'Catatan Tambahan',
                  value: booking.notes!,
                ),
              if (booking.adminNotes?.isNotEmpty ?? false)
                _buildDetailCard(
                  icon: Icons.admin_panel_settings,
                  title: 'Catatan Admin',
                  value: booking.adminNotes!,
                ),
              const SizedBox(height: 24),
              _buildActionButtons(booking, context, ref),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusTimeline(ServiceBooking booking,context) {
    // Parse status history dari booking
    final Map<String, DateTime> statusTimestamps = {};

    if (booking.statusHistory != null && booking.statusHistory!.isNotEmpty) {
      booking.statusHistory!.forEach((key, value) {
        try {
          DateTime timestamp;
          if (value is String) {
            timestamp = DateTime.parse(value);
          } else if (value is Map) {
            // Jika value adalah Map dengan format {status, notes, updatedAt}
            final updatedAt = value['updatedAt'];
            if (updatedAt != null) {
              timestamp = DateTime.parse(updatedAt.toString());
            } else {
              timestamp = DateTime.now();
            }
            // Override key dengan status dari value jika ada
            final status = value['status'];
            if (status != null) {
              statusTimestamps[status.toString()] = timestamp;
              return;
            }
          } else {
            timestamp = DateTime.now();
          }
          statusTimestamps[key] = timestamp;
        } catch (e) {
          debugPrint('Error parsing timestamp for $key: $e');
        }
      });
    }

    // Jika tidak ada history, gunakan createdAt untuk status awal
    if (statusTimestamps.isEmpty) {
      statusTimestamps['pending'] = booking.createdAt;
    }

    // Tambahkan current status jika belum ada
    if (!statusTimestamps.containsKey(booking.status)) {
      statusTimestamps[booking.status] = booking.updatedAt ?? DateTime.now();
    }

    // Sort berdasarkan waktu
    final sortedEntries = statusTimestamps.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    print('🔍 Timeline Data:');
    for (var entry in sortedEntries) {
      print('   ${entry.key}: ${entry.value}');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(width: 8),
              const Text(
                'Timeline',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...sortedEntries.asMap().entries.map((entry) {
            final index = entry.key;
            final statusEntry = entry.value;
            final isLast = index == sortedEntries.length - 1;
            final isCurrent = statusEntry.key == booking.status;

            return _buildTimelineItem(
              status: statusEntry.key,
              timestamp: statusEntry.value,
              isLast: isLast,
              isCurrent: isCurrent,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String status,
    required DateTime timestamp,
    required bool isLast,
    required bool isCurrent,
  }) {
    Color getStatusColor() {
      if (status == 'cancelled') return Colors.red;
      if (status == 'completed') return Colors.green;
      if (isCurrent) return Colors.blue;
      return Colors.grey;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          SizedBox(
            width: 40,
            child: Column(
              children: [
                // Dot
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: getStatusColor(),
                    border: Border.all(
                      color: getStatusColor(),
                      width: 3,
                    ),
                  ),
                  child: isCurrent
                      ? Container(
                    margin: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  )
                      : null,
                ),
                // Connecting line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: getStatusColor().withOpacity(0.3),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getStatusText(status),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                      color: isCurrent ? Colors.black : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, d MMM yyyy • HH:mm', 'id_ID').format(timestamp),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (_getStatusDescription(status).isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _getStatusDescription(status),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusDescription(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu konfirmasi dari bengkel';
      case 'confirmed':
        return 'Pesanan telah dikonfirmasi';
      case 'in_progress':
        return 'Servis sedang dalam pengerjaan';
      case 'waiting_parts':
        return 'Menunggu suku cadang';
      case 'waiting_payment':
        return 'Menunggu pembayaran';
      case 'ready_for_pickup':
        return 'Servis selesai, siap diambil';
      case 'completed':
        return 'Pesanan selesai';
      case 'cancelled':
        return 'Pesanan dibatalkan';
      default:
        return '';
    }
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
      ServiceBooking booking, BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        if (booking.status == 'pending')
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.cancel),
              label: const Text('Batalkan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[50],
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => _showCancelConfirmation(context, booking, ref),
            ),
          ),
        if (booking.status == 'ready_for_pickup')
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_circle),
              label: const Text('Konfirmasi Selesai'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => _showCompleteDialog(context, booking, ref),
            ),
          ),
      ],
    );
  }

  void _showCancelConfirmation(
      BuildContext context, ServiceBooking booking, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Booking'),
        content: const Text('Apakah Anda yakin ingin membatalkan booking ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(bookingsProvider.notifier)
                    .updateStatus(booking.id, 'cancelled');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Booking telah dibatalkan')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gagal membatalkan booking')),
                  );
                }
              }
            },
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCompleteDialog(
      BuildContext context, ServiceBooking booking, WidgetRef ref) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Selesai'),
        content: const Text('Apakah Anda sudah mengambil mobil Anda?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Belum'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(bookingsProvider.notifier)
                    .updateStatus(booking.id, 'completed');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Terima kasih telah menggunakan layanan kami!'),
                    ),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gagal memperbarui status')),
                  );
                }
              }
            },
            child: const Text('Sudah'),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _loadBookingDetails(
      ServiceBooking booking, WidgetRef ref) async {
    try {
      final cars = ref.read(carsProvider);
      debugPrint('Booking carId: ${booking.carId}');
      debugPrint('Available cars: ${cars.map((c) => c.id).join(', ')}');
      final car = cars.firstWhere(
            (car) => car.id == booking.carId,
        orElse: () => Car(
          id: '',
          brand: 'Mobil tidak ditemukan',
          model: '',
          year: 0,
          plateNumber: '',
          vin: 'N/A',
          engineNumber: 'N/A',
          initialKm: 0,
          userId: '',
          isMain: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Load promo if promoId is not null
      Promo? promo;
      double? finalCost;
      if (booking.promoId != null) {
        promo = await ref.read(promoDaoProvider).getById(booking.promoId!);
        finalCost = await ref.read(bookingsProvider.notifier).calculateFinalCost(booking.id);
      }

      return {'car': car, 'promo': promo, 'finalCost': finalCost};
    } catch (e) {
      debugPrint('Error loading booking details: $e');
      return {
        'car': Car(
          id: '',
          brand: 'Gagal memuat data mobil',
          model: '',
          year: 0,
          plateNumber: '',
          vin: 'N/A',
          engineNumber: 'N/A',
          initialKm: 0,
          userId: '',
          isMain: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        'promo': null,
        'finalCost': null
      };
    }
  }

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
      case 'waiting_payment':
        return 'Menunggu Pembayaran';
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
}