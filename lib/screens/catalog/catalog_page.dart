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
    final mainCarId = ref.watch(mainCarIdProvider);
    final mainCar = cars.where((c) => c.id == mainCarId).firstOrNull;
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
    
  }
}

extension FirstOrNullExt<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
