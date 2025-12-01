import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../widgets/neumorphic_header.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(historyProvider);
    return Scaffold(
      appBar: GFAppBar(title: const Text('Riwayat Servis')),
      body: ListView.builder(
        itemCount: items.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: NeumorphicHeader(title: 'Riwayat', subtitle: 'Catatan servis kendaraan Anda'),
            );
          }
          final h = items[i - 1];
          return GFCard(
            title: GFListTile(
              titleText: '${h.date.toLocal().toString().split(' ').first} • KM ${h.km}',
              subTitleText: 'Rp ${h.totalCost.toStringAsFixed(0)}',
            ),
            content: Text('Pekerjaan: ${h.jobs.join(', ')}\nSparepart: ${h.parts.join(', ')}'),
          );
        },
      ),
    );
  }
}
