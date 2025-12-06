// In checkout_page.dart
import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../providers/app_providers.dart';
import '../../models/order.dart';
import '../../widgets/neumorphic_header.dart';

class CheckoutPage extends ConsumerWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final authState = ref.watch(authProvider);
    final total = cart.subtotal;
    final shippingMethods = const ['Reguler', 'Kargo', 'Same Day'];
    String selectedShipping = shippingMethods.first;

    return Scaffold(
      appBar: GFAppBar(title: const Text('Checkout & Pembayaran')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const NeumorphicHeader(title: 'Ringkasan Pembayaran', subtitle: 'Pastikan data sudah benar'),
            const SizedBox(height: 12),
            const Text('Metode Pengiriman'),
            DropdownButton<String>(
              value: selectedShipping,
              items: shippingMethods.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => selectedShipping = v ?? selectedShipping,
            ),
            const SizedBox(height: 12),
            Neumorphic(
              style: const NeumorphicStyle(depth: 6, lightSource: LightSource.topLeft),
              padding: const EdgeInsets.all(12),
              child: Text('Total: Rp ${total.toStringAsFixed(0)}'),
            ),
            const Spacer(),
            authState.when(
              data: (user) {
                if (user == null) {
                  return const Text('Silakan login terlebih dahulu');
                }
                return GFButton(
                  onPressed: () {
                    if (cart.items.isEmpty) return;

                    final order = Order(
                      id: const Uuid().v4(),
                      userId: user.idString,
                      items: cart.items
                          .map((item) => OrderItem(
                        id: const Uuid().v4(),
                        productId: item.productId,
                        name: item.productName,
                        price: item.price,
                        quantity: item.quantity,
                        imageUrl: item.imageUrl,
                      ))
                          .toList(),
                      total: total,
                      createdAt: DateTime.now(),
                      status: 'pending',
                      shippingMethod: 'Standard',
                      paymentMethod: 'Go Pay',
                      shippingAddress: 'Masukkan alamat',
                    );

                    ref.read(ordersProvider.notifier).add(order);
                    ref.read(loyaltyPointsProvider.notifier).state += (total ~/ 10000);
                    ref.read(cartProvider.notifier).clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pembayaran berhasil')),
                    );
                    Navigator.of(context).pop();
                  },
                  text: 'Bayar',
                  color: const Color(0xFF1E88E5),
                  blockButton: true,
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Error: $error'),
            ),
          ],
        ),
      ),
    );
  }
}