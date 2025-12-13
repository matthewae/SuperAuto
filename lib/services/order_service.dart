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
      final orderId = _uuid.v4();

      print('Creating order with ID: $orderId for user: $userId');

      final orderData = {
        'id': orderId,
        'user_id': userId,
        'username': userName,
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

      final List<Map<String, dynamic>> itemsData = items.map((item) => {
        'id': _uuid.v4(),
        'order_id': orderId,
        'product_id': item.productId,
        'product_name': item.productName,
        'price': item.price,
        'quantity': item.quantity,
        'image_url': item.imageUrl,
      }).toList();

      print('Creating order items: $itemsData');

      await client.from('order_items').insert(itemsData);

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

      final order = Order.fromMap(orderMap, items: orderItems);

      print('Order object created: ${order.toMap()}');

      try {
        await orderDao.insert(order);
      } catch (e) {
        print('Error caching order locally: $e');
      }

      return order;
    } catch (e) {
      print('Error creating order: $e');
      rethrow;
    }
  }

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

      final Map<String, List<Map<String, dynamic>>> itemsByOrderId = {};
      for (final item in itemsResponse) {
        final orderId = item['order_id'] as String;
        itemsByOrderId.putIfAbsent(orderId, () => []).add(item);
      }

      final List<Order> orders = [];
      final Set<String> seenIds = {};

      for (final orderMap in response) {
        final orderId = orderMap['id'] as String;

        if (seenIds.contains(orderId)) {
          print('Skipping duplicate order from Supabase response: $orderId');
          continue;
        }

        seenIds.add(orderId);

        final itemsData = itemsByOrderId[orderId] ?? [];
        final items = itemsData.map((itemMap) => OrderItem.fromMap(itemMap)).toList();

        orders.add(Order.fromMap(orderMap, items: items));
      }

      print('Final unique orders list: ${orders.length} orders');

      for (final order in orders) {
        await orderDao.insert(order);
      }

      return orders;
    } catch (e) {
      print('Error fetching orders: $e');
      rethrow;
    }
  }

  Future<Order> updateOrderStatus(String orderId, String status) async {
    try {
      print('🔄 [OrderService] Memperbarui status order: $orderId menjadi $status');

      final updateData = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      print('📤 [OrderService] Mengirim data pembaruan: $updateData');

      final response = await client
          .from('orders')
          .update(updateData)
          .eq('id', orderId)
          .select();

      if (response.isEmpty) {
        throw Exception('Order dengan ID $orderId tidak ditemukan atau pembaruan gagal.');
      }

      final orderMap = response.first;
      print('✅ [OrderService] Respon Supabase setelah pembaruan: $orderMap');

      final cachedOrder = await orderDao.getById(orderId);
      if (cachedOrder == null) {
        print('⚠️ [OrderService] Order tidak ditemukan di cache, mengambil ulang dari Supabase.');
        return await getOrderById(orderId);
      }

      final updatedOrder = cachedOrder.copyWith(
        status: status,
        updatedAt: DateTime.now(),
      );

      try {
        await orderDao.update(updatedOrder);
        print('✅ [OrderService] Cache lokal diperbarui.');
      } catch (e) {
        print('⚠️ [OrderService] Error memperbarui cache lokal: $e');
      }

      return updatedOrder;
    } catch (e) {
      print('❌ [OrderService] Error memperbarui status order: $e');
      rethrow;
    }
  }

  Future<Order> updateTrackingNumber(String orderId, String trackingNumber) async {
    try {
      print('🔄 [OrderService] Memperbarui nomor lacak order: $orderId menjadi $trackingNumber');

      final updateData = {
        'tracking_number': trackingNumber,
        'status': 'shipped',
        'updated_at': DateTime.now().toIso8601String(),
      };

      print('📤 [OrderService] Mengirim data pembaruan: $updateData');

      final response = await client
          .from('orders')
          .update(updateData)
          .eq('id', orderId)
          .select();

      if (response.isEmpty) {
        throw Exception('Order dengan ID $orderId tidak ditemukan atau pembaruan gagal.');
      }

      final orderMap = response.first;
      print('✅ [OrderService] Respon Supabase setelah pembaruan: $orderMap');

      final cachedOrder = await orderDao.getById(orderId);
      if (cachedOrder == null) {
        print('⚠️ [OrderService] Order tidak ditemukan di cache, mengambil ulang dari Supabase.');
        return await getOrderById(orderId);
      }

      final updatedOrder = cachedOrder.copyWith(
        trackingNumber: trackingNumber,
        status: 'shipped',
        updatedAt: DateTime.now(),
      );

      try {
        await orderDao.update(updatedOrder);
        print('✅ [OrderService] Cache lokal diperbarui.');
      } catch (e) {
        print('⚠️ [OrderService] Error memperbarui cache lokal: $e');
      }

      return updatedOrder;
    } catch (e) {
      print('❌ [OrderService] Error memperbarui nomor lacak: $e');
      rethrow;
    }
  }

  Future<List<Order>> getCachedOrders(String userId) async {
    return await orderDao.getByUserId(userId);
  }

  Future<Order?> getCachedOrder(String orderId) async {
    return await orderDao.getById(orderId);
  }

  Future<Order> getOrderById(String orderId) async {
    try {
      print('🔍 [OrderService] Mengambil satu order dari Supabase: $orderId');

      final orderResponse = await client
          .from('orders')
          .select()
          .eq('id', orderId)
          .single();

      print('✅ [OrderService] Data order diterima: $orderResponse');

      final itemsResponse = await client
          .from('order_items')
          .select()
          .eq('order_id', orderId);

      print('✅ [OrderService] Data item order diterima: $itemsResponse');

      final items = itemsResponse.map((itemMap) => OrderItem.fromMap(itemMap)).toList();
      final order = Order.fromMap(orderResponse, items: items);

      await orderDao.insert(order);

      return order;
    } catch (e) {
      print('❌ [OrderService] Error mengambil order $orderId dari Supabase: $e');
      rethrow;
    }
  }

}