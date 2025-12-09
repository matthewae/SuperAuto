import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/service_booking.dart';
import '../../models/car.dart';
import '../../providers/app_providers.dart';
import 'package:intl/date_symbol_data_local.dart';

class BookingDetailPage extends ConsumerWidget {
  final String bookingId;

  const BookingDetailPage({Key? key, required this.bookingId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    initializeDateFormatting('id_ID', null);

    final bookingsState = ref.watch(userBookingsProviderAlt);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Booking'),
        centerTitle: true,
      ),
      body: bookingsState.when(
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

  Widget _buildBookingList(List<ServiceBooking> bookings, BuildContext context, WidgetRef ref) {
    try {
      final booking = bookings.firstWhere((b) => b.id == bookingId);
      print('✅ Found booking: ${booking.id} - Status: ${booking.status}');
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

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusCard(booking, context),
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
                title: 'Perkiraan Biaya',
                value: 'Rp${booking.estimatedCost.toStringAsFixed(0)}',
              ),
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
                  isAdminNote: true,
                ),
              _buildTimeline(booking, context),
              const SizedBox(height: 20),
              if (_shouldShowActionButtons(booking))
                _buildActionButtons(booking, context, ref),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadBookingDetails(
      ServiceBooking booking, WidgetRef ref) async {
    final car = await ref.read(carDaoProvider).getById(booking.carId);
    return {'car': car};
  }

  Widget _buildStatusCard(ServiceBooking booking, BuildContext context) {
    Color statusColor;
    switch (booking.status) {
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      case 'in_progress':
        statusColor = Colors.orange;
        break;
      case 'confirmed':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  _getStatusIcon(booking.status),
                  color: statusColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getStatusText(booking.status),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (booking.updatedAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Terakhir diperbarui: ${DateFormat('d MMM yyyy, HH:mm').format(booking.updatedAt!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            if (booking.status == 'in_progress')
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String value,
    bool isAdminNote = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: isAdminNote ? Colors.red : null),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isAdminNote ? Colors.red : null,
          ),
        ),
        subtitle: Text(value, style: isAdminNote ? const TextStyle(color: Colors.red) : null),
      ),
    );
  }

  Widget _buildTimeline(ServiceBooking booking, BuildContext context) {
    final statusHistory = booking.statusHistory ?? {};
    if (statusHistory.isEmpty) return const SizedBox.shrink();

    final entries = statusHistory.entries.map((entry) {
      return MapEntry(
        entry.key,
        entry.value is String ? DateTime.parse(entry.value) : DateTime.now(),
      );
    }).toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // Sort by date, newest first
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Riwayat Status'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                for (var i = 0; i < entries.length; i++)
                  _buildTimelineStep(
                    context: context,
                    status: entries[i].key,
                    time: entries[i].value,
                    isFirst: i == 0,
                    isLast: i == entries.length - 1,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineStep({
    required BuildContext context,
    required String status,
    required DateTime time,
    bool isFirst = false,
    bool isLast = false,
  }) {
    String formattedDate;
    try {
      formattedDate = DateFormat('EEEE, d MMMM yyyy, HH:mm', 'id_ID').format(time);
    } catch (e) {
      formattedDate = 'Waktu tidak valid';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            if (!isFirst)
              Container(
                width: 2,
                height: 20,
                color: Colors.grey[300],
              ),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isLast ? Theme.of(context).primaryColor : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 20,
                color: Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusText(status),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  formattedDate,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
      ServiceBooking booking,
      BuildContext context,
      WidgetRef ref
      ) {
    if (booking.status == 'cancelled' || booking.status == 'completed') {
      return const SizedBox.shrink();
    }
    return Row(
      children: [
        if (booking.status == 'pending')
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.cancel),
              label: const Text('Batalkan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _showCancelConfirmation(context, booking, ref),
            ),
          ),
        if (booking.status == 'pending') const SizedBox(width: 8),
        if (booking.status == 'ready_for_pickup')
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_circle),
              label: const Text('Konfirmasi Selesai'),
              onPressed: () => _confirmCompletion(context, booking, ref),
            ),
          ),
      ],
    );
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending_actions;
      case 'confirmed':
        return Icons.assignment_turned_in;
      case 'in_progress':
        return Icons.build;
      case 'waiting_parts':
        return Icons.inventory_2;
      case 'waiting_payment':
        return Icons.payment;
      case 'ready_for_pickup':
        return Icons.local_car_wash;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
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

  bool _shouldShowActionButtons(ServiceBooking booking) {
    return booking.status == 'pending' || booking.status == 'ready_for_pickup';
  }

  void _showCancelConfirmation(
      BuildContext context, ServiceBooking booking, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Booking?'),
        content: const Text('Apakah Anda yakin ingin membatalkan booking ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(bookingsProvider.notifier)
                  .updateStatus(booking.id, 'cancelled');
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Booking telah dibatalkan')),
              );
            },
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }

  void _confirmCompletion(
      BuildContext context, ServiceBooking booking, WidgetRef ref) {
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
            onPressed: () {
              ref
                  .read(bookingsProvider.notifier)
                  .updateStatus(booking.id, 'completed');
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Terima kasih telah menggunakan layanan kami!')),
              );
            },
            child: const Text('Sudah'),
          ),
        ],
      ),
    );
  }
}