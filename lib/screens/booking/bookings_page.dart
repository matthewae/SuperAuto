import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import 'booking_detail_page.dart';
import '../../models/service_booking.dart';

class BookingsPage extends ConsumerWidget {
  const BookingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ Gunakan userBookingsProviderAlt yang sudah di-filter per user
    final bookingsState = ref.watch(userBookingsProviderAlt);
    final currentUser = ref.watch(authProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Booking'),
      ),
      body: bookingsState.when(
        data: (bookings) {
          print('📋 BookingsPage: Showing ${bookings.length} bookings for user ${currentUser?.id}');
          return _buildBookingsList(context, bookings, ref);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          print('❌ BookingsPage Error: $error');
          return Center(child: Text('Error: $error'));
        },
      ),
    );
  }

  Widget _buildBookingsList(
      BuildContext context, List<ServiceBooking> bookings, WidgetRef ref) {
    if (bookings.isEmpty) {
      return const Center(
        child: Text('Belum ada riwayat booking'),
      );
    }

    return ListView.builder(
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(
              '${_formatServiceType(booking.serviceType)} - ${_formatDate(booking.scheduledAt)}',
            ),
            subtitle: Text(_getStatusText(booking.status)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      BookingDetailPage(bookingId: booking.id),
                ),
              );
            },
          ),
        );
      },
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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