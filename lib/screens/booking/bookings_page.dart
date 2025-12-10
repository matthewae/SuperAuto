import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import 'booking_detail_page.dart';
import '../../models/service_booking.dart';
import '../../models/enums.dart' show BookingFilter;

class BookingsPage extends ConsumerStatefulWidget {
  const BookingsPage({super.key});

  @override
  ConsumerState<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends ConsumerState<BookingsPage> {
  BookingFilter currentFilter = BookingFilter.active;

  @override
  Widget build(BuildContext context) {
    final bookingsState = ref.watch(userBookingsProviderAlt);

    return Scaffold(
      appBar: AppBar(title: const Text("Daftar Booking")),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: bookingsState.when(
              data: (bookings) {
                final filtered = _applyFilter(bookings);
                if (filtered.isEmpty) {
                  return const Center(child: Text("Tidak ada data"));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final booking = filtered[index];
                    final isActive = booking.status != "completed" &&
                        booking.status != "cancelled";

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(
                          '${_formatServiceType(booking.serviceType)} - ${_formatDate(booking.scheduledAt)}',
                        ),
                        subtitle: Text(_getStatusText(booking.status)),
                        trailing:
                        isActive ? const Icon(Icons.chevron_right) : null,
                        onTap: isActive
                            ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookingDetailPage(
                                bookingId: booking.id),
                          ),
                        )
                            : null, // non aktif untuk selesai/batal
                      ),
                    );
                  },
                );
              },
              loading: () =>
              const Center(child: CircularProgressIndicator()),
              error: (err, _) =>
                  Center(child: Text("Error: $err")),
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------
  // FILTER UI
  // -----------------------------------------
  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _chip("Aktif", BookingFilter.active),
          const SizedBox(width: 8),
          _chip("Selesai", BookingFilter.completed),
          const SizedBox(width: 8),
          _chip("Dibatalkan", BookingFilter.cancelled),
        ],
      ),
    );
  }

  Widget _chip(String label, BookingFilter filter) {
    final selected = currentFilter == filter;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() => currentFilter = filter);
      },
    );
  }

  // -----------------------------------------
  // FILTER LOGIC
  // -----------------------------------------
  List<ServiceBooking> _applyFilter(List<ServiceBooking> bookings) {
    switch (currentFilter) {
      case BookingFilter.active:
        return bookings.where((b) =>
        b.status != "completed" &&
            b.status != "cancelled"
        ).toList();

      case BookingFilter.completed:
        return bookings.where((b) => b.status == "completed").toList();

      case BookingFilter.cancelled:
        return bookings.where((b) => b.status == "cancelled").toList();

      default:
        return bookings;
    }
  }

  // -----------------------------------------
  // UTIL FUNCTIONS
  // -----------------------------------------

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
    return '${date.day}/${date.month}/${date.year} '
        '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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
