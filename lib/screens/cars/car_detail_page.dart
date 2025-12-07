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
    final mainCarId = ref.watch(mainCarIdProvider);
    final currentUser = ref.watch(authProvider).value;

    // Find the car or show error if not found
    final car = cars.firstWhereOrNull((c) => c.id == carId);

    if (car == null) {
      return Scaffold(
        appBar: GFAppBar(title: const Text('Detail Mobil')),
        body: const Center(
          child: Text('Mobil tidak ditemukan'),
        ),
      );
    }

    final isMain = mainCarId == car.id;

    Future<void> setAsMainCar() async {
      if (currentUser == null) return;

      try {
        await ref
            .read(mainCarIdProvider.notifier)
            .setMainCarId(currentUser.idString, car.id);

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
            NeumorphicHeader(
              title: '${car.brand} ${car.model}',
              subtitle: 'Tahun ${car.year} • ${car.plateNumber}',
            ),
            const SizedBox(height: 8),
            _buildDetailRow('Tahun', car.year.toString()),
            _buildDetailRow('Nomor Polisi', car.plateNumber),
            _buildDetailRow('Nomor Rangka (VIN)', car.vin),
            _buildDetailRow('Nomor Mesin', car.engineNumber),
            _buildDetailRow('KM Awal', car.initialKm.toString()),
            const SizedBox(height: 16),

            // Main Car Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isMain ? null : setAsMainCar,
                icon: Icon(isMain ? Icons.star : Icons.star_border),
                label: Text(
                  isMain ? 'Mobil Utama' : 'Jadikan Mobil Utama',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: isMain
                      ? Colors.orange.withOpacity(0.1)
                      : Theme.of(context).primaryColor,
                  foregroundColor: isMain ? Colors.orange : Colors.white,
                  elevation: 0,
                ),
              ),
            ),

            // Delete Button
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showDeleteConfirmation(context, ref, carId),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text(
                  'Hapus Mobil',
                  style: TextStyle(color: Colors.red),
                ),
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
      BuildContext context,
      WidgetRef ref,
      String carId,
      ) async {
    final isMain = ref.read(mainCarIdProvider) == carId;

    if (isMain) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Tidak dapat menghapus mobil utama. Silakan ubah mobil utama terlebih dahulu.'),
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
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.red),
            ),
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