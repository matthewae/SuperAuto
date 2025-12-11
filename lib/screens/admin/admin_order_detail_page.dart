import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/dao/order_dao.dart';
import '../../models/order.dart';
import '../../providers/app_providers.dart';

class AdminOrderDetailPage extends ConsumerStatefulWidget {
  final String orderId;

  const AdminOrderDetailPage({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<AdminOrderDetailPage> createState() =>
      _AdminOrderDetailPageState();
}

class _AdminOrderDetailPageState
    extends ConsumerState<AdminOrderDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _trackingController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _trackingController.dispose();
    super.dispose();
  }

  Future<void> _updateTrackingNumber(String orderId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(orderDaoProvider).updateTrackingNumber(orderId, _trackingController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Tracking number updated successfully"),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {}); // Refresh the page
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update tracking number: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateOrderStatus(String orderId, String status) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(orderDaoProvider).updateStatus(orderId, status);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Order status updated successfully"),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {}); // Refresh the page
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update order status: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dao = ref.watch(orderDaoProvider);

    return FutureBuilder<Order?>(
      future: dao.getById(widget.orderId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Text("Error loading order: ${snap.error}"),
            ),
          );
        }

        if (!snap.hasData || snap.data == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: Text("Order not found"),
            ),
          );
        }

        final order = snap.data!;
        _trackingController.text = order.trackingNumber ?? '';

        final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
        final createdDate = order.createdAt != null
            ? dateFormat.format(order.createdAt!)
            : 'Unknown date';

        return Scaffold(
          appBar: AppBar(
            title: Text("Order #${order.id.substring(0, 8)}..."),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Order Details'),
                Tab(text: 'Manage Order'),
              ],
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
            controller: _tabController,
            children: [
              _buildOrderDetailsTab(order, createdDate),
              _buildManageOrderTab(order),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderDetailsTab(Order order, String createdDate) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order info card
          Card(
            elevation: 2,
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
                        "Order Information",
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusDisplayName(order.status),
                          style: TextStyle(
                            color: _getStatusColor(order.status),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow("Order ID", order.id),
                  _buildDetailRow("Customer", order.userName ?? "Unknown"),
                  _buildDetailRow("Date", createdDate),
                  _buildDetailRow("Total", "Rp ${order.total.toStringAsFixed(2)}"),
                  if (order.trackingNumber != null)
                    _buildDetailRow("Tracking Number", order.trackingNumber!),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Items card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Order Items",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: order.items.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = order.items[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            // Product image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: item.imageUrl != null
                                  ? Image.network(
                                item.imageUrl!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.image, color: Colors.grey),
                                  );
                                },
                              )
                                  : Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[200],
                                child: const Icon(Icons.image, color: Colors.grey),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Product details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Quantity: ${item.quantity}",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Price
                            Text(
                              "Rp ${item.price.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManageOrderTab(Order order) {
    // Check if order is in final status
    final isFinalStatus = order.status == 'delivered' || order.status == 'cancelled';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Update tracking number card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Tracking Number",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _trackingController,
                    enabled: !isFinalStatus, // Disable if order is in final status
                    decoration: InputDecoration(
                      hintText: "Enter tracking number",
                      border: const OutlineInputBorder(),
                      enabledBorder: isFinalStatus
                          ? OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isFinalStatus ? null : () => _updateTrackingNumber(order.id),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text("Update Tracking Number"),
                    ),
                  ),
                  if (isFinalStatus)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "Cannot update tracking number for ${order.status} orders",
                        style: TextStyle(
                          color: Colors.red.shade400,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Update status card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Order Status",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: order.status,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      enabledBorder: isFinalStatus
                          ? OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            )
                          : null,
                    ),
                    items: _getAvailableStatuses(order.status).map<DropdownMenuItem<String>>((status) {
                      return DropdownMenuItem<String>(
                        value: status['value']!,
                        child: Text(status['label']!),
                      );
                    }).toList(),
                    onChanged: isFinalStatus 
                        ? null 
                        : (String? value) {
                            if (value != null) {
                              _updateOrderStatus(order.id, value);
                            }
                          },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isFinalStatus
                        ? "This order is ${order.status} and cannot be modified."
                        : "Note: Changing the status will notify the customer.",
                    style: TextStyle(
                      color: isFinalStatus ? Colors.red.shade400 : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu Pembayaran';
      case 'processing':
        return 'Sedang Diproses';
      case 'shipped':
        return 'Dikirim';
      case 'delivered':
        return 'Terkirim';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  // Function to check if status transition is valid
  bool _isValidStatusTransition(String currentStatus, String newStatus) {
    final validTransitions = {
      'pending': ['processing', 'cancelled'],
      'processing': ['shipped', 'cancelled'],
      'shipped': ['delivered', 'cancelled'],
      'delivered': [], // Final status
      'cancelled': [], // Final status
    };

    return validTransitions[currentStatus]?.contains(newStatus) ?? false;
  }

  // Function to get available statuses for dropdown
  List<Map<String, String>> _getAvailableStatuses(String currentStatus) {
    final allStatuses = [
      {'value': 'pending', 'label': 'Menunggu Pembayaran'},
      {'value': 'processing', 'label': 'Sedang Diproses'},
      {'value': 'shipped', 'label': 'Dikirim'},
      {'value': 'delivered', 'label': 'Terkirim'},
      {'value': 'cancelled', 'label': 'Dibatalkan'},
    ];

    // Return all statuses if current status is final
    if (currentStatus == 'delivered' || currentStatus == 'cancelled') {
      return allStatuses.where((status) => status['value'] == currentStatus).toList();
    }

    // Return current status + valid transitions
    return allStatuses.where((status) {
      return status['value'] == currentStatus ||
          _isValidStatusTransition(currentStatus, status['value']!);
    }).toList();
  }
}