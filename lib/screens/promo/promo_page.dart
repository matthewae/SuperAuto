import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../models/promo.dart';
import '../../providers/app_providers.dart';

class PromoListPage extends ConsumerWidget {
  const PromoListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promo Tersedia'),
      ),
      body: FutureBuilder<List<Promo>>(
        future: ref.read(promosProvider.notifier).getActivePromos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final activePromos = snapshot.data ?? [];
          final cartState = ref.watch(cartProvider);
          final appliedPromoId = cartState.appliedPromoId;

          if (activePromos.isEmpty) {
            return const Center(child: Text('Tidak ada promo yang tersedia'));
          }

          return ListView.builder(
            itemCount: activePromos.length,
            itemBuilder: (context, index) {
              final promo = activePromos[index];
              final isApplied = appliedPromoId == promo.id;

              return Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promo.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tipe: ${promo.formattedType}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Nilai: ${promo.formattedValue}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        'Berlaku: ${DateFormat('dd MMM yyyy').format(promo.start)} - ${DateFormat('dd MMM yyyy').format(promo.end)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (isApplied) {
                              ref.read(cartProvider.notifier).applyPromo(null);
                            } else {
                              ref.read(cartProvider.notifier).applyPromo(promo.id);
                              if (promo.type == 'service_discount') {
                                context.push('/booking');
                              } else if (promo.type == 'product_discount') {
                                context.go('/catalog');
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isApplied ? Colors.grey : null,
                          ),
                          child: Text(isApplied ? 'Batalkan' : 'Gunakan'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}