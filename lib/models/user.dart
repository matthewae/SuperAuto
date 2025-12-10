class User {
  final String id;
  final String email;
  final String password;
  final String name;
  final String role;

  User({
    required this.id,
    required this.email,
    required this.password,
    required this.name,
    this.role = 'user',
  });
  String get idString => id?.toString() ?? '';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'name': name,
      'role': role,
    };
  }

  // Dari database ke object
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
      name: map['name'] as String,
      role: map['role'] as String? ?? 'user',
    );
   }
  }


