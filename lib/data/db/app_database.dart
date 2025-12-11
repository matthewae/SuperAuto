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
  userId TEXT NOT NULL,
  isMain INTEGER NOT NULL DEFAULT 0,
  createdAt TEXT,
  updatedAt TEXT,
  FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
)
    ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    name TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'user',
    createdAt TEXT,
    updatedAt TEXT
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
    jobs TEXT,
    parts TEXT,
    km INTEGER,
    totalCost REAL,
    createdAt TEXT NOT NULL,
    updatedAt TEXT,
    FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (carId) REFERENCES cars(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS service_history (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        carId TEXT NOT NULL,
        date TEXT NOT NULL,
        km INTEGER NOT NULL,
        jobs TEXT NOT NULL,
        parts TEXT NOT NULL,
        totalCost REAL NOT NULL,
        serviceType TEXT,
        notes TEXT,
        createdAt TEXT NOT NULL
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
  CREATE TABLE IF NOT EXISTS cart_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    userId TEXT NOT NULL,
    productId TEXT NOT NULL,
    productName TEXT NOT NULL,
    quantity INTEGER NOT NULL,
    price REAL NOT NULL,
    imageUrl TEXT,
    createdAt TEXT NOT NULL,
    updatedAt TEXT,
    UNIQUE(userId, productId)
  )
''');
    await db.execute('''
  CREATE TABLE IF NOT EXISTS order_items (
  id TEXT PRIMARY KEY,
  orderId TEXT NOT NULL,
  productId TEXT NOT NULL,
  productName TEXT NOT NULL,
  price REAL NOT NULL,
  quantity INTEGER NOT NULL,
  imageUrl TEXT,
  FOREIGN KEY (orderId) REFERENCES orders (id) ON DELETE CASCADE,
  FOREIGN KEY (productId) REFERENCES products (id) ON DELETE CASCADE
  )
''');

    await db.execute('''
  CREATE TABLE IF NOT EXISTS orders (
     id TEXT PRIMARY KEY,
     userId TEXT NOT NULL,
     userName TEXT,
     total REAL NOT NULL,
     status TEXT NOT NULL,
     trackingNumber TEXT,
     shippingMethod TEXT,
     shippingAddress TEXT,
     paymentMethod TEXT,
     createdAt TEXT NOT NULL,
     updatedAt TEXT,
     FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
  )
''');
  }
}
