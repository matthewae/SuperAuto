import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../models/product.dart';
import '../../models/enums.dart';
import '../../widgets/neumorphic_header.dart';

class BundlingPage extends ConsumerWidget {
  const BundlingPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundlings = ref.watch(bundlingsProvider);
    return Scaffold(
      appBar: GFAppBar(title: const Text('Bundling Produk')),
      body: ListView.builder(
        itemCount: bundlings.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: NeumorphicHeader(title: 'Paket Hemat', subtitle: 'Gabungan produk dengan harga spesial'),
            );
          }
          final b = bundlings[i - 1];
          return GFCard(
            title: GFListTile(
              titleText: b.name,
              subTitleText: b.description,
              icon: Text('Rp ${b.bundlePrice.toStringAsFixed(0)}'),
            ),
            buttonBar: GFButtonBar(children: [
              GFButton(
                onPressed: () {
                  final synthetic = Product(
                    id: 'bundle:${b.id}',
                    name: 'Bundle ${b.name}',
                    category: ProductCategory.interiorAccessories,
                    description: b.description,
                    price: b.bundlePrice,
                  );
                  ref.read(cartProvider.notifier).addItem(synthetic);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bundling ditambahkan ke cart')));
                },
                text: 'Tambah ke Cart',
                color: const Color(0xFF1E88E5),
              )
            ]),
          );
        },
      ),
    );
  }
}
