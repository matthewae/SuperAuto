import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/app_providers.dart';
import 'package:superauto/models/service_booking.dart';
import 'package:superauto/models/enums.dart' show BookingFilter;

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the filtered bookings provider
    final filteredBookingsAsync = ref.watch(historyBookingsProvider);
    // Watch the current filter state
    final currentFilter = ref.watch(historyFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Servis'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                _buildFilterChip(
                  context: context,
                  ref: ref,
                  label: 'Semua',
                  filter: BookingFilter.all,
                  isSelected: currentFilter == BookingFilter.all,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context: context,
                  ref: ref,
                  label: 'Selesai',
                  filter: BookingFilter.completed,
                  isSelected: currentFilter == BookingFilter.completed,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context: context,
                  ref: ref,
                  label: 'Dibatalkan',
                  filter: BookingFilter.cancelled,
                  isSelected: currentFilter == BookingFilter.cancelled,
                ),
              ],
            ),
          ),
          // Bookings list
          Expanded(
            child: filteredBookingsAsync.when(
              data: (bookings) {
                if (bookings.isEmpty) {
                  return const Center(
                    child: Text('Tidak ada riwayat servis yang ditemukan'),
                  );
                }
                return ListView.builder(
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    return _buildBookingCard(booking);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required WidgetRef ref,
    required String label,
    required BookingFilter filter,
    required bool isSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        ref.read(historyFilterProvider.notifier).setFilter(filter);
      },
      backgroundColor: isSelected
          ? Theme.of(context).primaryColor.withOpacity(0.2)
          : Colors.grey[200],
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.4),
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildBookingCard(ServiceBooking booking) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status dan tanggal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(booking.status),
                    style: TextStyle(
                      color: _getStatusColor(booking.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  DateFormat('d MMM yyyy').format(booking.scheduledAt),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Tipe layanan dan bengkel
            if (booking.workshop != null) ...[
              const SizedBox(height: 4),
              Text(
                booking.workshop!,
                style: const TextStyle(color: Colors.grey),
              ),
            ],

            // Detail tambahan (pekerjaan, suku cadang, dll.)
            if (booking.jobs?.isNotEmpty ?? false) ...[
              const SizedBox(height: 12),
              const Text('Pekerjaan:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ...booking.jobs!.map((job) => Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                child: Text('• $job'),
              )),
            ],

            if (booking.parts?.isNotEmpty ?? false) ...[
              const SizedBox(height: 12),
              const Text('Suku Cadang:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ...booking.parts!.map((part) => Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                child: Text('• $part'),
              )),
            ],

            if (booking.km != null || booking.totalCost != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (booking.km != null)
                    Text(
                      'KM: ${booking.km}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  if (booking.totalCost != null)
                    Text(
                      'Total: Rp${booking.totalCost?.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                ],
              ),
            ],

            if (booking.adminNotes?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Catatan: ${booking.adminNotes}',
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  // Helper methods
  String _getFilterDisplayName(BookingFilter filter) {
    switch (filter) {
      case BookingFilter.all:
        return 'Semua';
      case BookingFilter.active:
        return 'Aktif';
      case BookingFilter.completed:
        return 'Selesai';
      case BookingFilter.cancelled:
        return 'Dibatalkan';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }


}