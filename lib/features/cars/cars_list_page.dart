import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';
import '../../models/car.dart';
import 'package:uuid/uuid.dart';
import '../../widgets/neumorphic_header.dart';

class CarsListPage extends ConsumerWidget {
  const CarsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cars = ref.watch(carsProvider);
    return Scaffold(
      appBar: GFAppBar(title: const Text('Mobil Saya')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/scan'),
        child: const Icon(Icons.qr_code_scanner),
      ),
      body: ListView.builder(
        itemCount: cars.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: NeumorphicHeader(title: 'Daftar Mobil', subtitle: 'Kelola kendaraan Anda'),
            );
          }
          final c = cars[i - 1];
          return GFListTile(
            avatar: const Icon(Icons.directions_car),
            title: Text('${c.brand} ${c.model} (${c.year})'),
            subTitle: Text('${c.plateNumber} • KM awal: ${c.initialKm}'),
            onTap: () => context.go('/cars/${c.id}'),
            icon: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => ref.read(carsProvider.notifier).remove(c.id),
            ),
          );
        },
      ),
    );
  }
}
