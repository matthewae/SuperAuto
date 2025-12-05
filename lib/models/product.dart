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

  factory Product.fromMap(Map<String, dynamic> json) => Product(
    id: json['id'],
    name: json['name'],
    category: ProductCategoryExt.fromString(json['category']),
    description: json['description'],
    price: json['price'],
    imageUrl: json['imageUrl'],
    compatibleModels: json['compatibleModels'] == null
        ? []
        : List<String>.from(jsonDecode(json['compatibleModels'])),
  );
}
