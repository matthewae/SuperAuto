import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';
import '../../models/product.dart';
import '../../widgets/neumorphic_header.dart';

class CatalogPage extends ConsumerWidget {
  const CatalogPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final cars = ref.watch(carsProvider);
    final mainCarId = ref.watch(mainCarIdProvider);
    final mainCar = cars.where((c) => c.id == mainCarId).firstOrNull;
    final model = mainCar?.model;
    final filtered = model == null
        ? products
        : products.where((p) => p.compatibleModels.isEmpty || p.compatibleModels.contains(model)).toList();
    return Scaffold(
      appBar: GFAppBar(title: const Text('Katalog Produk')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 3 / 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: filtered.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) {
            return Neumorphic(
              style: const NeumorphicStyle(depth: 6, lightSource: LightSource.topLeft),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Filter otomatis berdasarkan mobil utama Anda'),
              ),
            );
          }
          final p = filtered[i - 1];
          return InkWell(
            onTap: () => context.push('/product/${p.id}'),
            child: GFCard(
              title: GFListTile(
                titleText: p.name,
                subTitleText: 'Rp ${p.price.toStringAsFixed(0)}',
              ),
              content: Container(
                height: 120,
                alignment: Alignment.center,
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: Text(p.imageUrl == null ? 'No Image' : 'Image'),
              ),
            ),
          );
        },
      ),
    );
  }
}

extension FirstOrNullExt<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
