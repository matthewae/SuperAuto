import 'package:getwidget/getwidget.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/app_providers.dart';
import '../../models/promo.dart';

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  String? _selectedPromoId;
  bool _showPromoSection = false;
  final TextEditingController _promoCodeController = TextEditingController();

  @override
  void dispose() {
    _promoCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final products = ref.watch(productsProvider);
    final activePromosFuture = ref.read(promosProvider.notifier).getActivePromosByType('product_discount');

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
                    // Promo Section
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Promo',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _showPromoSection = !_showPromoSection;
                                    });
                                  },
                                  child: Text(_showPromoSection ? 'Sembunyikan' : 'Pilih Promo'),
                                ),
                              ],
                            ),
                            if (_showPromoSection) ...[
                              const SizedBox(height: 8),
                              // Promo Code Input
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _promoCodeController,
                                      decoration: const InputDecoration(
                                        labelText: 'Kode Promo',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () async {
                                      final promoCode = _promoCodeController.text.trim();
                                      if (promoCode.isEmpty) return;

                                      final promos = await activePromosFuture;
                                      final matchingPromo = promos.firstWhere(
                                            (promo) => promo.name.toLowerCase() == promoCode.toLowerCase(),
                                        orElse: () => Promo(
                                          id: '',
                                          name: '',
                                          type: '',
                                          value: 0,
                                          start: DateTime.now(),
                                          end: DateTime.now(),
                                          createdAt: DateTime.now(),
                                        ),
                                      );

                                      if (matchingPromo.id.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Kode promo tidak valid')),
                                        );
                                        return;
                                      }

                                      setState(() {
                                        _selectedPromoId = matchingPromo.id;
                                        _promoCodeController.clear();
                                      });

                                      await ref.read(cartProvider.notifier).applyPromo(matchingPromo.id);
                                    },
                                    child: const Text('Gunakan'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Available Promos
                              FutureBuilder<List<Promo>>(
                                future: activePromosFuture,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }

                                  if (snapshot.hasError || !snapshot.hasData) {
                                    return const Text('Tidak ada promo tersedia');
                                  }

                                  final promos = snapshot.data!;
                                  if (promos.isEmpty) {
                                    return const Text('Tidak ada promo tersedia');
                                  }

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Promo Tersedia:',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 8),
                                      ...promos.map((promo) {
                                        final isSelected = _selectedPromoId == promo.id;
                                        return InkWell(
                                          onTap: () async {
                                            setState(() {
                                              _selectedPromoId = isSelected ? null : promo.id;
                                            });
                                            await ref.read(cartProvider.notifier).applyPromo(
                                              isSelected ? null : promo.id,
                                            );
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
                                    ],
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Price Summary
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
        ),
      ),
    );
  }
}