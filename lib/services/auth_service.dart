import '../data/dao/user_dao.dart';
import '../models/user.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';

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
            email: "admin@superauto.com",
            password: "admin",
            name: "Super Admin",
            role: "admin",
          ),
        );

      } else {

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
      email: email,
      password: password,
      name: name,
      role: isAdmin ? "admin" : "user",
    );

    debugPrint('➕ Creating new user: ${newUser.toMap()}');
    await _userDao.insertUser(newUser);
    debugPrint('User created successfully');
    return null;
  }

  Future<User?> login(String email, String password) async {
    try {
      // Your existing login logic
      final user = await _userDao.getUserByEmail(email);
      if (user != null && user.password == password) {
        // Save user session
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', user.idString);

        // Refresh bookings if we have a ref
        if (_ref != null) {
          _ref!.read(bookingsProvider.notifier).refresh();
        }
        return user;
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

      // Invalidate providers if we have a ref
      if (_ref != null) {
        _ref!.invalidate(bookingsProvider);
      }
    } catch (e) {
      print('Logout error: $e');
      rethrow;
    }
  }
}
