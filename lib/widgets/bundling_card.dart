import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import '../models/bundling.dart';

class BundlingCard extends StatelessWidget {
  final Bundling bundling;
  final VoidCallback? onTap;
  const BundlingCard({super.key, required this.bundling, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: GFCard(
        title: GFListTile(
          titleText: bundling.name,
          subTitleText: '${bundling.productIds.length} produk • Rp ${bundling.bundlePrice.toStringAsFixed(0)}',
        ),
        content: Text(
          bundling.description,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

