import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/app_providers.dart';
import '../../models/promo.dart';
import '../../models/product.dart';
import '../../models/cart.dart';


class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final products = ref.watch(productsProvider);


    final allPromos = ref.watch(promosProvider);
    final isPromoLoading = ref.read(promosProvider.notifier).isLoading;

    final productMap = <String, Product>{for (var p in products) p.id: p};

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
            if (cart.items.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Text('Keranjang belanja Anda kosong.'),
                ),
              )
            else ...[
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, i) {
                    final item = cart.items[i];
                    final product = productMap[item.productId];

                    if (product == null) {
                      return Neumorphic(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.error, color: Colors.red),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Text(
                                  'Produk tidak ditemukan. Mungkin sudah dihapus.',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_forever, color: Colors.red),
                                onPressed: () {
                                  ref.read(cartProvider.notifier).removeItem(item.productId);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }

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
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey[300],
                              ),
                              child: product.imageUrl != null
                                  ? Image.network(product.imageUrl!, fit: BoxFit.cover)
                                  : const Center(child: Icon(Icons.image)),
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
                                        onPressed: () async {
                                          try {
                                            if (item.quantity > 1) {
                                              await ref.read(cartProvider.notifier).updateItemQuantity(
                                                item.productId,
                                                item.quantity - 1,
                                              );
                                            } else {
                                              await ref.read(cartProvider.notifier).removeItem(item.productId);
                                            }
                                          } catch (e) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Gagal mengupdate item: $e'), backgroundColor: Colors.red),
                                            );
                                          }
                                        },
                                      ),
                                      Text('${item.quantity}'),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline),
                                        onPressed: () async {
                                          try {
                                            await ref.read(cartProvider.notifier).updateItemQuantity(
                                              item.productId,
                                              item.quantity + 1,
                                            );
                                          } catch (e) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Gagal mengupdate item: $e'), backgroundColor: Colors.red),
                                            );
                                          }
                                        },
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: const Icon(Icons.delete_forever, color: Colors.red),
                                        onPressed: () async {
                                          try {
                                            await ref.read(cartProvider.notifier).removeItem(item.productId);
                                          } catch (e) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Gagal menghapus item: $e'), backgroundColor: Colors.red),
                                            );
                                          }
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
                      Neumorphic(
                        style: NeumorphicStyle(
                          shape: NeumorphicShape.flat,
                          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
                          depth: 4,
                          lightSource: LightSource.topLeft,
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Promo',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),

                              if (isPromoLoading)
                                const Center(child: CircularProgressIndicator())
                              else if (allPromos.isEmpty)
                                const Text('Tidak ada promo tersedia saat ini.')
                              else
                                _buildPromoList(context, ref, cart, allPromos),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Neumorphic(
                        style: NeumorphicStyle(
                          shape: NeumorphicShape.flat,
                          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
                          depth: 4,
                          lightSource: LightSource.topLeft,
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        ),
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
                              if (cart.discount > 0) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Diskon'),
                                    Text(
                                      '-Rp ${cart.discount.toStringAsFixed(0)}',
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ],
                              const Divider(),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Rp ${cart.total.toStringAsFixed(0)}',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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
          ],
        ),
      ),
    );
  }


  Widget _buildPromoList(BuildContext context, WidgetRef ref, CartState cart, List<Promo> allPromos) {
    final productDiscountPromos = allPromos.where((promo) =>
    promo.type == 'product_discount' && promo.isActive()
    ).toList();

    return productDiscountPromos.isEmpty
        ? const Text('Tidak ada promo produk yang aktif.')
        : Column(
      children: productDiscountPromos.map((promo) {
        final isSelected = cart.appliedPromoId == promo.id;
        return InkWell(
          onTap: () async {
            try {
              await ref.read(cartProvider.notifier).applyPromo(
                isSelected ? null : promo.id,
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Gagal menerapkan promo: $e'), backgroundColor: Colors.red),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
              ),
              borderRadius: BorderRadius.circular(8),
              color: isSelected
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promo.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Berlaku hingga ${DateFormat('dd MMM yyyy').format(promo.end)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  promo.formattedValue,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}