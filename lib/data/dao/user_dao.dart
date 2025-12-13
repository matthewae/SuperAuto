import 'package:sqflite/sqflite.dart';
import '../../models/user.dart';

class UserDao {
  final Database db;
  UserDao(this.db);

  Future<void> cacheUser(User user) async {
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<User?> getCachedUser() async {
    final result = await db.query('users', limit: 1);
    if (result.isEmpty) return null;
    return User.fromMap(result.first);
  }

  Future<void> updateCache(User user) async {
    await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<void> clearCache() async {
    await db.delete('users');
  }
}
