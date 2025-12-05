import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../widgets/neumorphic_header.dart';

class PromoPage extends ConsumerWidget {
  const PromoPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promos = ref.watch(promosProvider);
    final applied = ref.watch(cartProvider).appliedPromoId;
    return Scaffold(
      appBar: GFAppBar(title: const Text('Promo & Voucher')),
      body: ListView.builder(
        itemCount: promos.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: NeumorphicHeader(title: 'Promo Aktif', subtitle: 'Klik untuk menerapkan ke cart'),
            );
          }
          final p = promos[i - 1];
          final isApplied = applied == p.id;
          return GFCard(
            title: GFListTile(
              titleText: p.name,
              subTitleText: '${p.type} • ${p.value}%',
              icon: isApplied ? const Icon(Icons.check_circle, color: Colors.green) : null,
            ),
            buttonBar: GFButtonBar(children: [
              GFButton(
                onPressed: () {
                  ref.read(cartProvider.notifier).applyPromo(p.id);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Promo diterapkan')));
                },
                text: isApplied ? 'Diterapkan' : 'Terapkan',
                color: const Color(0xFF1E88E5),
              )
            ]),
          );
        },
      ),
    );
  }
}
