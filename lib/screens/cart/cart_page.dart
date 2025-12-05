import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';
import '../../widgets/neumorphic_header.dart';

class CartPage extends ConsumerWidget {
  const CartPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    return Scaffold(
      appBar: GFAppBar(title: const Text('Cart')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: NeumorphicHeader(title: 'Ringkasan Keranjang', subtitle: 'Tinjau sebelum checkout'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: cart.items.length,
              itemBuilder: (context, i) {
                final item = cart.items[i];
                return GFListTile(
                  title: Text(item.productId),
                  subTitle: Text('Qty: ${item.quantity}'),
                  icon: Text('Rp ${(item.price * item.quantity).toStringAsFixed(0)}'),
                );
              },
            ),
          ),
          Padding(
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
                const SizedBox(height: 8),
                GFButton(
                  onPressed: () => context.push('/checkout'),
                  text: 'Checkout',
                  blockButton: true,
                  color: const Color(0xFF1E88E5),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
