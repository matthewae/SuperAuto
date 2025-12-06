import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============================
// ENUM FILTERS
// ============================
enum HistoryFilter { day, week, month }
enum TransactionTypeFilter { all, spareParts }

// ============================
// MODEL
// ============================
class HistoryEntry {
  final String id;
  final String type; // 'Sale' atau 'Service'
  final String description;
  final double amount;
  final DateTime date;

  HistoryEntry({
    required this.id,
    required this.type,
    required this.description,
    required this.amount,
    required this.date,
  });
}

// ============================
// STATE NOTIFIER
// ============================
class HistoryListNotifier extends StateNotifier<List<HistoryEntry>> {
  HistoryListNotifier()
      : super([
          HistoryEntry(
              id: '1',
              type: 'Sale',
              description: 'Oil Change',
              amount: 50.0,
              date: DateTime.now().subtract(const Duration(hours: 2))),
          HistoryEntry(
              id: '2',
              type: 'Service',
              description: 'Tire Rotation',
              amount: 30.0,
              date: DateTime.now().subtract(const Duration(days: 1))),
          HistoryEntry(
              id: '3',
              type: 'Sale',
              description: 'Brake Pad Replacement',
              amount: 120.0,
              date: DateTime.now().subtract(const Duration(days: 3))),
          HistoryEntry(
              id: '4',
              type: 'Service',
              description: 'Engine Tune-up',
              amount: 150.0,
              date: DateTime.now().subtract(const Duration(days: 8))),
          HistoryEntry(
              id: '5',
              type: 'Sale',
              description: 'Battery Purchase',
              amount: 90.0,
              date: DateTime.now().subtract(const Duration(days: 15))),
          HistoryEntry(
              id: '6',
              type: 'Service',
              description: 'Wheel Alignment',
              amount: 70.0,
              date: DateTime.now().subtract(const Duration(days: 25))),
          HistoryEntry(
              id: '7',
              type: 'Sale',
              description: 'Headlight Bulb',
              amount: 20.0,
              date: DateTime.now().subtract(const Duration(days: 35))),
        ]);

  List<HistoryEntry> getFilteredHistory(
      HistoryFilter dateFilter, TransactionTypeFilter typeFilter) {
    final now = DateTime.now();

    return state.where((entry) {
      // =====================
      // FILTER TANGGAL
      // =====================
      bool isDateValid = false;

      switch (dateFilter) {
        case HistoryFilter.day:
          isDateValid = entry.date.year == now.year &&
              entry.date.month == now.month &&
              entry.date.day == now.day;
          break;

        case HistoryFilter.week:
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final endOfWeek = startOfWeek.add(const Duration(days: 6));

          isDateValid = entry.date.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
              entry.date.isBefore(endOfWeek.add(const Duration(days: 1)));
          break;

        case HistoryFilter.month:
          isDateValid = entry.date.year == now.year &&
              entry.date.month == now.month;
          break;
      }

      // =====================
      // FILTER TIPE TRANSAKSI
      // =====================
      bool isTypeValid = switch (typeFilter) {
        TransactionTypeFilter.all => true,
        TransactionTypeFilter.spareParts => entry.type == 'Sale',
      };

      return isDateValid && isTypeValid;
    }).toList();
  }
}

// ============================
// PROVIDERS
// ============================
final historyFilterProvider =
    StateProvider<HistoryFilter>((ref) => HistoryFilter.day);

final transactionTypeFilterProvider =
    StateProvider<TransactionTypeFilter>((ref) => TransactionTypeFilter.all);

final historyListProvider =
    StateNotifierProvider<HistoryListNotifier, List<HistoryEntry>>(
        (ref) => HistoryListNotifier());

// ============================
// UI PAGE
// ============================
class AdminHistoryPage extends ConsumerWidget {
  const AdminHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentDateFilter = ref.watch(historyFilterProvider);
    final currentTypeFilter = ref.watch(transactionTypeFilterProvider);

    final historyNotifier = ref.read(historyListProvider.notifier);
    final filteredHistory =
        historyNotifier.getFilteredHistory(currentDateFilter, currentTypeFilter);

    return Scaffold(
      appBar: AppBar(title: const Text("Admin Sales/Service History")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ============================
            // FILTER TANGGAL BUTTON GROUP
            // ============================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFilterButton(
                  context,
                  ref,
                  label: "Day",
                  isActive: currentDateFilter == HistoryFilter.day,
                  onTap: () =>
                      ref.read(historyFilterProvider.notifier).state =
                          HistoryFilter.day,
                ),
                _buildFilterButton(
                  context,
                  ref,
                  label: "Week",
                  isActive: currentDateFilter == HistoryFilter.week,
                  onTap: () =>
                      ref.read(historyFilterProvider.notifier).state =
                          HistoryFilter.week,
                ),
                _buildFilterButton(
                  context,
                  ref,
                  label: "Month",
                  isActive: currentDateFilter == HistoryFilter.month,
                  onTap: () =>
                      ref.read(historyFilterProvider.notifier).state =
                          HistoryFilter.month,
                ),
              ],
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFilterButton(
                  context,
                  ref,
                  label: "Semua Transaksi",
                  isActive: currentTypeFilter == TransactionTypeFilter.all,
                  onTap: () =>
                      ref.read(transactionTypeFilterProvider.notifier).state =
                          TransactionTypeFilter.all,
                ),
                _buildFilterButton(
                  context,
                  ref,
                  label: "Hanya Suku Cadang",
                  isActive:
                      currentTypeFilter == TransactionTypeFilter.spareParts,
                  onTap: () =>
                      ref.read(transactionTypeFilterProvider.notifier).state =
                          TransactionTypeFilter.spareParts,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ============================
            // LIST HISTORY
            // ============================
            Expanded(
              child: filteredHistory.isEmpty
                  ? const Center(
                      child: Text("No history found for this filter"),
                    )
                  : ListView.builder(
                      itemCount: filteredHistory.length,
                      itemBuilder: (context, index) {
                        final entry = filteredHistory[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(
                              "${entry.type}: ${entry.description}",
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              "Amount: \$${entry.amount.toStringAsFixed(2)}\n"
                              "Date: ${entry.date.toLocal().toString().split(' ')[0]}",
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================
  // BUTTON COMPONENT
  // ============================
  Widget _buildFilterButton(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GFButton(
      onPressed: onTap,
      text: label,
      type: isActive ? GFButtonType.solid : GFButtonType.outline,
      color: Colors.blue,
    );
  }
}
