import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';

class ProductDetailPage extends ConsumerWidget {
  final String productId;
  const ProductDetailPage({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final product = products.firstWhere((p) => p.id == productId);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(product.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
              background: GFCarousel(
                height: 250,
                items: [
                  Container(color: Theme.of(context).colorScheme.surfaceContainerHighest, alignment: Alignment.center, child: const Text('Image 1')),
                  Container(color: Theme.of(context).colorScheme.surfaceContainerHighest, alignment: Alignment.center, child: const Text('Image 2')),
                  Container(color: Theme.of(context).colorScheme.surfaceContainerHighest, alignment: Alignment.center, child: const Text('Image 3')),
                ],
                autoPlay: true,
                enlargeMainPage: true,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Rp ${product.price.toStringAsFixed(0)}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(height: 16),
                  Text('Kategori: ${product.category.name}', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (product.compatibleModels.isNotEmpty)
                    Text('Kompatibel dengan Model: ${product.compatibleModels.join(', ')}', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  Text(product.description, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 24),
                  GFButton(
                    onPressed: () {
                      ref.read(cartProvider.notifier).addItem(productId: product.id, productName: product.name, price: product.price);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${product.name} ditambahkan ke keranjang!'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    text: 'Tambah ke Keranjang',
                    icon: const Icon(Icons.add_shopping_cart),
                    color: const Color(0xFF1E88E5),
                    blockButton: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );          
  }
}
