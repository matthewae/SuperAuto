import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../models/service_booking.dart';
import '../../models/enums.dart' show BookingFilter;
import 'booking_detail_page.dart';

class BookingsPage extends ConsumerStatefulWidget {
  const BookingsPage({super.key});

  @override
  ConsumerState<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends ConsumerState<BookingsPage> {
  BookingFilter currentFilter = BookingFilter.active;

  @override
  Widget build(BuildContext context) {
    final allBookings = ref.watch(bookingsProvider);

    // --- PERBAIKAN: Terapkan filter di sini untuk membuat daftar baru ---
    final filteredBookings = _filterBookings(allBookings, currentFilter);

    return Scaffold(
      appBar: AppBar(title: const Text("Daftar Booking")),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: filteredBookings.isEmpty
                ? const Center(child: Text("Tidak ada data booking untuk filter ini"))
                : ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: filteredBookings.length, // Gunakan panjang filteredBookings
              itemBuilder: (context, index) {
                final booking = filteredBookings[index]; // Ambil dari filteredBookings
                // Gunakan satu fungsi pembuat kartu untuk semua kasus
                return _buildBookingCard(booking, context);
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- PERBAIKAN: Kembalikan fungsi helper untuk menyaring ---
  List<ServiceBooking> _filterBookings(List<ServiceBooking> bookings, BookingFilter filter) {
    switch (filter) {
      case BookingFilter.active:
      // Kembalikan booking yang statusnya BUKAN 'completed' atau 'cancelled'
        return bookings
            .where((b) => b.status != 'completed' && b.status != 'cancelled')
            .toList();
      case BookingFilter.completed:
      // Kembalikan booking yang statusnya 'completed'
        return bookings.where((b) => b.status == 'completed').toList();
      case BookingFilter.cancelled:
      // Kembalikan booking yang statusnya 'cancelled'
        return bookings.where((b) => b.status == 'cancelled').toList();
      case BookingFilter.all:
      default:
      // Untuk filter 'all' atau tidak diketahui, kembalikan semua booking
        return bookings;
    }
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

  // --- PERUBAHAN: Satu fungsi untuk semua kartu booking ---
  Widget _buildBookingCard(ServiceBooking booking, BuildContext context) {
    // Tentukan apakah kartu harus bisa diklik atau tidak
    final isTappable = currentFilter == BookingFilter.active;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      elevation: 2,
      // Beri warna berbeda untuk item yang tidak bisa diklik sebagai indikator visual
      color: isTappable ? null : Colors.grey.shade300,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: isTappable
            ? () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingDetailPage(bookingId: booking.id),
          ),
        )
            : null, // Non-aktifkan tap jika bukan filter 'active'
        child: Padding(
          padding: const EdgeInsets.all(16),
          // --- TAMBAHAN IKON: Bungkus Column dalam Row ---
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gunakan Expanded agar konten utama mengambil ruang yang tersisa
              Expanded(
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

                    // SERVICE LOCATION
                    if (booking.serviceLocation != null && booking.isPickupService)
                      _infoRow(Icons.local_shipping, "Lokasi Pickup", booking.serviceLocation!),

                    // WORKSHOP
                    if (booking.workshop != null)
                      _infoRow(Icons.store, "Bengkel", booking.workshop!),

                    // KM
                    if (booking.km != null)
                      _infoRow(Icons.speed, "Kilometer", "${booking.km} km"),

                    const SizedBox(height: 12),

                    // JOBS
                    if (booking.jobs.isNotEmpty) ...[
                      const Text("Pekerjaan:", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      ...booking.jobs.map((j) => Text("• $j")),
                      const SizedBox(height: 12),
                    ],

                    // PARTS
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
                          const Text("Catatan Admin:", style: TextStyle(fontWeight: FontWeight.bold)),
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
                      ),
                  ],
                ),
              ),

              // --- TAMBAHAN IKON: Tampilkan ikon panah hanya jika bisa diklik ---
              if (isTappable)
                const Icon(
                  Icons.chevron_right,
                  color: Colors.grey, // Warna yang netral agar tidak terlalu menonjol
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ... (Method helper seperti _infoRow, _formatServiceType, dll tetap sama)
  Widget _infoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Text("$title: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
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