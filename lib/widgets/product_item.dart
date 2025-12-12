import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../models/product.dart';
import 'product_form_dialog.dart';
import 'package:getwidget/getwidget.dart';

class ProductItem extends ConsumerWidget {
  final Product product;

  const ProductItem({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: SizedBox(
          width: 50,
          height: 50,
          child: product.imageUrl != null
              ? Image.network(
            product.imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.image_not_supported);
            },
          )
              : const Icon(Icons.image),
        ),
        title: Text(product.name),
        subtitle: Text('Rp ${product.price.toStringAsFixed(0)}'),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            // Buka dialog edit
            showDialog(
              context: context,
              builder: (_) => ProductFormDialog(existing: product),
            );
          },
        ),
      ),
    );
  }
}
