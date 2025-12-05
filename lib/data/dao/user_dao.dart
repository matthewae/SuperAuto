import 'package:sqflite/sqflite.dart';
import '../db/app_database.dart';
import '../../models/user.dart';

class UserDao {
  Future<int> insertUser(User user) async {
    final db = await AppDatabase.instance.database;
    return await db.insert('users', user.toMap());
  }

  Future<User?> login(String email, String password) async {
    final db = await AppDatabase.instance.database;

    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (result.isNotEmpty) {
      return User.fromMap(result.first);
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
}
