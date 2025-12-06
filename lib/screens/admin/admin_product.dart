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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Products",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Add"),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const ProductFormDialog(),
                    );
                  },
                ),

              ],
            ),

            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: products.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) => ProductItem(product: products[i]),
              ),
            )
          ],
        ),
      ),
    );
  }
}
