import '../../../data/db/app_database.dart';
import '../../models/car.dart';
import 'package:sqflite/sqflite.dart';
class CarDao {
  final Database db;

  CarDao(this.db);
  Future<void> insert(Car car) async {
    print('Inserting car: ${car.toMap()}');
    await db.insert('cars', car.toMap());
  }

  Future<List<Car>> getAll() async {
    final results = await db.query('cars');
    return results.map((e) => Car.fromMap(e)).toList();
  }

  Future<List<Car>> getByUserId(String userId) async {
    print('Getting cars for user ID: $userId');
    final results = await db.query(
      'cars',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    print('Found ${results.length} cars for user $userId');
    return results.map((e) => Car.fromMap(e)).toList();
  }

  Future<void> checkTableSchema() async {
    final tableInfo = await db.rawQuery('PRAGMA table_info(cars)');
    print('Cars table schema:');
    for (var column in tableInfo) {
      print('  - ${column['name']}: ${column['type']} ${column['pk'] == 1 ? 'PRIMARY KEY' : ''}');
    }
  }



  Future<Car?> getById(dynamic id) async {
    final results = await db.query(
      'cars',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isNotEmpty) {
      return Car.fromMap(results.first);
    }
    return null;
  }

  Future<int> update(Car car) async {
    return await db.update(
      'cars',
      car.toMap(),
      where: 'id = ?',
      whereArgs: [car.id],
    );
  }

  Future<int> delete(String id) async {
    return await db.delete(
      'cars',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}