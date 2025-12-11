import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../models/order.dart';
import 'package:go_router/go_router.dart';
import '../../models/enums.dart'; // berisi OrderFilter

class OrderHistoryPage extends ConsumerStatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  ConsumerState<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends ConsumerState<OrderHistoryPage> {
  OrderFilter currentFilter = OrderFilter.pending;

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider);
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Riwayat Pesanan"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
        ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: orders.isEmpty
                ? const Center(child: Text("Belum ada pesanan"))
                : ListView(
              children: _applyFilter(orders).map((order) {
                return Card(
                  child: ListTile(
                    title: Text("Pesanan #${order.id.substring(0, 8)}"),
                    subtitle: Text(
                        "${order.items.length} item • Rp ${order.total.toStringAsFixed(0)} • ${_statusLabel(order.status)}"
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      context.go('/order-detail/${order.id}');
                    },
                  ),
                );
              }).toList(),
            ),
          )
        ],
      ),
    ),);
  }

  // ------------------------------------------------------
  // FILTER CHIPS
  // ------------------------------------------------------
  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        children: [
          _chip("Pending", OrderFilter.pending),
          _chip("Processing", OrderFilter.processing),
          _chip("Dikirim", OrderFilter.shipped),
          _chip("Terkirim", OrderFilter.delivered),
          _chip("Batal", OrderFilter.cancelled),
        ],
      ),
    );
  }

  Widget _chip(String label, OrderFilter filter) {
    final selected = currentFilter == filter;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() => currentFilter = filter);
      },
    );
  }

  // ------------------------------------------------------
  // FILTER LOGIC
  // ------------------------------------------------------
  List<Order> _applyFilter(List<Order> orders) {
    switch (currentFilter) {
      case OrderFilter.pending:
        return orders.where((o) => o.status == "pending").toList();

      case OrderFilter.processing:
        return orders.where((o) => o.status == "processing").toList();

      case OrderFilter.shipped:
        return orders.where((o) => o.status == "shipped").toList();

      case OrderFilter.delivered:
        return orders.where((o) => o.status == "delivered").toList();

      case OrderFilter.cancelled:
        return orders.where((o) => o.status == "cancelled").toList();
    }
  }

  // ------------------------------------------------------
  // STATUS LABEL
  // ------------------------------------------------------
  String _statusLabel(String status) {
    switch (status) {
      case "pending":
        return "Menunggu Konfirmasi";
      case "processing":
        return "Diproses";
      case "shipped":
        return "Dikirim";
      case "delivered":
        return "Terkirim";
      case "cancelled":
        return "Dibatalkan";
      default:
        return status;
    }
  }
}
