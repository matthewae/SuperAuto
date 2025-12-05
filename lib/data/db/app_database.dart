import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _db;

  AppDatabase._init();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB('superauto.db');
    return _db!;
  }

  Future<Database> _initDB(String file) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, file);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cars (
      id TEXT PRIMARY KEY,
      brand TEXT,
      model TEXT,
      year INTEGER,
      plateNumber TEXT,
      vin TEXT,
      engineNumber TEXT,
      initialKm INTEGER
    );
    ''');

    await db.execute('''
  CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    name TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'user'
  )
  ''');


    await db.execute('''
      CREATE TABLE products (
      id TEXT PRIMARY KEY,
      name TEXT,
      category TEXT,
      description TEXT,
      price REAL,
      imageUrl TEXT,
      compatibleModels TEXT
    );
    ''');

    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        userId TEXT,
        productId TEXT,
        createdAt TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE service_bookings (
        id TEXT PRIMARY KEY,
        carId TEXT,
        date TEXT,
        description TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE promo (
        id TEXT PRIMARY KEY,
        title TEXT,
        description TEXT,
        discount REAL
      );
    ''');

    await db.execute('''
      CREATE TABLE cart (
        id TEXT PRIMARY KEY,
        productId TEXT,
        qty INTEGER
      );
    ''');
  }
}
