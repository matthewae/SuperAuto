class CartItem {
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final String? imageUrl;

  const CartItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    this.imageUrl,
  });

  double get total => price * quantity;

  CartItem copyWith({
    String? productId,
    String? productName,
    int? quantity,
    double? price,
    String? imageUrl,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

class Cart {
  final List<CartItem> items;
  final String? appliedPromoId;

  const Cart({
    this.items = const [],
    this.appliedPromoId,
  });

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.total);
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  Cart copyWith({
    List<CartItem>? items,
    String? appliedPromoId,
  }) {
    return Cart(
      items: items ?? this.items,
      appliedPromoId: appliedPromoId ?? this.appliedPromoId,
    );
  }
}

