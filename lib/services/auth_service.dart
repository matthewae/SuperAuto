
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:uuid/uuid.dart';
import '../data/dao/user_dao.dart';
import '../models/user.dart';

class AuthService {
  final sb.SupabaseClient client = sb.Supabase.instance.client;
  final UserDao userDao;

  AuthService(this.userDao);

  // SIGNUP
  Future<User?> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // 1. Try to create the user in Supabase Auth first
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'role': 'user',
        },
      ).catchError((error) {
        if (error.toString().contains('user_already_exists')) {
          // If user exists, try to sign in to check if they have a profile
          return client.auth.signInWithPassword(
            email: email,
            password: password,
          ).then((signInResponse) async {
            if (signInResponse.user != null) {
              // Check if profile exists
              final profile = await client
                  .from('profiles')
                  .select()
                  .eq('id', signInResponse.user!.id)
                  .maybeSingle();

              if (profile == null) {
                // If no profile exists, create one
                await _createUserProfile(
                  userId: signInResponse.user!.id,
                  email: email,
                  name: name,
                );
              }
              return signInResponse;
            }
            throw Exception('Gagal memeriksa akun yang ada');
          });
        }
        throw error;
      });

      if (response.user == null) {
        throw Exception('Gagal membuat akun');
      }

      // 2. Create user profile if this is a new user
      if (response.session == null) {
        // This is an existing user who just signed in
        return User(
          id: response.user!.id,
          email: email,
          name: name,
          role: 'user',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      // 3. This is a new user, create their profile
      await _createUserProfile(
        userId: response.user!.id,
        email: email,
        name: name,
      );

      return User(
        id: response.user!.id,
        email: email,
        name: name,
        role: 'user',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      print('Error during signup: $e');
      rethrow;
    }
  }

// Helper method to create user profile
  Future<void> _createUserProfile({
    required String userId,
    required String email,
    required String name,
  }) async {
    await client.from('profiles').upsert({
      'id': userId,
      'name': name,
      'role': 'user',
      'email': email,
      'username': email.split('@')[0],
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
  // LOGIN
  Future<User?> login(String email, String password) async {
    try {
      final res = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final sbUser = res.user;
      if (sbUser == null) return null;

      // Ambil data lengkap dari tabel 'profiles' di Supabase
      final profile = await client
          .from('profiles')
          .select()
          .eq('id', sbUser.id)
          .single();

      final user = User(
        id: sbUser.id,
        email: profile['email'] ?? sbUser.email,
        name: profile['name'],
        role: profile['role'] ?? 'user',
        createdAt: DateTime.parse(profile['created_at']),
        updatedAt: DateTime.parse(profile['updated_at']),
        password: password, // Simpan password di lokal cache
      );

      // Cache user yang berhasil login ke SQLite
      await userDao.cacheUser(user);

      return user;
    } catch (e) {
      print("Error during login: $e");
      return null;
    }
  }

  // LOGOUT
  Future<void> logout() async {
    // Hapus cache dari lokal
    await userDao.clearCache();
    // Logout dari Supabase
    await client.auth.signOut();
  }

  // INISIALISASI & RESTORE SESSION
  // Method ini akan dipanggil saat aplikasi dimulai
  Future<User?> init() async {
    // 1. Cek apakah ada session aktif di Supabase
    final session = client.auth.currentSession;

    if (session != null && session.user != null) {
      final sbUser = session.user!;
      print("Supabase session found for user: ${sbUser.email}");

      try {
        // Jika ada, ambil data terbaru dari Supabase
        final profile = await client
            .from('profiles')
            .select()
            .eq('id', sbUser.id)
            .single();

        final user = User(
          id: sbUser.id,
          email: profile['email'] ?? sbUser.email,
          name: profile['name'],
          role: profile['role'] ?? 'user',
          createdAt: DateTime.parse(profile['created_at']),
          updatedAt: DateTime.parse(profile['updated_at']),
          password: '', // Password tidak tersedia dari session
        );

        // Perbarui cache lokal dengan data terbaru
        await userDao.cacheUser(user);
        return user;
      } catch (e) {
        // Jika gagal mengambil data dari Supabase (misalnya offline),
        // lanjut ke langkah 2.
        print("Could not fetch user profile from Supabase, falling back to cache.");
      }
    }

    // 2. Jika tidak ada session Supabase atau offline, coba ambil dari cache lokal
    print("No Supabase session, checking local cache...");
    final cachedUser = await userDao.getCachedUser();
    if (cachedUser != null) {
      print("User found in local cache: ${cachedUser.email}");
    }
    return cachedUser;
  }

  // UPDATE PROFILE
  Future<User> updateProfile({
    required User user,
    String? name,
    String? email,
    String? currentPassword,
    String? newPassword,
  }) async {
    try {
      // 1. Update data di tabel 'profiles' Supabase
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (email != null) updates['email'] = email;
      updates['updated_at'] = DateTime.now().toIso8601String();

      if (updates.isNotEmpty) {
        await client
            .from('profiles')
            .update(updates)
            .eq('id', user.id);
      }

      // 2. Jika password berubah, update di Supabase Auth
      if (newPassword != null && newPassword.isNotEmpty) {
        await client.auth.updateUser(
          sb.UserAttributes(
            password: newPassword,
          ),
        );
      }

      // 3. Ambil data profil yang sudah diperbarui dari Supabase
      final updatedProfile = await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      // 4. Buat objek User baru
      final updatedUser = user.copyWith(
        name: updatedProfile['name'],
        email: updatedProfile['email'],
        updatedAt: DateTime.parse(updatedProfile['updated_at']),
        password: newPassword ?? user.password, // Update password jika berubah
      );

      // 5. Perbarui cache di SQLite
      await userDao.updateCache(updatedUser);

      return updatedUser;
    } catch (e) {
      print("Error updating profile: $e");
      rethrow;
    }
  }
  Future<bool> verifyCurrentPassword(String password) async {
    try {
      final currentUser = client.auth.currentUser;
      if (currentUser == null) return false;

      final response = await client.auth.signInWithPassword(
        email: currentUser.email!,
        password: password,
      );
      return response.user != null;
    } catch (e) {
      return false;
    }
  }
}