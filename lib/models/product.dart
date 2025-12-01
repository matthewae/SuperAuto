import 'enums.dart';

class Product {
  final String id;
  final String name;
  final ProductCategory category;
  final String description;
  final double price;
  final String? imageUrl;
  final List<String> compatibleModels; // simple sorting by model

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    this.imageUrl,
    this.compatibleModels = const [],
  });
}

