import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';
import '../../models/car.dart';
import '../../widgets/neumorphic_header.dart';

class CarDetailPage extends ConsumerWidget {
  final String carId;
  const CarDetailPage({super.key, required this.carId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cars = ref.watch(carsProvider);
    Car? car;
    try {
      car = cars.firstWhere((c) => c.id == carId);
    } catch (e) {
      car = null;
    }


    if (car == null) {
      return Scaffold(
        appBar: GFAppBar(title: const Text('Detail Mobil')),
        body: const Center(
          child: Text('Mobil tidak ditemukan'),
        ),
      );
    }
    final currentUser = ref.watch(authProvider).value;
    final isMain = car.isMain;

    Future<void> setAsMainCar() async {
      if (currentUser == null || car == null) return;

      try {
        // 1. Hapus status 'isMain' untuk SEMUA mobil milik user ini
        final userCars = ref.read(carsProvider);
        for (final userCar in userCars) {
          if (userCar.isMain) {
            await ref.read(carDaoProvider).updateMainCarStatus(
                  userCar.id, 
                  false,
                  userId: currentUser.id.toString(),
                );
          }
        }

        // 2. Tetapkan status 'isMain' untuk mobil yang dipilih
        await ref.read(carDaoProvider).updateMainCarStatus(
              car!.id, 
              true,
              userId: currentUser.id.toString(),
            );

        // 3. REFRESH state agar UI langsung update
        ref.invalidate(carsProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${car!.brand} ${car!.model} dijadikan mobil utama'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal mengubah mobil utama'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    return Scaffold(
      appBar: GFAppBar(
        title: const Text('Detail Mobil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: car == null ? null : () {
              context.pushNamed('car-edit', pathParameters: {'id': car!.id});
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tahun: ${car.year}'),
            Text('Nomor Polisi: ${car.plateNumber}'),
            Text('Nomor Rangka (VIN): ${car.vin}'),
            Text('Nomor Mesin: ${car.engineNumber}'),
            Text('KM Awal: ${car.initialKm}'),
            const SizedBox(height: 16),
            GFButton(
              onPressed: isMain ? null : setAsMainCar,
              text: isMain ? 'Sudah jadi mobil utama' : 'Jadikan mobil utama',
              color: const Color(0xFF1E88E5),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: car == null ? null : () => _showDeleteConfirmation(context, ref, car!.id, isMain),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
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
      }
    }
  }
}

// Add this extension if not already in your project
extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}