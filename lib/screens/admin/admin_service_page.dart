import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:getwidget/getwidget.dart';

class AdminServicePage extends ConsumerWidget {
  const AdminServicePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Service Bay Status',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Consumer(
                builder: (context, ref, child) {
                  final serviceBays = ref.watch(serviceBayListProvider);
                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // Two bays per row
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: serviceBays.length,
                    itemBuilder: (context, index) {
                      final bay = serviceBays[index];
                      return GFCard(
                        color: bay.status == ServiceBayStatus.available ? GFColors.SUCCESS : GFColors.DANGER,
                        content: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Bay ${bay.id}',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              bay.status == ServiceBayStatus.available ? 'Available' : 'Occupied by ${bay.vehiclePlate}',
                              style: const TextStyle(fontSize: 16, color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                            if (bay.status == ServiceBayStatus.occupied)
                              GFButton(
                                onPressed: () {
                                  ref.read(serviceBayListProvider.notifier).markBayAsAvailable(bay.id);
                                },
                                text: 'Mark as Available',
                                color: GFColors.LIGHT,
                                textColor: GFColors.DARK,
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum ServiceBayStatus { available, occupied }

class ServiceBay {
  final String id;
  ServiceBayStatus status;
  String? vehiclePlate;

  ServiceBay({
    required this.id,
    this.status = ServiceBayStatus.available,
    this.vehiclePlate,
  });

  ServiceBay copyWith({
    String? id,
    ServiceBayStatus? status,
    String? vehiclePlate,
  }) {
    return ServiceBay(
      id: id ?? this.id,
      status: status ?? this.status,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
    );
  }
}

class ServiceBayListNotifier extends StateNotifier<List<ServiceBay>> {
  ServiceBayListNotifier() : super(_initialServiceBays);

  static final List<ServiceBay> _initialServiceBays = [
    ServiceBay(id: 'A1'),
    ServiceBay(id: 'A2', status: ServiceBayStatus.occupied, vehiclePlate: 'B 1234 CD'),
    ServiceBay(id: 'B1'),
    ServiceBay(id: 'B2', status: ServiceBayStatus.occupied, vehiclePlate: 'D 5678 EF'),
    ServiceBay(id: 'C1'),
  ];

  void markBayAsOccupied(String id, String vehiclePlate) {
    state = [
      for (final bay in state)
        if (bay.id == id)
          bay.copyWith(status: ServiceBayStatus.occupied, vehiclePlate: vehiclePlate)
        else
          bay,
    ];
  }

  void markBayAsAvailable(String id) {
    state = [
      for (final bay in state)
        if (bay.id == id)
          bay.copyWith(status: ServiceBayStatus.available, vehiclePlate: null)
        else
          bay,
    ];
  }
}

final serviceBayListProvider = StateNotifierProvider<ServiceBayListNotifier, List<ServiceBay>>((ref) {
  return ServiceBayListNotifier();
});
