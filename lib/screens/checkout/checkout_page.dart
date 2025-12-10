// In checkout_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:getwidget/getwidget.dart';
import 'package:uuid/uuid.dart';

import '../../providers/app_providers.dart';
import '../../models/order.dart';
import '../../data/dao/order_dao.dart';
import '../../data/dao/cart_dao.dart';
import '../../widgets/neumorphic_header.dart';
import 'package:go_router/go_router.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  String? _selectedPaymentMethod;
  String? _selectedShippingMethod;
  bool _isLoading = false;

  final List<String> _paymentMethods = ['GoPay', 'OVO', 'Dana', 'Bank Transfer', 'COD'];
  final List<String> _shippingMethods = ['Reguler', 'Express', 'Same Day'];

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final cart = ref.read(cartProvider);
      final user = ref.read(authProvider).value;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan login terlebih dahulu')),
        );
        return;
      }

      final orderId = const Uuid().v4();

      final items = cart.items.map((item) {
        return OrderItem(
          id: const Uuid().v4(),
          orderId: orderId,
          productId: item.productId,
          productName: item.productName,
          price: item.price,
          quantity: item.quantity,
          imageUrl: item.imageUrl,
        );
      }).toList();

      // Create order with items
      final order = Order(
        id: orderId,
        userId: user.id!,
        items: items,
        total: cart.subtotal,
        createdAt: DateTime.now(),
        status: 'pending',
        paymentMethod: _selectedPaymentMethod,
        shippingMethod: _selectedShippingMethod,
        shippingAddress: _addressController.text,
        trackingNumber: null, // admin will fill this later
      );

      // Save the order and its items in a transaction
      final orderDao = OrderDao();
      await orderDao.insert(order);
      
      // Clear the cart
      ref.read(cartProvider.notifier).clear();
      
      // Update the orders list in the provider
      if (ref.read(ordersProvider.notifier) is AsyncNotifier) {
        await (ref.read(ordersProvider.notifier) as dynamic).refresh();
      }

      // Loyalty points
      final pointsEarned = (cart.subtotal ~/ 100000) * 10;
      ref.read(loyaltyPointsProvider.notifier).state += pointsEarned;

      if (!mounted) return;

      context.go('/order-confirmation', extra: orderId);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat pesanan: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final total = cart.subtotal;

    return Scaffold(
      appBar: GFAppBar(
        title: const Text('Checkout & Pembayaran'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const NeumorphicHeader(
              title: 'Informasi Pengiriman',
              subtitle: 'Pastikan alamat pengiriman sudah benar',
            ),
            const SizedBox(height: 16),

            // Shipping Address
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Alamat Pengiriman',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Alamat pengiriman harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Shipping Method
            DropdownButtonFormField<String>(
              value: _selectedShippingMethod,
              decoration: const InputDecoration(
                labelText: 'Metode Pengiriman',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.delivery_dining),
              ),
              items: _shippingMethods
                  .map((method) => DropdownMenuItem(
                value: method,
                child: Text(method),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedShippingMethod = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Pilih metode pengiriman';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Payment Method
            DropdownButtonFormField<String>(
              value: _selectedPaymentMethod,
              decoration: const InputDecoration(
                labelText: 'Metode Pembayaran',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.payment),
              ),
              items: _paymentMethods
                  .map((method) => DropdownMenuItem(
                value: method,
                child: Text(method),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Pilih metode pembayaran';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),
            const Divider(),

            // Order Summary
            const Text(
              'Ringkasan Pesanan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Order Items
            ...cart.items.map((item) => ListTile(
              leading: item.imageUrl != null
                  ? Image.network(item.imageUrl!, width: 50, height: 50, fit: BoxFit.cover)
                  : const Icon(Icons.shopping_cart),
              title: Text(item.productName),
              subtitle: Text('${item.quantity} x Rp ${item.price.toStringAsFixed(0)}'),
              trailing: Text('Rp ${(item.price * item.quantity).toStringAsFixed(0)}'),
            )),

            const Divider(),

            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  'Rp ${total.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Checkout Button
            GFButton(
              onPressed: _placeOrder,
              text: 'Buat Pesanan',
              color: Theme.of(context).primaryColor,
              textColor: Colors.white,
              size: GFSize.LARGE,
              fullWidthButton: true,
              shape: GFButtonShape.pills,
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}