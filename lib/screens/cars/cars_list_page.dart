import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';
import '../../models/car.dart';

class CarsListPage extends ConsumerWidget {
  const CarsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cars = ref.watch(carsProvider);
    // Gunakan provider asli
    final mainCarId = ref.watch(mainCarIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Mobil')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/scan'),
        child: const Icon(Icons.qr_code_scanner),
      ),
      body: ListView.builder(
        itemCount: cars.length,
        itemBuilder: (context, index) {
          final car = cars[index];
          // Cek apakah ini mobil utama
          final isMain = car.id == mainCarId;

          return ListTile(
            leading: const Icon(Icons.directions_car),
            title: Text('${car.brand} ${car.model} (${car.year})'),
            subtitle: Text('${car.plateNumber} • KM awal: ${car.initialKm}'),
            trailing: isMain
                ? const Icon(Icons.star, color: Colors.orange) // Tampilkan bintang jika utama
                : null, // Sembunyikan jika bukan utama
            onTap: () => context.push('/cars/${car.id}'),
          );
        },
      ),
    );
  }
}