import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';

import '../../models/enums.dart';
import '../../widgets/neumorphic_header.dart';

final selectedCategoryProvider = StateProvider<ProductCategory?>((ref) => null);
final searchQueryProvider = StateProvider<String>((ref) => '');
final currentPageProvider = StateProvider<int>((ref) => 0); // Added for pagination
const int itemsPerPage = 6; // Added for pagination

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
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final currentPage = ref.watch(currentPageProvider); // Added for pagination

    final filtered = products.where((p) {
      final matchesModel = model == null || p.compatibleModels.isEmpty || p.compatibleModels.contains(model);
      final matchesCategory = selectedCategory == null || p.category == selectedCategory;
      final matchesSearch = p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          p.description.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesModel && matchesCategory && matchesSearch;
    }).toList();

    // Pagination logic
    final int start = currentPage * itemsPerPage;
    final int end = (currentPage + 1) * itemsPerPage;
    final paginatedProducts = filtered.sublist(start, end.clamp(0, filtered.length));

    return Builder(
      builder: (context) => Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: NeumorphicHeader(title: 'Katalog', subtitle: 'Temukan produk terbaik untuk mobil Anda'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextFormField(
              decoration: const InputDecoration(
                labelText: 'Cari Produk',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).state = value;
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                spacing: 8.0,
                children: ProductCategory.values.map((category) {
                  return ChoiceChip(
                    label: Text(category.name),
                    selected: selectedCategory == category,
                    onSelected: (selected) {
                      ref.read(selectedCategoryProvider.notifier).state = selected ? category : null;
                    },
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: paginatedProducts.length,
              itemBuilder: (context, i) {
                final p = paginatedProducts[i];
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
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Text(p.imageUrl == null ? 'No Image' : 'Image'),
                    ),
                    buttonBar: GFButtonBar(
                      children: [
                        GFButton(
                          onPressed: () {
                            ref.read(cartProvider.notifier).addItem(p);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${p.name} ditambahkan ke keranjang!'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          text: 'Tambah ke Keranjang',
                          icon: const Icon(Icons.add_shopping_cart),
                          shape: GFButtonShape.pills,
                          fullWidthButton: true,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Pagination Controls
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: currentPage > 0
                      ? () {
                          ref.read(currentPageProvider.notifier).state--;
                        }
                      : null,
                  child: const Text('Previous'),
                ),
                Text('Page ${currentPage + 1}'),
                ElevatedButton(
                  onPressed: end < filtered.length
                      ? () {
                          ref.read(currentPageProvider.notifier).state++;
                        }
                      : null,
                  child: const Text('Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    
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