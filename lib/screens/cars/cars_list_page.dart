import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/scan'),
        child: const Icon(Icons.qr_code_scanner),
      ),
      body: ListView.builder(
        itemCount: cars.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) {
            return const SizedBox.shrink();
          }
          final c = cars[i - 1];
          return GFListTile(
            avatar: const Icon(Icons.directions_car),
            title: Text('${c.brand} ${c.model} (${c.year})'),
            subTitle: Text('${c.plateNumber} • KM awal: ${c.initialKm}'),
            onTap: () => context.push('/cars/${c.id}'),
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

