import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../widgets/neumorphic_header.dart';

class ProductDetailPage extends ConsumerWidget {
  final String productId;
  const ProductDetailPage({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final product = products.firstWhere((p) => p.id == productId);
    return Scaffold(
      appBar: GFAppBar(title: Text(product.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const NeumorphicHeader(title: 'Detail Produk', subtitle: 'Info dan kompatibilitas'),
            const SizedBox(height: 12),
            Expanded(
              child: GFCarousel(
                height: 180,
                items: [
                  Container(color: Theme.of(context).colorScheme.surfaceVariant, alignment: Alignment.center, child: const Text('Image 1')),
                  Container(color: Theme.of(context).colorScheme.surfaceVariant, alignment: Alignment.center, child: const Text('Image 2')),
                  Container(color: Theme.of(context).colorScheme.surfaceVariant, alignment: Alignment.center, child: const Text('Image 3')),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(product.description),
            const SizedBox(height: 12),
            Text('Rp ${product.price.toStringAsFixed(0)}'),
            const SizedBox(height: 12),
            GFButton(
              onPressed: () => ref.read(cartProvider.notifier).addItem(product),
              text: 'Add to Cart',
              icon: const Icon(Icons.add_shopping_cart),
              color: const Color(0xFF1E88E5),
              blockButton: true,
            ),
          ],
        ),
      ),
    );
  }
}
