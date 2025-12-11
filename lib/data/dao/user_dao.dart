import '../db/app_database.dart';
import '../../models/user.dart';
import 'package:sqflite/sqflite.dart';

class UserDao {
  final Database db;

  UserDao(this.db);

  // In UserDao class
  Future<String> insertUser(User user) async {
    final db = await AppDatabase.instance.database;
    await db.insert('users', user.toMap());
    return user.id;
  }

  Future<User?> login(String email, String password) async {
    final db = await AppDatabase.instance.database;
    final results = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (results.isNotEmpty) {
      return User.fromMap(results.first);
    }
    return null;
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await AppDatabase.instance.database;

    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }

    return null;
  }

  Future<User?> getUserById(String id) async {
    final db = await AppDatabase.instance.database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? User.fromMap(results.first) : null;
  }

  // Tambahkan metode update untuk memperbarui data pengguna
  Future<User> updateUser(User user) async {
    final db = await AppDatabase.instance.database;

    // Buat map baru dengan updatedAt yang diperbarui
    final userMap = user.toMap();
    userMap['updatedAt'] = DateTime.now().toIso8601String();

    await db.update(
      'users',
      userMap,
      where: 'id = ?',
      whereArgs: [user.id],
    );

    // Kembalikan user yang sudah diperbarui dengan updatedAt baru
    return user.copyWith(updatedAt: DateTime.now());
  }

  // Tambahkan metode untuk verifikasi password
  Future<bool> verifyPassword(String userId, String password) async {
    final db = await AppDatabase.instance.database;
    final results = await db.query(
      'users',
      where: 'id = ? AND password = ?',
      whereArgs: [userId, password],
    );
    return results.isNotEmpty;
  }

  Future<void> listAllUsers() async {
    final db = await AppDatabase.instance.database;
    final users = await db.query('users');
    print('👥 All users in database:');
    for (var user in users) {
      print('  - ID: ${user['id']}, Email: ${user['email']}, Name: ${user['name']}');
    }
  }
}