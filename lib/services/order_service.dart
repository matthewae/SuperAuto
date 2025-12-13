import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../models/order.dart';
import '../data/dao/order_dao.dart';

class OrderService {
  final sb.SupabaseClient client;
  final OrderDao orderDao;
  final Uuid _uuid = const Uuid();

  OrderService({required this.client, required this.orderDao});

  // Create a new order in Supabase and cache it locally
  Future<Order> createOrder({
    required String userId,
    required String userName,
    required List<OrderItem> items,
    required double total,
    required String paymentMethod,
    String? shippingMethod,
    String? shippingAddress,
  }) async {
    try {
      // Generate a unique ID for order using UUID
      final orderId = _uuid.v4();

      print('Creating order with ID: $orderId for user: $userId');

      // Create the order in Supabase
      final orderData = {
        'id': orderId,
        'user_id': userId,
        'username': userName, // Make sure userName is not null
        'total': total,
        'status': 'pending',
        'payment_method': paymentMethod,
        'shipping_method': shippingMethod,
        'shipping_address': shippingAddress,
        'created_at': DateTime.now().toIso8601String(),
      };

      print('Creating order with data: $orderData');

      final orderResponse = await client.from('orders').insert(orderData).select();
      final orderMap = orderResponse.first;

      print('Order created in Supabase: $orderMap');

      // Create order items in Supabase with unique IDs
      final List<Map<String, dynamic>> itemsData = items.map((item) => {
        'id': _uuid.v4(), // Generate unique ID for each order item
        'order_id': orderId,
        'product_id': item.productId,
        'product_name': item.productName,
        'price': item.price,
        'quantity': item.quantity,
        'image_url': item.imageUrl,
      }).toList();

      print('Creating order items: $itemsData');

      await client.from('order_items').insert(itemsData);

      // Create OrderItem objects with proper IDs
      final orderItems = itemsData.asMap().entries.map((entry) {
        final index = entry.key;
        final itemData = entry.value;
        final originalItem = items[index];

        return OrderItem(
          id: itemData['id'],
          orderId: orderId,
          productId: originalItem.productId,
          productName: originalItem.productName,
          price: originalItem.price,
          quantity: originalItem.quantity,
          imageUrl: originalItem.imageUrl,
        );
      }).toList();

      // Use factory fromMap to create Order object
      final order = Order.fromMap(orderMap, items: orderItems);

      print('Order object created: ${order.toMap()}');

      // Cache the order locally with error handling
      try {
        await orderDao.insert(order);
      } catch (e) {
        print('Error caching order locally: $e');
        // Continue even if caching fails
      }

      return order;
    } catch (e) {
      print('Error creating order: $e');
      rethrow;
    }
  }

  // Fetch orders from Supabase and cache them locally
  Future<List<Order>> fetchAndCacheOrders(String userId) async {
    try {
      print('Fetching orders for user: $userId');

      final response = await client
          .from('orders')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      print('Orders response from Supabase (${response.length} orders): $response');

      if (response.isEmpty) return [];

      final orderIds = response.map((order) => order['id'] as String).toList();

      final itemsResponse = await client
          .from('order_items')
          .select()
          .inFilter('order_id', orderIds);

      print('Order items response (${itemsResponse.length} items): $itemsResponse');

      // Group items by orderId
      final Map<String, List<Map<String, dynamic>>> itemsByOrderId = {};
      for (final item in itemsResponse) {
        final orderId = item['order_id'] as String;
        itemsByOrderId.putIfAbsent(orderId, () => []).add(item);
      }

      // Build orders - PASTIKAN TIDAK DUPLIKAT
      final List<Order> orders = [];
      final Set<String> seenIds = {}; // ← Tambah ini untuk anti duplikat

      for (final orderMap in response) {
        final orderId = orderMap['id'] as String;

        if (seenIds.contains(orderId)) {
          print('Skipping duplicate order from Supabase response: $orderId');
          continue; // Skip kalau sudah ada
        }

        seenIds.add(orderId);

        final itemsData = itemsByOrderId[orderId] ?? [];
        final items = itemsData.map((itemMap) => OrderItem.fromMap(itemMap)).toList();

        orders.add(Order.fromMap(orderMap, items: items));
      }

      print('Final unique orders list: ${orders.length} orders');

      // Cache semua (DAO sudah aman skip duplikat)
      for (final order in orders) {
        await orderDao.insert(order);
      }

      return orders;
    } catch (e) {
      print('Error fetching orders: $e');
      rethrow;
    }
  }

  // Update order status in Supabase and cache
  Future<Order> updateOrderStatus(String orderId, String status) async {
    try {
      final response = await client
          .from('orders')
          .update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', orderId)
          .select();

      if (response.isEmpty) {
        throw Exception('Order not found');
      }

      final orderMap = response.first;

      // Get the cached order to preserve items
      final cachedOrder = await orderDao.getById(orderId);
      if (cachedOrder == null) {
        throw Exception('Cached order not found');
      }

      // Use copyWith to update status
      final updatedOrder = cachedOrder.copyWith(
        status: status,
        updatedAt: DateTime.now(),
      );

      // Update the cache with error handling
      try {
        await orderDao.update(updatedOrder);
      } catch (e) {
        print('Error updating order locally: $e');
        // Continue even if updating fails
      }

      return updatedOrder;
    } catch (e) {
      print('Error updating order status: $e');
      rethrow;
    }
  }

  // Update tracking number in Supabase and cache
  Future<Order> updateTrackingNumber(String orderId, String trackingNumber) async {
    try {
      final response = await client
          .from('orders')
          .update({
        'tracking_number': trackingNumber,
        'status': 'shipped',
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', orderId)
          .select();

      if (response.isEmpty) {
        throw Exception('Order not found');
      }

      final orderMap = response.first;

      // Get the cached order to preserve items
      final cachedOrder = await orderDao.getById(orderId);
      if (cachedOrder == null) {
        throw Exception('Cached order not found');
      }

      // Use copyWith to update
      final updatedOrder = cachedOrder.copyWith(
        trackingNumber: trackingNumber,
        status: 'shipped',
        updatedAt: DateTime.now(),
      );

      // Update the cache with error handling
      try {
        await orderDao.update(updatedOrder);
      } catch (e) {
        print('Error updating order locally: $e');
        // Continue even if updating fails
      }

      return updatedOrder;
    } catch (e) {
      print('Error updating tracking number: $e');
      rethrow;
    }
  }

  // Get cached orders for offline access
  Future<List<Order>> getCachedOrders(String userId) async {
    return await orderDao.getByUserId(userId);
  }

  // Get a specific cached order
  Future<Order?> getCachedOrder(String orderId) async {
    return await orderDao.getById(orderId);
  }
}