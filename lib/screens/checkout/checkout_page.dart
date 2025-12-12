import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:getwidget/getwidget.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../providers/app_providers.dart';
import '../../models/order.dart';
import '../../models/promo.dart';
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
  String? _appliedPromoId;
  Promo? _appliedPromo;

  final List<String> _paymentMethods = ['GoPay', 'OVO', 'Dana', 'Bank Transfer', 'COD'];
  final List<String> _shippingMethods = ['Reguler', 'Express', 'Same Day'];

  @override
  void initState() {
    super.initState();
    _loadAppliedPromo();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadAppliedPromo() async {
    final cart = ref.read(cartProvider);
    if (cart.appliedPromoId != null) {
      final promo = await ref.read(promoDaoProvider).getById(cart.appliedPromoId!);
      if (promo != null && promo.isActive()) {
        setState(() {
          _appliedPromoId = cart.appliedPromoId;
          _appliedPromo = promo;
        });
      } else {
        // If promo is not valid, clear it
        await ref.read(cartProvider.notifier).applyPromo(null);
      }
    }
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
        userName: user.name,
        items: items,
        total: cart.total,
        createdAt: DateTime.now(),
        status: 'pending',
        paymentMethod: _selectedPaymentMethod,
        shippingMethod: _selectedShippingMethod,
        shippingAddress: _addressController.text,
        trackingNumber: null, // admin will fill this later
      );

      // Save to order and its items in a transaction
      final orderDao = OrderDao();
      await orderDao.insert(order);

      // Clear cart
      ref.read(cartProvider.notifier).clear();

      // Update orders list in provider
      if (ref.read(ordersProvider.notifier) is AsyncNotifier) {
        await (ref.read(ordersProvider.notifier) as dynamic).refresh();
      }

      // Loyalty points
      final pointsEarned = (cart.total ~/ 100000) * 10;
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
    final subtotal = cart.subtotal;
    final discount = cart.discount;
    final total = cart.total;

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

            // Applied Promo
            if (_appliedPromo != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_offer, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _appliedPromo!.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Berlaku hingga ${DateFormat('dd MMM yyyy').format(_appliedPromo!.end)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '-Rp ${discount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Price Summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal'),
                Text('Rp ${subtotal.toStringAsFixed(0)}'),
              ],
            ),
            if (discount > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Diskon'),
                  Text(
                    '-Rp ${discount.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Biaya Pengiriman'),
                Text('Rp ${_selectedShippingMethod == 'Reguler' ? '10000' : _selectedShippingMethod == 'Express' ? '20000' : '30000'}'),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
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