import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';

class LoyaltyPage extends ConsumerWidget {
  const LoyaltyPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final points = ref.watch(loyaltyPointsProvider);
    return Scaffold(
      appBar: GFAppBar(title: const Text('Loyalty Rewards')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Neumorphic(
              style: const NeumorphicStyle(depth: 8, lightSource: LightSource.topLeft),
              padding: const EdgeInsets.all(16),
              child: Text('Poin Anda: $points', style: Theme.of(context).textTheme.headlineMedium),
            ),
            const SizedBox(height: 12),
            GFButton(
              onPressed: points >= 100 ? () => ref.read(loyaltyPointsProvider.notifier).state -= 100 : null,
              text: 'Tukar 100 poin jadi voucher',
              color: const Color(0xFF1E88E5),
            )
          ],
        ),
      ),
    );
  }
}
