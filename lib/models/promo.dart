class Promo {
  final String id;
  final String name;
  final String type; // service_discount, product_discount, bundling
  final double value; // percentage or fixed depending on type
  final DateTime start;
  final DateTime end;

  const Promo({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    required this.start,
    required this.end,
  });
}

