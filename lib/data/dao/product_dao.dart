
import 'package:sqflite/sqflite.dart';
import '../../../data/db/app_database.dart';
import '../../models/product.dart';

class ProductDao {
  final Database db;

  ProductDao(this.db);


  Future<int> insert(Product product) async {
    try {
      final map = product.toMap();
      print('Caching product: $map');
      final id = await db.insert('products', map, conflictAlgorithm: ConflictAlgorithm.replace);
      print('Product cached with ID: $id');
      return id;
    } catch (e) {
      print('Error caching product: $e');
      rethrow;
    }
  }

  Future<List<Product>> getAll() async {
    try {
      final results = await db.query('products');
      return results.map((e) {
        try {
          return Product.fromMap(e);
        } catch (e) {
          print('Error parsing product from cache: $e');
          print('Problematic data: $e');
          rethrow;
        }
      }).toList();
    } catch (e) {
      print('Error getting all products from cache: $e');
      rethrow;
    }
  }

  Future<int> update(Product product) async {
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> delete(String id) async {
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAll() async {
    try {
      print('Clearing all products from local cache...');
      await db.delete('products');
      print('Local cache cleared.');
    } catch (e) {
      print('Error clearing product cache: $e');
      rethrow;
    }
  }
}