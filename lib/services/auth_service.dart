import '../data/dao/user_dao.dart';
import '../models/user.dart';

class AuthService {
  final UserDao _userDao = UserDao();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await _initializeAdmin();
  }

  Future<void> _initializeAdmin() async {
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
    return await _userDao.login(email, password);
  }
}

