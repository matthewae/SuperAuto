import 'package:sqflite/sqflite.dart';
import '../../../data/db/app_database.dart';
import '../../models/product.dart';

class ProductDao {
  final Database db;

  ProductDao(this.db);

  // In lib/data/dao/product_dao.dart
  Future<int> insert(Product product) async {
    try {
      final map = product.toMap();
      print('Inserting product: $map');
      final id = await db.insert('products', map);
      print('Product inserted with ID: $id');
      return id;
    } catch (e) {
      print('Error inserting product: $e');
      rethrow;
    }
  }

  // In lib/data/dao/product_dao.dart
  Future<List<Product>> getAll() async {
    try {
      final results = await db.query('products');
      return results.map((e) {
        try {
          return Product.fromMap(e);
        } catch (e) {
          print('Error parsing product: $e');
          print('Problematic data: $e');
          rethrow;
        }
      }).toList();
    } catch (e) {
      print('Error in ProductDao.getAll(): $e');
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
}
