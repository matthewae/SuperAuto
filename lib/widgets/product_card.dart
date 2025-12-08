import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  const ProductCard({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: GFCard(
        title: GFListTile(
          titleText: product.name,
          subTitleText: 'Rp ${product.price.toStringAsFixed(0)}',
        ),
        content: Container(
          height: 120,
          alignment: Alignment.center,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Text(product.imageUrl == null ? 'No Image' : 'Image'),
        ),
      ),
    );
  }
}
