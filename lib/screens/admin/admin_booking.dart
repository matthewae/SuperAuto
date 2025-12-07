import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/service_booking.dart';
import '../../providers/app_providers.dart';
import '../../models/enums.dart';
import '../../data/dao/user_dao.dart';
import '../../data/dao/car_dao.dart';

class AdminBookingPage extends ConsumerWidget {
  const AdminBookingPage({super.key});

  Future<Map<String, dynamic>> _getUserAndCarDetails(
      WidgetRef ref,
      BuildContext context,
      String userId,
      String carId,
      ) async {
    try {
      final user = await ref.read(userDaoProvider).getUserById(userId);
      final car = await ref.read(carDaoProvider).getById(carId);

      // Debug logs
      print('🔍 Fetching car details - CarID: $carId (type: ${carId.runtimeType})');
      print('   - User: ${user?.toMap()}');
      print('   - Car found: ${car != null}');

      return {
        'userName': user?.name ?? 'Unknown User',
        'userPhone': user?.email ?? '-',
        'carInfo': car != null
            ? '${car.brand} ${car.model} (${car.plateNumber})'
            : 'Mobil tidak ditemukan (ID: $carId)',
      };
    } catch (e) {
      print('❌ Error in _getUserAndCarDetails: $e');
      return {
        'userName': 'Error',
        'userPhone': '-',
        'carInfo': 'Error memuat data mobil',
      };
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(bookingsProvider);
    final notifier = ref.read(bookingsProvider.notifier);

    void _updateStatus(String id, String status) {
      _showStatusUpdateDialog(context, notifier, id, status);
    }

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
            final formattedDate = DateFormat('dd MMM yyyy HH:mm').format(
                booking.scheduledAt);

            return FutureBuilder<Map<String, dynamic>>(
              future: _getUserAndCarDetails(
                  ref, context, booking.userId, booking.carId),
              builder: (context, snapshot) {
                final details = snapshot.data ?? {
                  'userName': 'Loading...',
                  'userPhone': '-',
                  'carInfo': 'Loading...',
                };

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Existing booking ID and status
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
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500),
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

                        // User and Car Info
                        _buildInfoRow('Nama', details['userName']),
                        _buildInfoRow('No. HP', details['userPhone']),
                        _buildInfoRow('Mobil', details['carInfo']),
                        const Divider(height: 20),

                        // Booking Details
                        _buildInfoRow('Layanan', booking.serviceType),
                        _buildInfoRow('Bengkel', booking.workshop),
                        _buildInfoRow('Tanggal', formattedDate),
                        _buildInfoRow(
                            'Perkiraan Biaya',
                            'Rp${booking.estimatedCost.toStringAsFixed(0)}'
                        ),

                        if (booking.notes?.isNotEmpty ?? false)
                          _buildInfoRow('Catatan', booking.notes,
                              isMultiline: true),

                        if (booking.adminNotes?.isNotEmpty ?? false)
                          _buildInfoRow('Catatan Admin', booking.adminNotes,
                              isMultiline: true),

                        const SizedBox(height: 12),

                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (booking.status == 'pending') ...[
                              GFButton(
                                onPressed: () =>
                                    _updateStatus(booking.id, 'confirmed'),
                                text: 'Konfirmasi',
                                color: GFColors.SUCCESS,
                                size: GFSize.SMALL,
                              ),
                              const SizedBox(width: 8),
                              GFButton(
                                onPressed: () =>
                                    _updateStatus(booking.id, 'cancelled'),
                                text: 'Tolak',
                                color: GFColors.DANGER,
                                size: GFSize.SMALL,
                              ),
                            ],
                            const SizedBox(width: 8),
                            GFButton(
                              onPressed: () =>
                                  _showStatusUpdateDialog(
                                      context,
                                      notifier,
                                      booking.id,
                                      booking.status
                                  ),
                              text: 'Ubah Status',
                              color: GFColors.INFO,
                              size: GFSize.SMALL,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value,
      {bool isMultiline = false}) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          const Text(': '),
          if (isMultiline)
            Expanded(child: Text(value))
          else
            Text(value),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    try {
      final statusEnum = BookingStatus.values.firstWhere(
            (e) =>
        e
            .toString()
            .split('.')
            .last
            .toLowerCase() == status.toLowerCase(),
        orElse: () => BookingStatus.pending,
      );
      switch (statusEnum) {
        case BookingStatus.confirmed:
          return Colors.green;
        case BookingStatus.cancelled:
          return Colors.red;
        case BookingStatus.completed:
          return Colors.blue;
        case BookingStatus.inProgress:
          return Colors.orange;
        default:
          return Colors.grey;
      }
    } catch (e) {
      return Colors.grey;
    }
  }

  String _getStatusDisplayName(String status) {
    try {
      final statusEnum = BookingStatus.values.firstWhere(
            (e) =>
        e
            .toString()
            .split('.')
            .last
            .toLowerCase() == status.toLowerCase(),
        orElse: () => BookingStatus.pending,
      );
      return statusEnum.displayName;
    } catch (e) {
      return status;
    }
  }

  void _showStatusUpdateDialog(
      BuildContext context,
      BookingsNotifier notifier,
      String bookingId,
      String currentStatus,
      ) {
    final controller = TextEditingController();
    BookingStatus currentStatusEnum;

    try {
      currentStatusEnum = BookingStatus.values.firstWhere(
            (e) =>
        e
            .toString()
            .split('.')
            .last
            .toLowerCase() == currentStatus.toLowerCase(),
      );
    } catch (e) {
      currentStatusEnum = BookingStatus.pending;
    }

    // Get the next possible statuses and include current status
    final possibleStatuses = [
      currentStatusEnum,
      ...BookingStatus.getNextPossibleStatuses(currentStatusEnum)
    ].toSet().toList(); // Use Set to remove duplicates

    BookingStatus? selectedStatus = currentStatusEnum;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Update Status Booking'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Pilih status baru:'),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<BookingStatus>(
                      value: selectedStatus,
                      items: possibleStatuses.map((status) {
                        return DropdownMenuItem<BookingStatus>(
                          value: status,
                          child: Text(status.displayName),
                        );
                      }).toList(),
                      onChanged: (status) {
                        setState(() {
                          selectedStatus = status;
                        });
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        labelText: 'Catatan (Opsional)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: selectedStatus == null
                      ? null
                      : () {
                    notifier.updateStatus(
                      bookingId,
                      selectedStatus!
                          .toString()
                          .split('.')
                          .last,
                      notes: controller.text,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}