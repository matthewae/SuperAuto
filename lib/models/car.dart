class Car {
  final String id;
  final String brand;
  final String model;
  final int year;
  final String plateNumber;
  final String vin;
  final String engineNumber;
  final int initialKm;
  final int userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Car({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.plateNumber,
    required this.vin,
    required this.engineNumber,
    required this.initialKm,
    required this.userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'brand': brand,
      'model': model,
      'year': year,
      'plateNumber': plateNumber,
      'vin': vin,
      'engineNumber': engineNumber,
      'initialKm': initialKm,
      'userId': userId,  // This will be stored as INTEGER in SQLite
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Car.fromMap(Map<String, dynamic> map) {
    // Helper function to safely parse userId
    int parseUserId(dynamic value) {
      if (value == null) throw Exception('User ID cannot be null');
      if (value is int) return value;
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
      throw Exception('Invalid user ID format: $value');
    }

    return Car(
      id: map['id'] as String,
      brand: map['brand'] as String,
      model: map['model'] as String,
      year: map['year'] as int,
      plateNumber: map['plateNumber'] as String,
      vin: map['vin'] as String,
      engineNumber: map['engineNumber'] as String,
      initialKm: map['initialKm'] as int,
      userId: parseUserId(map['userId']),  // Use the safe parser
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }
}