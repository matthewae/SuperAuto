import '../data/dao/user_dao.dart';
import '../models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final UserDao _userDao = UserDao();
  bool _initialized = false;
  User? _currentUser;

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
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('current_user_email');
    if (userEmail != null) {
      _currentUser = await _userDao.getUserByEmail(userEmail);
    }
  }

  Future<String?> register(String email, String password, String name) async {
    await init(); // pastikan init selesai dulu

    final existing = await _userDao.getUserByEmail(email);
    if (existing != null) return "Email sudah terdaftar!";

    final isAdmin = email.toLowerCase() == "admin@superauto.com";

    final newUser = User(
      email: email,
      password: password,
      name: name,
      role: isAdmin ? "admin" : "user",
    );

    await _userDao.insertUser(newUser);
    return null;
  }

  Future<User?> login(String email, String password) async {
    await init(); // pastikan admin sudah dibuat dulu
    final user = await _userDao.login(email, password);
    if (user != null) {
      _currentUser = user;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user_email', user.email);
    }
    return user;
  }

  User? currentUser() {
    return _currentUser;
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_email');
  }
}