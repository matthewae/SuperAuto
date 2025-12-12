import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/app_providers.dart';
import '../../widgets/complete_service_dialog.dart';
import '../../models/promo.dart';
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
    // FILTER: hanya booking aktif
    final bookings = ref.watch(bookingsProvider).where((b) {
      final s = b.status.toLowerCase();
      return s != 'completed' && s != 'cancelled';
    }).toList();

    final notifier = ref.read(bookingsProvider.notifier);

    void _updateStatus(String id, String status) async {
      final booking = notifier.state.firstWhere(
            (b) => b.id == id,
      );

      if (status == 'completed') {
        await showDialog(
          context: context,
          builder: (context) => CompleteServiceDialog(
            booking: booking,
            onComplete: (id, jobs, parts, km, totalCost) async {
              await notifier.updateServiceDetails(
                id: id,
                jobs: jobs,
                parts: parts,
                km: km,
                totalCost: totalCost,
                notes: 'Servis selesai',
              );
              await notifier.updateStatus(
                id,
                'completed',
                notes: 'Servis selesai',
              );
            },
          ),
        );
      } else {
        _showStatusUpdateDialog(context, notifier, id, status);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Booking'),
        centerTitle: true,
      ),
      body: bookings.isEmpty
          ? const Center(child: Text('Tidak ada booking aktif'))
          : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            final formattedDate = DateFormat('dd MMM yyyy HH:mm')
                .format(booking.scheduledAt);

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
                        _buildInfoRow('Nama', details['userName']),
                        _buildInfoRow('E-Mail', details['userPhone']),
                        _buildInfoRow('Mobil', details['carInfo']),
                        const Divider(height: 20),
                        _buildInfoRow('Layanan', booking.serviceType),
                        _buildInfoRow('Bengkel', booking.workshop),
                        _buildInfoRow('Tanggal', formattedDate),
                        _buildInfoRow(
                            'Perkiraan Biaya',
                            'Rp${booking.estimatedCost.toStringAsFixed(0)}'
                        ),
                        if (booking.totalCost != null) ...[
                          _buildInfoRow(
                              'Total Biaya',
                              'Rp${booking.totalCost!.toStringAsFixed(0)}'
                          ),
                          // Add promo info if exists
                          if (booking.promoId != null)
                            FutureBuilder<Promo?>(
                              future: ref.read(promoDaoProvider).getById(booking.promoId!),
                              builder: (context, snapshot) {
                                if (snapshot.hasData && snapshot.data != null) {
                                  final promo = snapshot.data!;
                                  return FutureBuilder<double>(
                                    future: ref.read(bookingsProvider.notifier).calculateDiscount(booking.id),
                                    builder: (context, discountSnapshot) {
                                      final discount = discountSnapshot.data ?? 0.0;
                                      return Column(
                                        children: [
                                          _buildInfoRow(
                                              'Promo',
                                              '${promo.name} (${promo.formattedValue})'
                                          ),
                                          _buildInfoRow(
                                              'Diskon',
                                              '-Rp${discount.toStringAsFixed(0)}'
                                          ),
                                          _buildInfoRow(
                                              'Total Setelah Diskon',
                                              'Rp${(booking.totalCost! - discount).toStringAsFixed(0)}'
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                        ],
                        if (booking.notes?.isNotEmpty ?? false) ...[
                          const SizedBox(height: 4),
                          _buildInfoRow(
                            'Catatan',
                            booking.notes!,
                            isMultiline: true,
                          ),
                        ],

                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            GFButton(
                              onPressed: () => _showStatusUpdateDialog(
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
          }),
    );
  }

  Widget _buildInfoRow(String label, String? value, {bool isMultiline = false}) {
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
    switch (status) {
      case 'pending':
        return Colors.grey;
      case 'confirmed':
        return Colors.green;
      case 'inProgress':
        return Colors.orange;
      case 'waitingForParts':
        return Colors.blueGrey;
      case 'readyForPickup':
        return Colors.teal;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu Konfirmasi';
      case 'confirmed':
        return 'Dikonfirmasi';
      case 'inProgress':
        return 'Sedang Dikerjakan';
      case 'waitingForParts':
        return 'Menunggu Part';
      case 'readyForPickup':
        return 'Siap Diambil';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  bool _isValidStatusTransition(String currentStatus, String newStatus) {
    final validTransitions = {
      'pending': ['confirmed', 'cancelled'],
      'confirmed': ['inProgress', 'cancelled'],
      'inProgress': ['waitingForParts', 'readyForPickup', 'completed', 'cancelled'],
      'waitingForParts': ['inProgress', 'readyForPickup', 'completed', 'cancelled'],
      'readyForPickup': ['completed', 'cancelled'],
      'completed': [],
      'cancelled': [],
    };

    return validTransitions[currentStatus]?.contains(newStatus) ?? false;
  }

  void _showStatusUpdateDialog(
      BuildContext context, BookingsNotifier notifier, String id, String currentStatus) {
    final statuses = <String, String>{
      'pending': 'Menunggu Konfirmasi',
      'confirmed': 'Dikonfirmasi',
      'inProgress': 'Sedang Dikerjakan',
      'waitingForParts': 'Menunggu Part',
      'readyForPickup': 'Siap Diambil',
      'completed': 'Selesai',
      'cancelled': 'Dibatalkan',
    };

    // Only allow valid status transitions
    final availableStatuses = statuses.entries
        .where((e) =>
    _isValidStatusTransition(currentStatus, e.key) ||
        e.key == currentStatus)
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
      // Jika admin sudah pernah menetapkan totalCost, gunakan nilai itu.
      totalCostController.text = currentBooking.totalCost.toString();
    } else if (currentBooking.estimatedCost != null) {
      // Jika totalCost belum ada (masih null), gunakan estimatedCost sebagai nilai awal.
      totalCostController.text = currentBooking.estimatedCost.toString();
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
                  onPressed: () => Navigator.pop(context),
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