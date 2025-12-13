import 'package:sqflite/sqflite.dart';
import '../db/app_database.dart';
import '../../models/promo.dart';

class PromoDao {
  static final PromoDao instance = PromoDao._internal();
  PromoDao._internal();

  Future<Database> get _db async => await AppDatabase.instance.database;

  Future<String> insert(Promo promo) async {
    final db = await _db;
    await db.insert('promo', promo.toMap());
    return promo.id;
  }

  Future<List<Promo>> getAll() async {
    final db = await _db;
    final result = await db.query('promo', orderBy: 'createdAt DESC');
    return result.map((e) => Promo.fromMap(e)).toList();
  }

  Future<Promo?> getById(String id) async {
    final db = await _db;
    final result = await db.query('promo', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? Promo.fromMap(result.first) : null;
  }

  Future<List<Promo>> getActive() async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    final result = await db.query(
      'promo',
      where: 'start <= ? AND end >= ?',
      whereArgs: [now, now],
      orderBy: 'createdAt DESC',
    );
    return result.map((e) => Promo.fromMap(e)).toList();
  }

  Future<List<Promo>> getByType(String type) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    final result = await db.query(
      'promo',
      where: 'type = ? AND start <= ? AND end >= ?',
      whereArgs: [type, now, now],
      orderBy: 'createdAt DESC',
    );
    return result.map((e) => Promo.fromMap(e)).toList();
  }

  Future<int> update(Promo promo) async {
    final db = await _db;
    return await db.update(
      'promo',
      {
        ...promo.toMap(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [promo.id],
    );
  }

  Future<int> delete(String id) async {
    final db = await _db;
    return await db.delete('promo', where: 'id = ?', whereArgs: [id]);
  }
  Future<void> deleteAll() async {
    final db = await _db;
    await db.delete('promo');
  }
}