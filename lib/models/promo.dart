import 'package:uuid/uuid.dart';

class Promo {
  final String id;
  final String name;
  final String type;
  final double value;
  final DateTime start;
  final DateTime end;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? imageUrl;

  const Promo({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    required this.start,
    required this.end,
    required this.createdAt,
    this.updatedAt,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'value': value,
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'imageUrl': imageUrl,
    };
  }

  factory Promo.fromMap(Map<String, dynamic> map) {
    return Promo(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      value: (map['value'] as num).toDouble(),
      start: DateTime.parse(map['start']),
      end: DateTime.parse(map['end']),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
      imageUrl: map['imageUrl'],
    );
  }


  bool isActive() {
    final now = DateTime.now();
    return now.isAfter(start) && now.isBefore(end);
  }

  // Calculate discount amount based on original amount
  double calculateDiscount(double originalAmount) {
    if (type == 'service_discount' || type == 'product_discount') {
      if (value > 1) {
        // Fixed amount discount
        return value;
      } else {
        // Percentage discount
        return originalAmount * value;
      }
    }
    return 0.0;
  }

  // Get formatted discount value for display
  String get formattedValue {
    if (value > 1) {
      return 'Rp ${value.toStringAsFixed(0)}';
    } else {
      return '${(value * 100).toStringAsFixed(0)}%';
    }
  }

  // Get formatted type for display
  String get formattedType {
    switch (type) {
      case 'service_discount':
        return 'Diskon Servis';
      case 'product_discount':
        return 'Diskon Produk';
      default:
        return type;
    }
  }
  factory Promo.fromSupabase(Map<String, dynamic> json) {
    return Promo(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      value: (json['value'] as num).toDouble(),
      start: DateTime.parse(json['start']),
      end: DateTime.parse(json['end']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      imageUrl: json['image_url'],
    );
  }

  Promo copyWith({
    String? id,
    String? name,
    String? type,
    double? value,
    DateTime? start,
    DateTime? end,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? imageUrl,
  }) {
    return Promo(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      value: value ?? this.value,
      start: start ?? this.start,
      end: end ?? this.end,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  // Create a new promo with default values
  factory Promo.create({
    required String name,
    required String type,
    required double value,
    required DateTime start,
    required DateTime end,
  }) {
    return Promo(
      id: const Uuid().v4(),
      name: name,
      type: type,
      value: value,
      start: start,
      end: end,
      createdAt: DateTime.now(),
    );
  }
}