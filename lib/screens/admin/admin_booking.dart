import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/service_booking.dart';
import '../../providers/app_providers.dart';
import '../../models/enums.dart';
import '../../data/dao/user_dao.dart';
import '../../data/dao/car_dao.dart';
import '../../widgets/complete_service_dialog.dart';

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

    void _updateStatus(String id, String status) async {
      final booking = ref.read(bookingsProvider.notifier).state.firstWhere(
            (b) => b.id == id,
        orElse: () => throw Exception('Booking not found'),
      );

      if (status == 'completed') {
        // Show the completion dialog
        await showDialog(
          context: context,
          builder: (context) => CompleteServiceDialog(
            booking: booking,
            onComplete: (id, jobs, parts, km, totalCost) async {
              await ref.read(bookingsProvider.notifier).updateServiceDetails(
                id: id,
                jobs: jobs,
                parts: parts,
                km: km,
                totalCost: totalCost,
                notes: 'Servis selesai',
              );
              await ref.read(bookingsProvider.notifier).updateStatus(
                id,
                'completed',
                notes: 'Servis selesai',
              );
            },
          ),
        );
      } else {
        // For other statuses, show the status update dialog
        _showStatusUpdateDialog(context, notifier, id, status);
      }
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
  bool _isValidStatusTransition(String currentStatus, String newStatus) {
    final validTransitions = {
      'pending': ['confirmed', 'cancelled'],
      'confirmed': ['inProgress', 'cancelled'],
      'inProgress': ['waitingForParts', 'completed','cancelled'],
      'waitingForParts': ['inProgress', 'completed','cancelled'],
      'completed': [], // Cannot change from completed
      'cancelled': [], // Cannot change from cancelled
    };

    return validTransitions[currentStatus]?.contains(newStatus) ?? false;
  }
  void _showStatusUpdateDialog(
      BuildContext context, BookingsNotifier notifier, String id, String currentStatus) {
    final statuses = <String, String>{
      'pending': 'Menunggu Konfirmasi',
      'confirmed': 'Dikonfirmasi',
      'inProgress': 'Dalam Pengerjaan',
      'waitingForParts': 'Menunggu Part',
      'completed': 'Selesai',
      'cancelled': 'Dibatalkan',
    };

    // Only allow valid status transitions
    final availableStatuses = statuses.entries
        .where((e) => _isValidStatusTransition(currentStatus, e.key) || e.key == currentStatus)
        .toList();

    String selectedStatus = currentStatus;
    final notesController = TextEditingController();
    final partsController = TextEditingController();
    final kmController = TextEditingController();
    final jobsController = TextEditingController();
    final totalCostController = TextEditingController();

    // Load existing booking data
    final currentBooking = notifier.state.firstWhere((b) => b.id == id);

    // Populate form fields with existing data
    if (currentBooking.jobs?.isNotEmpty ?? false) {
      jobsController.text = currentBooking.jobs!.join(', ');
    }
    if (currentBooking.parts?.isNotEmpty ?? false) {
      partsController.text = currentBooking.parts!.join(', ');
    }
    if (currentBooking.km != null) {
      kmController.text = currentBooking.km.toString();
    }
    if (currentBooking.totalCost != null) {
      totalCostController.text = currentBooking.totalCost.toString();
    }
    if (currentBooking.adminNotes != null) {
      notesController.text = currentBooking.adminNotes!;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Update Status Booking'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      items: availableStatuses.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedStatus = value;
                          });
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Catatan Admin',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    if (selectedStatus == 'inProgress' ||
                        selectedStatus == 'completed' ||
                        selectedStatus == 'waitingForParts') ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: jobsController,
                        decoration: const InputDecoration(
                          labelText: 'Pekerjaan (pisahkan dengan koma)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: partsController,
                        decoration: const InputDecoration(
                          labelText: 'Suku Cadang (pisahkan dengan koma)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: kmController,
                        decoration: const InputDecoration(
                          labelText: 'Kilometer',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: totalCostController,
                        decoration: const InputDecoration(
                          labelText: 'Total Biaya',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final jobs = jobsController.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();
                      final parts = partsController.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();
                      final km = int.tryParse(kmController.text);
                      final totalCost = double.tryParse(totalCostController.text);

                      await notifier.updateStatusAndDetails(
                        id: id,
                        status: selectedStatus,
                        jobs: jobs,
                        parts: parts,
                        km: km,
                        totalCost: totalCost,
                        adminNotes: notesController.text,
                      );

                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Status dan detail servis berhasil diperbarui')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
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