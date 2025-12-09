import 'dart:convert';
import 'enums.dart';

class Product {
  final String id;
  final String name;
  final ProductCategory category;
  final String description;
  final double price;
  final String? imageUrl;
  final List<String> compatibleModels;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    this.imageUrl,
    this.compatibleModels = const [],
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'category': category.nameStr,
    'description': description,
    'price': price,
    'imageUrl': imageUrl,
    'compatibleModels': jsonEncode(compatibleModels),
  };

  // In lib/models/product.dart
  factory Product.fromMap(Map<String, dynamic> json) {
    try {
      return Product(
        id: json['id'] as String,
        name: json['name'] as String,
        category: ProductCategoryExt.fromString(json['category'] as String),
        description: json['description'] as String,
        price: (json['price'] is int) ? (json['price'] as int).toDouble() : (json['price'] as num).toDouble(),
        imageUrl: json['imageUrl'] as String?,
        compatibleModels: json['compatibleModels'] == null
            ? []
            : List<String>.from(jsonDecode(json['compatibleModels'] as String)),
      );
    } catch (e) {
      print('Error in Product.fromMap: $e');
      print('Problematic JSON: $json');
      rethrow;
    }
  }
  Product copyWith({
    String? id,
    String? name,
    ProductCategory? category,
    String? description,
    double? price,
    String? imageUrl,
    List<String>? compatibleModels,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      compatibleModels: compatibleModels ?? this.compatibleModels,
    );
  }
}
