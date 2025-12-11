import 'package:getwidget/getwidget.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final products = ref.watch(productsProvider);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      },
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
              ),
              title: const Text('Keranjang'),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, i) {
                  final item = cart.items[i];
                  final product = products.firstWhere((p) => p.id == item.productId);
                  return Neumorphic(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    style: NeumorphicStyle(
                      shape: NeumorphicShape.flat,
                      boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
                      depth: 4,
                      lightSource: LightSource.topLeft,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Product Image
                          Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[300],
                            child: product.imageUrl != null
                                ? Image.network(product.imageUrl!, fit: BoxFit.cover)
                                : const Center(child: Text('No Image')),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Rp ${(item.price * item.quantity).toStringAsFixed(0)}',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      onPressed: () {
                                        if (item.quantity > 1) {
                                          ref.read(cartProvider.notifier).addItem(
                                            productId: product.id,
                                            productName: product.name,
                                            price: product.price,
                                            quantity: -1,
                                          );
                                        } else {
                                          ref.read(cartProvider.notifier).removeItem(item.productId);
                                        }
                                      },
                                    ),
                                    Text('${item.quantity}'),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline),
                                      onPressed: () {
                                        ref.read(cartProvider.notifier).addItem(
                                          productId: product.id,
                                          productName: product.name,
                                          price: product.price,
                                          quantity: 1,
                                        );
                                      },
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                                      onPressed: () {
                                        ref.read(cartProvider.notifier).removeItem(item.productId);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: cart.items.length,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal'),
                        Text('Rp ${cart.subtotal.toStringAsFixed(0)}'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GFButton(
                      onPressed: () {
                        if (cart.items.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Keranjang belanja kosong')),
                          );
                          return;
                        }
                        context.go('/checkout');
                      },
                      text: 'Checkout',
                      blockButton: true,
                      color: Theme.of(context).primaryColor,
                      textColor: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}