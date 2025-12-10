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
    final List<Map<String, dynamic>> maps = await db.query(
      'cars',
      where: 'userId = ?',
      whereArgs: [userId],  // Use userId as String
    );

    return List.generate(maps.length, (i) {
      return Car.fromMap(maps[i]);
    });
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
  /// Sets a car as the main car for a user.
  /// This will automatically unset any other main car for the same user.
  /// Sets a car as the main car for a user.
  /// This will automatically unset any other main car for the same user.
  Future<void> setMainCar(String userId, String carId) async {
    // Use a transaction to ensure both updates succeed or fail together
    await db.transaction((txn) async {
      // 1. Reset the 'isMain' flag for ALL cars belonging to the user
      await txn.update(
        'cars',
        {'isMain': 0},
        where: 'userId = ?',
        whereArgs: [userId],  // Use userId as String
      );

      // 2. Set the new main car for the user
      await txn.update(
        'cars',
        {'isMain': 1},
        where: 'id = ? AND userId = ?',
        whereArgs: [carId, userId],  // Use userId as String
      );
    });
  }

  /// Updates a car's main status.
  /// If setting as main (isMain = true), will unset any other main car for the user.
  Future<void> updateMainCarStatus(String carId, bool isMain, {String? userId}) async {
    if (isMain && userId == null) {
      throw ArgumentError('userId must be provided when setting a car as main');
    }

    await db.transaction((txn) async {
      if (isMain) {
        // If setting as main, first unset any existing main car
        await txn.update(
          'cars',
          {'isMain': 0},
          where: 'userId = ?',
          whereArgs: [userId],  // Use userId as String
        );
      }

      // Update the current car's status
      await txn.update(
        'cars',
        {'isMain': isMain ? 1 : 0},
        where: 'id = ?',
        whereArgs: [carId],
      );
    });
  }
}