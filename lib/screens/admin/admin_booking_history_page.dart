import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../models/service_booking.dart';

class AdminBookingActivePage extends ConsumerStatefulWidget {
  const AdminBookingActivePage({super.key});

  @override
  ConsumerState createState() => _AdminBookingActivePageState();
}

class _AdminBookingActivePageState extends ConsumerState<AdminBookingActivePage> {
  String selectedFilter = "all";

  @override
  Widget build(BuildContext context) {
    final allBookings = ref.watch(bookingsProvider);

    // Filter booking aktif (selain completed & cancelled)
    final activeBookings = allBookings.where((b) =>
    b.status != "completed" && b.status != "cancelled").toList();

    final filtered = _applyFilter(activeBookings);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Booking Aktif"),
        actions: [
          _buildFilterDropdown(),
        ],
      ),
      body: filtered.isEmpty
          ? const Center(child: Text("Tidak ada booking aktif"))
          : ListView.builder(
        itemCount: filtered.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final booking = filtered[index];
          return _buildBookingCard(context, booking);
        },
      ),
    );
  }

  // ---------------- FILTER ----------------
  Widget _buildFilterDropdown() {
    return DropdownButton<String>(
      value: selectedFilter,
      underline: const SizedBox(),
      items: const [
        DropdownMenuItem(value: "all", child: Text("Semua")),
        DropdownMenuItem(value: "pending", child: Text("Pending")),
        DropdownMenuItem(value: "confirmed", child: Text("Dikonfirmasi")),
        DropdownMenuItem(value: "inProgress", child: Text("Dikerjakan")),
        DropdownMenuItem(value: "waitingParts", child: Text("Menunggu Part")),
        DropdownMenuItem(value: "waitingPayment", child: Text("Menunggu Bayar")),
        DropdownMenuItem(value: "readyForPickup", child: Text("Siap Ambil")),
      ],
      onChanged: (v) => setState(() => selectedFilter = v!),
    );
  }

  // Apply filter
  List<ServiceBooking> _applyFilter(List<ServiceBooking> list) {
    if (selectedFilter == "all") return list;
    return list.where((b) => b.status == selectedFilter).toList();
  }

  // ---------------- CARD ----------------
  Widget _buildBookingCard(BuildContext context, ServiceBooking b) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        title: Text("Booking #${b.id.substring(0, 8)}"),
        subtitle: Text("Status: ${b.status}"),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          // go to detail
        },
      ),
    );
  }
}
