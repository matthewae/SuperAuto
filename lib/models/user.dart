class User {
  final String id;
  final String email;
  final String password;
  final String name;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String role;


  User({
    required this.id,
    required this.email,
    required this.password,
    required this.name,
    required this.createdAt,
    this.updatedAt,
    this.role = 'user',
  });

  String get idString => id?.toString() ?? '';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'name': name,
      'createdAt': createdAt.toIso8601String(), // Konversi DateTime ke string
      'updatedAt': updatedAt?.toIso8601String(), // Konversi DateTime ke string
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
      createdAt: DateTime.parse(map['createdAt'] as String), // Konversi string ke DateTime
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : null, // Konversi string ke DateTime
      role: map['role'] as String? ?? 'user',
    );
  }

  User copyWith({
    String? id,
    String? email,
    String? password,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? role,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      password: password ?? this.password,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      role: role ?? this.role,
    );
  }
}