
import '../../../data/db/app_database.dart';
import '../../models/car.dart';
import 'package:sqflite/sqflite.dart';

class CarDao {
  final Database db;
  CarDao(this.db);

  Future<void> cacheCar(Car car) async {
    print('Caching car: ${car.toMap()}');
    await db.insert(
      'cars',
      car.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Car>> getCachedCarsByUserId(String userId) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'cars',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return List.generate(maps.length, (i) {
      return Car.fromMap(maps[i]);
    });
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

  Future<void> clearCacheForUser(String userId) async {
    await db.delete(
      'cars',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  Future<void> updateMainCarStatusInCache(String userId, String carId) async {
    await db.transaction((txn) async {
      await txn.update(
        'cars',
        {'isMain': 0},
        where: 'userId = ?',
        whereArgs: [userId],
      );


      await txn.update(
        'cars',
        {'isMain': 1},
        where: 'id = ? AND userId = ?',
        whereArgs: [carId, userId],
      );
    });
  }

  Future<List<Car>> getAll() async {
    final results = await db.query('cars');
    return results.map((e) => Car.fromMap(e)).toList();
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
}