import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/service_booking.dart';
import '../../providers/app_providers.dart';

class AdminBookingPage extends ConsumerWidget {
  const AdminBookingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(bookingsProvider);
    final notifier = ref.read(bookingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Booking'),
        centerTitle: true,
      ),
      body: bookings.isEmpty
          ? const Center(child: Text('Tidak ada data booking'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          final formattedDate = DateFormat('dd MMM yyyy HH:mm').format(booking.scheduledAt);

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
                      Text(
                        'Booking #${booking.id.substring(0, 8)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
                          booking.status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow('Layanan', booking.serviceType),
                  _buildInfoRow('Bengkel', booking.workshop!),
                  _buildInfoRow('Tanggal', formattedDate),
                  if (booking.notes?.isNotEmpty ?? false)
                    _buildInfoRow('Catatan', booking.notes!),
                  const SizedBox(height: 12),
                  if (booking.status == 'pending')
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GFButton(
                          onPressed: () => _updateStatus(notifier, booking.id, 'dikonfirmasi'),
                          text: 'Konfirmasi',
                          color: GFColors.SUCCESS,
                          size: GFSize.SMALL,
                        ),
                        const SizedBox(width: 8),
                        GFButton(
                          onPressed: () => _updateStatus(notifier, booking.id, 'dibatalkan'),
                          text: 'Tolak',
                          color: GFColors.DANGER,
                          size: GFSize.SMALL,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          const Text(': '),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'dikonfirmasi':
        return Colors.green;
      case 'dibatalkan':
        return Colors.red;
      case 'selesai':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  void _updateStatus(BookingsNotifier notifier, String id, String status) {
    notifier.updateStatus(id, status);
    // TODO: Tambahkan logika update status ke database
  }
}