// lib/services/promo_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/dao/promo_dao.dart';
import '../models/promo.dart';

class PromoService {
  final SupabaseClient client;
  final PromoDao promoDao;

  PromoService({required this.client, required this.promoDao});

  // Mengambil SEMUA promo dari Supabase dan menyinkronkannya ke SQLite
  Future<List<Promo>> fetchAndCachePromos() async {
    try {
      final response = await client
          .from('promo')
          .select()
          .order('created_at', ascending: false);

      final List<Promo> promos = (response as List)
          .map((promoJson) => _mapSupabaseToPromo(promoJson))
          .toList();

      // Bersihkan cache lama dan simpan semua promo yang diambil ke cache lokal
      await promoDao.deleteAll(); // Anda perlu menambahkan metode deleteAll di PromoDao
      for (final promo in promos) {
        await promoDao.insert(promo);
      }

      return promos;
    } catch (e) {
      print('Error fetching promos from Supabase: $e');
      rethrow;
    }
  }

  // Menambahkan promo baru ke Supabase dan cache
  Future<Promo> addPromo(Promo promo) async {
    try {
      final response = await client
          .from('promo')
          .insert(_mapPromoToSupabase(promo))
          .select()
          .single();

      final newPromo = _mapSupabaseToPromo(response);
      await promoDao.insert(newPromo);

      return newPromo;
    } catch (e) {
      print('Error adding promo to Supabase: $e');
      rethrow;
    }
  }

  // Mengupdate promo di Supabase dan cache
  Future<Promo> updatePromo(Promo promo) async {
    try {
      final response = await client
          .from('promo')
          .update(_mapPromoToSupabase(promo))
          .eq('id', promo.id)
          .select()
          .single();

      final updatedPromo = _mapSupabaseToPromo(response);
      await promoDao.update(updatedPromo);

      return updatedPromo;
    } catch (e) {
      print('Error updating promo in Supabase: $e');
      rethrow;
    }
  }

  // Menghapus promo dari Supabase dan cache
  Future<void> deletePromo(String promoId) async {
    try {
      await client.from('promo').delete().eq('id', promoId);
      await promoDao.delete(promoId);
    } catch (e) {
      print('Error deleting promo from Supabase: $e');
      rethrow;
    }
  }

  Future<List<Promo>> getActivePromos() async {
    try {
      return await promoDao.getActive();
    } catch (e) {
      print('Error getting active promos from cache: $e');
      return [];
    }
  }

  Future<List<Promo>> getPromosByType(String type) async {
    try {
      return await promoDao.getByType(type);
    } catch (e) {
      print('Error getting promos by type from cache: $e');
      return [];
    }
  }

  Future<Promo?> getPromoById(String id) async {
    final res = await client
        .from('promo')
        .select()
        .eq('id', id)
        .maybeSingle();

    return res == null ? null : Promo.fromMap(res);
  }
  // --- Helper Functions ---

  Map<String, dynamic> _mapPromoToSupabase(Promo promo) {
    return {
      'id': promo.id,
      'name': promo.name,
      'type': promo.type,
      'value': promo.value,
      'start': promo.start.toIso8601String(),
      'end': promo.end.toIso8601String(),
      'image_url': promo.imageUrl,
    };
  }

  Promo _mapSupabaseToPromo(Map<String, dynamic> json) {
    return Promo(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      value: (json['value'] as num).toDouble(),

      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),

      // 🔥 SAFE PARSE (INI FIX UTAMA)
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),

      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,

      imageUrl: json['image_url'] as String?,
    );
  }

}