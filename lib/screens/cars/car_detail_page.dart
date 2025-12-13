import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';
import '../../models/car.dart';

class CarDetailPage extends ConsumerStatefulWidget {
  final String carId;
  const CarDetailPage({super.key, required this.carId});

  @override
  ConsumerState<CarDetailPage> createState() => _CarDetailPageState();
}

class _CarDetailPageState extends ConsumerState<CarDetailPage> {
  bool _isSettingMain = false;
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final cars = ref.watch(carsProvider);
    final car = cars.firstWhereOrNull((c) => c.id == widget.carId);
    final currentUser = ref.watch(authProvider).value;

    if (car == null) {
      return Scaffold(
        appBar: GFAppBar(title: const Text('Detail Mobil')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Mobil tidak ditemukan',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final isMain = car.isMain;

    return Scaffold(
      appBar: GFAppBar(
        title: const Text('Detail Mobil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              context.pushNamed('car-edit', pathParameters: {'id': car.id});
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GFCard(
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.directions_car, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${car.brand} ${car.model}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isMain)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Utama',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Tahun', car.year.toString()),
                  _buildDetailRow('Nomor Polisi', car.plateNumber),
                  _buildDetailRow('Nomor Rangka (VIN)', car.vin),
                  _buildDetailRow('Nomor Mesin', car.engineNumber),
                  _buildDetailRow('KM Awal', car.initialKm.toString()),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (_isSettingMain)
              const Center(child: CircularProgressIndicator())
            else
              GFButton(
                onPressed: isMain ? null : () => _setAsMainCar(context, ref, car, currentUser),
                text: isMain ? 'Sudah jadi mobil utama' : 'Jadikan mobil utama',
                color: const Color(0xFF1E88E5),
                size: GFSize.LARGE,
                fullWidthButton: true,
              ),

            const SizedBox(height: 12),

            if (_isDeleting)
              const Center(child: CircularProgressIndicator())
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isMain ? null : () => _showDeleteConfirmation(context, ref, car.id, isMain),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text('Hapus Mobil', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value ?? ''),
          ),
        ],
      ),
    );
  }

  Future<void> _setAsMainCar(BuildContext context, WidgetRef ref, Car car, currentUser) async {
    if (currentUser == null) return;

    setState(() {
      _isSettingMain = true;
    });

    try {

      await ref.read(carsProvider.notifier).setMainCar(car.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${car.brand} ${car.model} dijadikan mobil utama'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengubah mobil utama: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSettingMain = false;
        });
      }
    }
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context, WidgetRef ref, String carId, bool isMain) async {
    if (isMain) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat menghapus mobil utama.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Mobil'),
        content: const Text('Apakah Anda yakin ingin menghapus mobil ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      setState(() {
        _isDeleting = true;
      });

      try {
        await ref.read(carsProvider.notifier).remove(carId);
        if (context.mounted) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mobil berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal menghapus mobil'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isDeleting = false;
          });
        }
      }
    }
  }
}

extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}