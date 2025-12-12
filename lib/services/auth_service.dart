import '../data/dao/user_dao.dart';
import '../models/user.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import 'package:uuid/uuid.dart';

class AuthService {
  final UserDao _userDao;
  bool _initialized = false;
  User? _currentUser;
  final Ref? _ref;

  AuthService(this._userDao, {Ref? ref}) : _ref = ref;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await _initializeAdmin();
    await _loadCurrentUser();
  }

  Future<void> _initializeAdmin() async {
    try {
      final existingAdmin = await _userDao.getUserByEmail("admin@superauto.com");
      if (existingAdmin == null) {
        await _userDao.insertUser(
          User(
            id: const Uuid().v4(),
            email: "admin@superauto.com",
            password: "admin",
            name: "Super Admin",
            createdAt: DateTime.now(),
            role: "admin",
          ),
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('current_user_email');
      debugPrint('Loading current user with email: $userEmail');

      if (userEmail != null) {
        _currentUser = await _userDao.getUserByEmail(userEmail);
        if (_currentUser != null) {
          debugPrint('Loaded current user - ID: ${_currentUser!.id}, Email: ${_currentUser!.email}');
        } else {
          debugPrint('User not found in database, clearing saved email');
          await prefs.remove('current_user_email');
        }
      } else {
        debugPrint('ℹNo saved user email found');
      }
    } catch (e) {
      debugPrint('Error loading current user: $e');
      rethrow;
    }
  }

  Future<String?> register(String email, String password, String name) async {
    debugPrint('👤 Attempting to register user: $email');
    await init();

    final existing = await _userDao.getUserByEmail(email);
    if (existing != null) {
      debugPrint('User already exists: $email');
      return "Email sudah terdaftar!";
    }

    final isAdmin = email.toLowerCase() == "admin@superauto.com";
    final newUser = User(
      id: const Uuid().v4(),
      email: email,
      password: password,
      name: name,
      createdAt: DateTime.now(),
      role: isAdmin ? "admin" : "user",
    );

    debugPrint('➕ Creating new user: ${newUser.toMap()}');
    await _userDao.insertUser(newUser);
    debugPrint('User created successfully');
    return null;
  }

  Future<User?> login(String email, String password) async {
    try {
      final user = await _userDao.getUserByEmail(email);
      if (user != null) {
        // Use verifyPassword to check the password
        final isValid = await _userDao.verifyPassword(user.id, password);
        if (isValid) {
          // Save user session
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_id', user.idString);
          await prefs.setString('current_user_email', email);

          // Refresh bookings if we have a ref
          if (_ref != null) {
            _ref!.read(bookingsProvider.notifier).refresh();
          }

          // Set current user
          _currentUser = user;
          return user;
        }
      }
      return null;
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  User? currentUser() {
    return _currentUser;
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      await prefs.remove('current_user_email');

      // Invalidate providers if we have a ref
      if (_ref != null) {
        _ref!.invalidate(bookingsProvider);
      }

      // Clear current user
      _currentUser = null;
    } catch (e) {
      print('Logout error: $e');
      rethrow;
    }
  }

  // Tambahkan metode updateProfile
  Future<User> updateProfile({
    required User user,
    required String name,
    required String email,
    String? newPassword,
    String? currentPassword,
  }) async {
    try {
      // Verifikasi password saat ini jika ingin mengubah password
      if (newPassword != null && currentPassword != null) {
        final isPasswordValid = await _userDao.verifyPassword(user.id, currentPassword);
        if (!isPasswordValid) {
          throw Exception('Password saat ini tidak benar');
        }
      }

      // Periksa apakah email sudah digunakan oleh pengguna lain
      if (email != user.email) {
        final existingUser = await _userDao.getUserByEmail(email);
        if (existingUser != null) {
          throw Exception('Email sudah digunakan oleh pengguna lain');
        }
      }

      // Buat objek user yang diperbarui
      final updatedUser = user.copyWith(
        name: name,
        email: email,
        password: newPassword ?? user.password,
      );

      // Simpan perubahan ke database
      await _userDao.updateUser(updatedUser);

      // Update current user
      _currentUser = updatedUser;

      // Simpan email baru ke SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user_email', email);

      return updatedUser;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }
}