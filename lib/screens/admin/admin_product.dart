import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../widgets/product_form_dialog.dart';
import '../../widgets/product_item.dart';

class AdminProducts extends ConsumerWidget {
  const AdminProducts({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Product Management', style: Theme.of(context).textTheme.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const ProductFormDialog(),
              );
            },
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final pendingOrdersCountAsync = ref.watch(pendingOrdersCountProvider);
          final pendingBookingsCount = ref.watch(pendingBookingsCountProvider);
          final products = ref.watch(productsProvider);

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildInfoCard(
                      context,
                      icon: Icons.receipt_long,
                      title: 'Pesanan Tertunda',
                      value: pendingOrdersCountAsync.when(
                        data: (count) => count.toString(),
                        loading: () => '...',
                        error: (err, stack) => 'Error',
                      ),
                      color: Colors.orange.shade100,
                      iconColor: Colors.orange.shade700,
                    ),
                    _buildInfoCard(
                      context,
                      icon: Icons.calendar_today,
                      title: 'Booking Tertunda',
                      value: pendingBookingsCount.toString(),
                      color: Colors.blue.shade100,
                      iconColor: Colors.blue.shade700,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.separated(
                    itemCount: products.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: Theme.of(context).dividerColor),
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ProductItem(product: products[i]),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required Color iconColor,
  }) {
    return Card(
      color: color,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 36, color: iconColor),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.black87,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
            ),
          ],
        ),
      ),
    );
  }}

