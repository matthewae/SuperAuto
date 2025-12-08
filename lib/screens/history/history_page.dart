import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/service_history.dart'; // Import ServiceHistoryItem

// Dummy data for demonstration
final dummyHistoryProvider = Provider<List<ServiceHistoryItem>>((ref) {
  return [
    ServiceHistoryItem(
      id: '1',
      userId: 'user1',
      carId: 'car1',
      date: DateTime.now().subtract(const Duration(days: 30)),
      km: 50000,
      jobs: ['Ganti Oli', 'Pengecekan Rem'],
      parts: ['Oli Mesin', 'Filter Oli'],
      totalCost: 500000,
    ),
    ServiceHistoryItem(
      id: '2',
      userId: 'user1',
      carId: 'car1',
      date: DateTime.now().subtract(const Duration(days: 60)),
      km: 45000,
      jobs: ['Servis Rutin', 'Ganti Busi'],
      parts: ['Busi NGK'],
      totalCost: 300000,
    ),
    ServiceHistoryItem(
      id: '3',
      userId: 'user1',
      carId: 'car1',
      date: DateTime.now().subtract(const Duration(days: 90)),
      km: 40000,
      jobs: ['Perbaikan Kaki-kaki'],
      parts: ['Shockbreaker Depan'],
      totalCost: 1200000,
    ),
  ];
});

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(dummyHistoryProvider); // Use dummy data
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Servis'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            GoRouter.of(context).go('/home');
          },
        ),
      ),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, i) {
          final h = items[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${h.date.toLocal().toString().split(' ').first} • KM ${h.km}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Rp ${h.totalCost.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (h.jobs.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pekerjaan:', style: Theme.of(context).textTheme.titleSmall),
                        ...h.jobs.map((job) => Padding(
                          padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                          child: Text('- $job', style: Theme.of(context).textTheme.bodyMedium),
                        )),
                        const SizedBox(height: 8),
                      ],
                    ),
                  if (h.parts.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sparepart:', style: Theme.of(context).textTheme.titleSmall),
                        ...h.parts.map((part) => Padding(
                          padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                          child: Text('- $part', style: Theme.of(context).textTheme.bodyMedium),
                        )),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
    
  }
}
