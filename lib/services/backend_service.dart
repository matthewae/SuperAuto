import 'package:supabase_flutter/supabase_flutter.dart';

abstract class BackendService {
  Future<void> upsertUser(Map<String, dynamic> user);
  Future<void> upsertCar(Map<String, dynamic> car);
  Future<void> upsertServiceBooking(Map<String, dynamic> booking);
  Future<void> upsertServiceHistory(Map<String, dynamic> history);
  Future<void> upsertProduct(Map<String, dynamic> product);
  Future<void> upsertCategory(Map<String, dynamic> category);
  Future<void> upsertCart(Map<String, dynamic> cart);
  Future<void> upsertOrder(Map<String, dynamic> order);
  Future<void> upsertBundling(Map<String, dynamic> bundling);
  Future<void> upsertPromo(Map<String, dynamic> promo);
  Future<void> upsertLoyalty(Map<String, dynamic> loyalty);
}

class SupabaseBackendService implements BackendService {
  final SupabaseClient client;
  SupabaseBackendService(this.client);

  @override
  Future<void> upsertUser(Map<String, dynamic> user) async {
    await client.from('users').upsert(user);
  }

  @override
  Future<void> upsertCar(Map<String, dynamic> car) async {
    await client.from('cars').upsert(car);
  }

  @override
  Future<void> upsertServiceBooking(Map<String, dynamic> booking) async {
    await client.from('service_booking').upsert(booking);
  }

  @override
  Future<void> upsertServiceHistory(Map<String, dynamic> history) async {
    await client.from('service_history').upsert(history);
  }

  @override
  Future<void> upsertProduct(Map<String, dynamic> product) async {
    await client.from('products').upsert(product);
  }

  @override
  Future<void> upsertCategory(Map<String, dynamic> category) async {
    await client.from('product_category').upsert(category);
  }

  @override
  Future<void> upsertCart(Map<String, dynamic> cart) async {
    await client.from('cart').upsert(cart);
  }

  @override
  Future<void> upsertOrder(Map<String, dynamic> order) async {
    await client.from('orders').upsert(order);
  }

  @override
  Future<void> upsertBundling(Map<String, dynamic> bundling) async {
    await client.from('bundlings').upsert(bundling);
  }

  @override
  Future<void> upsertPromo(Map<String, dynamic> promo) async {
    await client.from('promos').upsert(promo);
  }

  @override
  Future<void> upsertLoyalty(Map<String, dynamic> loyalty) async {
    await client.from('loyalty_points').upsert(loyalty);
  }
}

