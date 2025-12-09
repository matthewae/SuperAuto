import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminOrdersPage extends ConsumerWidget {
  const AdminOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Management'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Consumer(
                builder: (context, ref, child) {
                  final productOrders = ref.watch(productOrderListProvider);
                  return ListView.builder(
                    itemCount: productOrders.length,
                    itemBuilder: (context, index) {
                      final order = productOrders[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                            Text('Order ID: ${order.id}'),
                            Text('Customer: ${order.customerName}'),
                            Text('Product: ${order.productName}'),
                            Text('Quantity: ${order.quantity}'),
                            Text('Status: ${order.status.toString().split('.').last}'),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (order.status == ProductOrderStatus.pending)
                                  FilledButton(
                                    onPressed: () {
                                      ref.read(productOrderListProvider.notifier).confirmOrder(order.id);
                                    },
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                    ),
                                    child: const Text('Confirm'),
                                  ),
                                const SizedBox(width: 8),
                                if (order.status == ProductOrderStatus.confirmed)
                                  ElevatedButton(
                                    onPressed: () {
                                      ref.read(productOrderListProvider.notifier).sendReceipt(order.id);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Receipt for Order ${order.id} sent!'),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                    ),
                                    child: const Text('Send Receipt'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum ProductOrderStatus { pending, confirmed, shipped }

class ProductOrder {
  final String id;
  final String customerName;
  final String productName;
  final int quantity;
  ProductOrderStatus status;

  ProductOrder({
    required this.id,
    required this.customerName,
    required this.productName,
    required this.quantity,
    this.status = ProductOrderStatus.pending,
  });

  ProductOrder copyWith({
    String? id,
    String? customerName,
    String? productName,
    int? quantity,
    ProductOrderStatus? status,
  }) {
    return ProductOrder(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      status: status ?? this.status,
    );
  }
}

class ProductOrderListNotifier extends StateNotifier<List<ProductOrder>> {
  ProductOrderListNotifier() : super(_initialProductOrders);

  static final List<ProductOrder> _initialProductOrders = [
    ProductOrder(id: 'PO001', customerName: 'Alice Smith', productName: 'Oil Filter', quantity: 1),
    ProductOrder(id: 'PO002', customerName: 'Bob Johnson', productName: 'Spark Plugs', quantity: 4),
    ProductOrder(id: 'PO003', customerName: 'Charlie Brown', productName: 'Brake Pads', quantity: 2),
    ProductOrder(id: 'PO004', customerName: 'Diana Prince', productName: 'Wiper Blades', quantity: 2),
    ProductOrder(id: 'PO005', customerName: 'Clark Kent', productName: 'Air Filter', quantity: 1),
  ];

  void confirmOrder(String id) {
    state = [
      for (final order in state)
        if (order.id == id)
          order.copyWith(status: ProductOrderStatus.confirmed)
        else
          order,
    ];
  }

  void sendReceipt(String id) {
    state = [
      for (final order in state)
        if (order.id == id)
          order.copyWith(status: ProductOrderStatus.shipped)
        else
          order,
    ];
    // In a real app, this would trigger an email or notification service
    print('Receipt sent for order $id');
  }
}

final productOrderListProvider = StateNotifierProvider<ProductOrderListNotifier, List<ProductOrder>>((ref) {
  return ProductOrderListNotifier();
});
