import 'package:sqflite/sqflite.dart';
import '../../../data/db/app_database.dart';
import '../../models/product.dart';

class ProductDao {
  final Database db;

  ProductDao(this.db);

  Future<int> insert(Product product) async {
    return await db.insert('products', product.toMap());
  }

  Future<List<Product>> getAll() async {
    final results = await db.query('products');
    return results.map((e) => Product.fromMap(e)).toList();
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
