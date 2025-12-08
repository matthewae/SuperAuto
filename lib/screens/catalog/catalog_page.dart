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

    // Debug logging
    print('Products count: ${products.length}');
    print('Cars count: ${cars.length}');

    // Find the main car using isMain
    final mainCar = cars.firstWhereOrNull((car) => car.isMain);
    final model = mainCar?.model;
    print('Main car model: $model');

    // Prepare products with compatibility info
    final productsWithCompatibility = products.map((p) {
      final isCompatible = model == null ||
          p.compatibleModels.isEmpty ||
          p.compatibleModels.any((m) => m.toLowerCase() == model?.toLowerCase());
      return {
        'product': p,
        'isCompatible': isCompatible,
      };
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Katalog Produk'),
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: productsWithCompatibility.length,
        itemBuilder: (context, index) {
          final item = productsWithCompatibility[index];
          final product = item['product'] as Product;
          final isCompatible = item['isCompatible'] as bool;

          return Opacity(
            opacity: isCompatible ? 1.0 : 0.6,
            child: InkWell(
              onTap: () => context.push('/product/${product.id}'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        child: product.imageUrl != null
                            ? Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.image_not_supported);
                          },
                        )
                            : const Center(
                          child: Icon(Icons.image, size: 48),
                        ),
                      ),
                    ),
                    // Product Info
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rp ${product.price.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!isCompatible) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Mungkin tidak kompatibel',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

extension FirstWhereOrNullExt<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}