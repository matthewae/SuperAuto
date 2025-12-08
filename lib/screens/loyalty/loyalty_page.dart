
import 'package:getwidget/getwidget.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../widgets/neumorphic_header.dart';

class LoyaltyPage extends ConsumerWidget {
  const LoyaltyPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final points = ref.watch(loyaltyPointsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Loyalty Rewards')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const NeumorphicHeader(title: 'Loyalty Poin', subtitle: 'Kumpulkan poin dan tukarkan hadiah menarik!'),
            const SizedBox(height: 24),
            Neumorphic(
              style: NeumorphicStyle(
                shape: NeumorphicShape.flat,
                boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
                depth: 8,
                lightSource: LightSource.topLeft,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Poin Anda',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      Text('$points Poin',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                    ],
                  ),
                  Icon(Icons.star, size: 48, color: Theme.of(context).colorScheme.primary),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('Hadiah Tersedia',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            // Contoh daftar hadiah
            Neumorphic(
              style: NeumorphicStyle(
                shape: NeumorphicShape.flat,
                boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
                depth: 4,
                lightSource: LightSource.topLeft,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.card_giftcard, size: 40, color: Theme.of(context).colorScheme.secondary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Voucher Diskon Rp 50.000',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Text('Tukarkan dengan 100 Poin', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  GFButton(
                    onPressed: points >= 100
                        ? () {
                            ref.read(loyaltyPointsProvider.notifier).state -= 100;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Voucher berhasil ditukarkan!')),
                            );
                          }
                        : null,
                    text: 'Tukar',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
            Neumorphic(
              style: NeumorphicStyle(
                shape: NeumorphicShape.flat,
                boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
                depth: 4,
                lightSource: LightSource.topLeft,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.local_car_wash, size: 40, color: Theme.of(context).colorScheme.secondary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Gratis Cuci Mobil',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Text('Tukarkan dengan 200 Poin', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  GFButton(
                    onPressed: points >= 200
                        ? () {
                            ref.read(loyaltyPointsProvider.notifier).state -= 200;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Gratis Cuci Mobil berhasil ditukarkan!')),
                            );
                          }
                        : null,
                    text: 'Tukar',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('Cara Mendapatkan Poin',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Neumorphic(
              style: NeumorphicStyle(
                shape: NeumorphicShape.flat,
                boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
                depth: 4,
                lightSource: LightSource.topLeft,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Setiap pembelian Rp 10.000 akan mendapatkan 1 Poin.',
                      style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 8),
                  Text('Setiap layanan servis akan mendapatkan bonus poin.',
                      style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
          ],
        ),
      ),
    );    
  }
}
