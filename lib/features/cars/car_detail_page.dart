import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../widgets/neumorphic_header.dart';

class CarDetailPage extends ConsumerWidget {
  final String carId;
  const CarDetailPage({super.key, required this.carId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cars = ref.watch(carsProvider);
    final car = cars.firstWhere((c) => c.id == carId);
    final mainCarId = ref.watch(mainCarIdProvider);
    final isMain = mainCarId == car.id;
    return Scaffold(
      appBar: GFAppBar(title: const Text('Detail Mobil')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NeumorphicHeader(title: '${car.brand} ${car.model}', subtitle: 'Tahun ${car.year} • ${car.plateNumber}'),
            const SizedBox(height: 8),
            Text('Tahun: ${car.year}'),
            Text('Nomor Polisi: ${car.plateNumber}'),
            Text('Nomor Rangka (VIN): ${car.vin}'),
            Text('Nomor Mesin: ${car.engineNumber}'),
            Text('KM Awal: ${car.initialKm}'),
            const SizedBox(height: 16),
            GFButton(
              onPressed: () => ref.read(mainCarIdProvider.notifier).state = car.id,
              text: isMain ? 'Sudah jadi mobil utama' : 'Jadikan mobil utama',
              color: const Color(0xFF1E88E5),
            ),
          ],
        ),
      ),
    );
  }
}
