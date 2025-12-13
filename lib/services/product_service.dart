import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/dao/product_dao.dart';
import '../models/product.dart';
import '../models/enums.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';


class ProductService {
  final SupabaseClient client;
  final ProductDao productDao;
  final Uuid _uuid = const Uuid();

  ProductService({required this.client, required this.productDao});

  Future<List<Product>> fetchAndCacheProducts() async {
    try {
      final response = await client
          .from('products')
          .select();

      final List<Product> products = (response as List)
          .map((productJson) => _mapSupabaseToProduct(productJson))
          .toList();

      await _clearAndRecacheProducts(products);

      return products;
    } catch (e) {
      print('Error fetching products from Supabase: $e');
      rethrow;
    }
  }

  // Helper untuk membersihkan dan menyimpan ulang cache produk
  Future<void> _clearAndRecacheProducts(List<Product> products) async {
    // Opsi 1: Hapus semua lalu insert ulang (lebih aman untuk sinkronisasi penuh)
    await productDao.deleteAll(); // Anda perlu menambahkan metode deleteAll di ProductDao
    for (final product in products) {
      await productDao.insert(product);
    }
  }

  Future<Product> addProduct(Product product) async {
    try {
      final response = await client
          .from('products')
          .insert(_mapProductToSupabase(product))
          .select()
          .single();

      final newProduct = _mapSupabaseToProduct(response);

      await productDao.insert(newProduct);

      return newProduct;
    } catch (e) {
      print('Error adding product to Supabase: $e');
      rethrow;
    }
  }

  Future<Product> updateProduct(Product product) async {
    try {
      final response = await client
          .from('products')
          .update(_mapProductToSupabase(product))
          .eq('id', product.id)
          .select()
          .single();

      final updatedProduct = _mapSupabaseToProduct(response);

      // Update cache lokal
      await productDao.update(updatedProduct);

      return updatedProduct;
    } catch (e) {
      print('Error updating product in Supabase: $e');
      rethrow;
    }
  }

  // Menghapus produk dari Supabase dan cache
  Future<void> deleteProduct(String productId) async {
    try {
      await client.from('products').delete().eq('id', productId);

      // Hapus juga dari cache lokal
      await productDao.delete(productId);
    } catch (e) {
      print('Error deleting product from Supabase: $e');
      rethrow;
    }
  }

  // Helper: Mapping dari model Product (camelCase) ke Map untuk Supabase (snake_case)
  // Helper: Mapping dari model Product (camelCase) ke Map untuk Supabase (snake_case)
  Map<String, dynamic> _mapProductToSupabase(Product product) {
    return {
      'id': product.id.isNotEmpty ? product.id : _uuid.v4(),
      'name': product.name,
      'category': product.category.nameStr,
      'description': product.description,
      'price': product.price,
      'image_url': product.imageUrl,
      'compatible_models': jsonEncode(product.compatibleModels),
    };
  }

  // Helper: Mapping dari JSON Supabase ke model Product
  Product _mapSupabaseToProduct(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: ProductCategoryExt.fromString(json['category']?.toString() ?? ''),
      description: json['description']?.toString() ?? '',
      price: (json['price'] is int)
          ? (json['price'] as int).toDouble()
          : (json['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['image_url'] as String?,
      compatibleModels: json['compatible_models'] != null
          ? List<String>.from(jsonDecode(json['compatible_models'] as String))
          : <String>[],
    );
  }
}