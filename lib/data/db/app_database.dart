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
     CREATE TABLE IF NOT EXISTS cars (
  id TEXT PRIMARY KEY,
  brand TEXT NOT NULL,
  model TEXT NOT NULL,
  year INTEGER NOT NULL,
  plateNumber TEXT NOT NULL,
  vin TEXT NOT NULL,
  engineNumber TEXT NOT NULL,
  initialKm INTEGER NOT NULL,
  userId INTEGER NOT NULL,
  isMain INTEGER NOT NULL DEFAULT 0,
  createdAt TEXT,
  updatedAt TEXT,
  FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
)
    ''');

    await db.execute('''
  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    name TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'user'
  )
  ''');


    await db.execute('''
      CREATE TABLE IF NOT EXISTS products (
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
      CREATE TABLE IF NOT EXISTS orders (
        id TEXT PRIMARY KEY,
        userId TEXT,
        productId TEXT,
        createdAt TEXT
      );
    ''');

    await db.execute('''
  CREATE TABLE IF NOT EXISTS service_bookings (
    id TEXT PRIMARY KEY,
    userId TEXT NOT NULL,
    carId TEXT NOT NULL,
    serviceType TEXT NOT NULL,
    scheduledAt TEXT NOT NULL,
    estimatedCost REAL NOT NULL,
    status TEXT NOT NULL,
    workshop TEXT,
    notes TEXT,
    serviceDetails TEXT,
    mechanicName TEXT,
    isPickupService INTEGER NOT NULL DEFAULT 0,
    serviceLocation TEXT,
    adminNotes TEXT,
    statusHistory TEXT,
    createdAt TEXT NOT NULL,
    updatedAt TEXT,
    FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (carId) REFERENCES cars(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS promo (
        id TEXT PRIMARY KEY,
        title TEXT,
        description TEXT,
        discount REAL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS cart (
        id TEXT PRIMARY KEY,
        productId TEXT,
        qty INTEGER
      );
    ''');
  }
}
