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
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final booking = filtered[index];
                    final isActive = booking.status != "completed" &&
                        booking.status != "cancelled";

                    if (isActive) {
                      return _buildActiveTile(context, booking);
                    } else {
                      return _buildHistoryCard(booking);
                    }
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
      onSelected: (_) => setState(() => currentFilter = filter),
    );
  }


  Widget _buildActiveTile(BuildContext context, ServiceBooking booking) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(
          '${_formatServiceType(booking.serviceType)} • ${_formatDate(booking.scheduledAt)}',
        ),
        subtitle: Text(_getStatusText(booking.status)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingDetailPage(bookingId: booking.id),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(ServiceBooking booking) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // STATUS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getStatusText(booking.status),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: booking.status == "completed"
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                Text(
                  _formatDate(booking.scheduledAt),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              _formatServiceType(booking.serviceType),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 12),

            // MECHANIC NAME
            if (booking.mechanicName != null)
              _infoRow(Icons.engineering, "Mekanik", booking.mechanicName!),

            if (booking.serviceLocation != null &&
                booking.isPickupService)
              _infoRow(Icons.local_shipping, "Lokasi Pickup",
                  booking.serviceLocation!),

            if (booking.workshop != null)
              _infoRow(Icons.store, "Bengkel", booking.workshop!),

            if (booking.km != null)
              _infoRow(Icons.speed, "Kilometer", "${booking.km} km"),

            const SizedBox(height: 12),

            if (booking.jobs.isNotEmpty) ...[
              const Text("Pekerjaan:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              ...booking.jobs.map((j) => Text("• $j")),
              const SizedBox(height: 12),
            ],

            if (booking.parts.isNotEmpty) ...[
              const Text("Suku Cadang:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              ...booking.parts.map((p) => Text("• $p")),
              const SizedBox(height: 12),
            ],

            // ADMIN NOTES
            if (booking.adminNotes != null && booking.adminNotes!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Catatan Admin:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(booking.adminNotes!),
                  const SizedBox(height: 12),
                ],
              ),

            // TOTAL COST
            if (booking.totalCost != null)
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "Total: Rp ${booking.totalCost!.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blueAccent,
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text("$title: ",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }


  List<ServiceBooking> _applyFilter(List<ServiceBooking> bookings) {
    switch (currentFilter) {
      case BookingFilter.active:
        return bookings.where((b) =>
        b.status != "completed" &&
            b.status != "cancelled").toList();

      case BookingFilter.completed:
        return bookings.where((b) => b.status == "completed").toList();

      case BookingFilter.cancelled:
        return bookings.where((b) => b.status == "cancelled").toList();

      default:
        return bookings;
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
