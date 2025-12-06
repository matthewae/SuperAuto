import '../../../data/db/app_database.dart';
import '../../models/car.dart';

class CarDao {
  Future<void> insert(Car car) async {
    final db = await AppDatabase.instance.database;
    print('Inserting car: ${car.toMap()}');  // Add this line to log the car being inserted
    await db.insert('cars', car.toMap());
  }

  Future<List<Car>> getAll() async {
    final db = await AppDatabase.instance.database;
    final results = await db.query('cars');  // This would get all cars
    return results.map((e) => Car.fromMap(e)).toList();
  }

  // In CarDao class
  Future<List<Car>> getByUserId(int userId) async {
    print('🔍 Getting cars for user ID: $userId (type: ${userId.runtimeType})');
    final db = await AppDatabase.instance.database;

    // Log all cars in the database for debugging
    final allCars = await db.query('cars');
    print('📋 All cars in database:');
    for (var car in allCars) {
      print('  - ID: ${car['id']}, Brand: ${car['brand']}, UserID: ${car['userId']} (type: ${car['userId']?.runtimeType})');
    }

    final results = await db.query(
      'cars',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    print('✅ Found ${results.length} cars for user $userId');
    return results.map((e) => Car.fromMap(e)).toList();
  }

  Future<void> checkTableSchema() async {
    final db = await AppDatabase.instance.database;
    final tableInfo = await db.rawQuery('PRAGMA table_info(cars)');
    print('📊 Cars table schema:');
    for (var column in tableInfo) {
      print('  - ${column['name']}: ${column['type']} ${column['pk'] == 1 ? 'PRIMARY KEY' : ''}');
    }
  }

  Future<Car?> getById(int id) async {
    final db = await AppDatabase.instance.database;
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
    final db = await AppDatabase.instance.database;
    return await db.update(
      'cars',
      car.toMap(),
      where: 'id = ?',
      whereArgs: [car.id],
    );
  }

  // Delete a car
  Future<int> delete(String id) async {
    final db = await AppDatabase.instance.database;
    return await db.delete(
      'cars',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}