import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/service_history.dart';
import '../../providers/app_providers.dart';
import 'package:intl/intl.dart';
import 'package:superauto/models/service_booking.dart';

// Dummy data for demonstration
// final dummyHistoryProvider = Provider<List<ServiceHistoryItem>>((ref) {
//   return [
//     ServiceHistoryItem(
//       id: '1',
//       userId: 'user1',
//       carId: 'car1',
//       date: DateTime.now().subtract(const Duration(days: 30)),
//       km: 50000,
//       jobs: ['Ganti Oli', 'Pengecekan Rem'],
//       parts: ['Oli Mesin', 'Filter Oli'],
//       totalCost: 500000,
//     ),
//     ServiceHistoryItem(
//       id: '2',
//       userId: 'user1',
//       carId: 'car1',
//       date: DateTime.now().subtract(const Duration(days: 60)),
//       km: 45000,
//       jobs: ['Servis Rutin', 'Ganti Busi'],
//       parts: ['Busi NGK'],
//       totalCost: 300000,
//     ),
//     ServiceHistoryItem(
//       id: '3',
//       userId: 'user1',
//       carId: 'car1',
//       date: DateTime.now().subtract(const Duration(days: 90)),
//       km: 40000,
//       jobs: ['Perbaikan Kaki-kaki'],
//       parts: ['Shockbreaker Depan'],
//       totalCost: 1200000,
//     ),
//   ];
// });

// In lib/screens/history/history_page.dart
class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;
    final completedBookings = ref.watch(completedBookingsProvider(user?.id.toString() ?? ''));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Servis'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: completedBookings.when(
        data: (bookings) {
          print('Jumlah booking yang selesai: ${bookings.length}'); // Debug print
          if (bookings.isEmpty) {
            return const Center(child: Text('Belum ada riwayat servis'));
          }
          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              print('Booking $index: ${booking.toMap()}'); // Debug print
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header dengan tanggal dan tipe servis
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatServiceType(booking.serviceType),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
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
                      const SizedBox(height: 12),

                      // Info bengkel
                      if (booking.workshop != null) ...[
                        _buildInfoRow('Bengkel', booking.workshop!),
                        const SizedBox(height: 8),
                      ],

                      // Daftar pekerjaan
                      if (booking.jobs?.isNotEmpty ?? false) ...[
                        const Text(
                          'Pekerjaan:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        ...booking.jobs!.map((job) => Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 2),
                          child: Text('• $job'),
                        )).toList(),
                        const SizedBox(height: 8),
                      ],

                      // Daftar suku cadang
                      if (booking.parts?.isNotEmpty ?? false) ...[
                        const Text(
                          'Suku Cadang:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        ...booking.parts!.map((part) => Padding(
                          padding: const EdgeInsets.only(left: 8, bottom: 2),
                          child: Text('• $part'),
                        )).toList(),
                        const SizedBox(height: 8),
                      ],

                      // Info tambahan (KM dan biaya)
                      Row(
                        children: [
                          if (booking.km != null) ...[
                            _buildInfoChip(
                              icon: Icons.speed,
                              label: '${booking.km} KM',
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (booking.totalCost != null)
                            _buildInfoChip(
                              icon: Icons.attach_money,
                              label: 'Rp${booking.totalCost?.toStringAsFixed(0)}',
                              color: Colors.green,
                            ),
                        ],
                      ),

                      // Catatan admin
                      if (booking.adminNotes?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Catatan:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(booking.adminNotes!),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) {
          print('Error loading completed bookings: $error'); // Debug print
          return Center(child: Text('Error: $error'));
        },
      ),
    );
  }
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

// Helper method untuk menampilkan chip info
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    Color color = Colors.blue,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  String _formatServiceType(String type) {
    switch (type) {
      case 'regular':
        return 'Servis Rutin';
      case 'repair':
        return 'Perbaikan';
      case 'emergency':
        return 'Darurat';
      default:
        return type;
    }
  }
}

// Add this provider to get completed bookings
final completedBookingsProvider = FutureProvider.autoDispose
    .family<List<ServiceBooking>, String>((ref, userId) async {
  final bookings = await ref.watch(bookingsProvider.notifier).getByUserId(userId);
  return bookings.where((b) => b.status == 'completed').toList();
});