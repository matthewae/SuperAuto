import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum BookingStatus { pending, confirmed, assigned }

class Booking {
  final String id;
  final String service;
  final String customer;
  final String date;
  BookingStatus status;
  String? assignedBay;

  Booking({
    required this.id,
    required this.service,
    required this.customer,
    required this.date,
    this.status = BookingStatus.pending,
    this.assignedBay,
  });

  Booking copyWith({
    BookingStatus? status,
    String? assignedBay,
  }) {
    return Booking(
      id: id,
      service: service,
      customer: customer,
      date: date,
      status: status ?? this.status,
      assignedBay: assignedBay ?? this.assignedBay,
    );
  }
}

class BookingListNotifier extends StateNotifier<List<Booking>> {
  BookingListNotifier() : super([
    Booking(id: '1', service: 'Oil Change', customer: 'John Doe 1', date: '2024-07-15'),
    Booking(id: '2', service: 'Tire Rotation', customer: 'Jane Smith 2', date: '2024-07-16', status: BookingStatus.confirmed),
    Booking(id: '3', service: 'Brake Inspection', customer: 'Peter Jones 3', date: '2024-07-17'),
    Booking(id: '4', service: 'Engine Tune-up', customer: 'Alice Brown 4', date: '2024-07-18'),
    Booking(id: '5', service: 'Battery Check', customer: 'Bob White 5', date: '2024-07-19', status: BookingStatus.assigned, assignedBay: 'Bay 3'),
  ]);

  void confirmBooking(String id) {
    state = [for (final booking in state) if (booking.id == id) booking.copyWith(status: BookingStatus.confirmed) else booking];
  }

  void assignBay(String id, String bay) {
    state = [for (final booking in state) if (booking.id == id) booking.copyWith(status: BookingStatus.assigned, assignedBay: bay) else booking];
  }
}

final bookingListProvider = StateNotifierProvider<BookingListNotifier, List<Booking>>((ref) {
  return BookingListNotifier();
});

class AdminBookingPage extends ConsumerWidget {
  const AdminBookingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(bookingListProvider);
    final notifier = ref.read(bookingListProvider.notifier);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admin Booking Management',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Booking #${booking.id}',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text('Service: ${booking.service} - ${booking.status.name}'),
                          Text('Customer: ${booking.customer}'),
                          Text('Date: ${booking.date}'),
                          if (booking.assignedBay != null) Text('Assigned Bay: ${booking.assignedBay}'),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (booking.status == BookingStatus.pending) GFButton(
                                onPressed: () {
                                  notifier.confirmBooking(booking.id);
                                },
                                text: 'Confirm',
                                color: GFColors.SUCCESS,
                              ),
                              const SizedBox(width: 8),
                              if (booking.status != BookingStatus.assigned) GFButton(
                                onPressed: () {
                                  // For simplicity, assign to a dummy bay
                                  notifier.assignBay(booking.id, 'Bay 1');
                                },
                                text: 'Assign Bay',
                                color: GFColors.PRIMARY,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
