import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../models/enums.dart';
import '../../widgets/neumorphic_header.dart';

class TrackingPage extends ConsumerWidget {
  const TrackingPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(bookingsProvider);
    return Scaffold(
      appBar: GFAppBar(title: const Text('Tracking Servis')),
      body: ListView.builder(
        itemCount: bookings.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: NeumorphicHeader(title: 'Status Servis', subtitle: 'Pantau progres pemesanan servis Anda'),
            );
          }
          final b = bookings[i - 1];
          return GFCard(
            title: GFListTile(
              titleText: '${b.workshop} • ${b.type.name}',
              subTitleText: 'Status: ${b.status.name}',
              icon: PopupMenuButton<ServiceStatus>(
                onSelected: (s) => ref.read(bookingsProvider.notifier).updateStatus(b.id, s),
                itemBuilder: (context) => ServiceStatus.values.map((s) => PopupMenuItem(value: s, child: Text(s.name))).toList(),
              ),
            ),
            content: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Estimasi: ${b.estimatedCost.toStringAsFixed(0)}'),
            ),
          );
        },
      ),
    );
  }
}
