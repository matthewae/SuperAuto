class Cart {
  final List<CartItem> items;
  final String? appliedPromoId;
  final double discount;
  final double deliveryFee;

  const Cart({
    this.items = const [],
    this.appliedPromoId,
    this.discount = 0.0,
    this.deliveryFee = 0.0,
  });

  double get subtotal => items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  
  double get total => subtotal - discount + deliveryFee;
  
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  
  Cart copyWith({
    List<CartItem>? items,
    String? appliedPromoId,
    double? discount,
    double? deliveryFee,
  }) {
    return Cart(
      items: items ?? this.items,
      appliedPromoId: appliedPromoId ?? this.appliedPromoId,
      discount: discount ?? this.discount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
    );
  }
}

class CartState {
  final List<CartItem> items;
  final String? appliedPromoId;
  final double discount;
  final double deliveryFee;

  const CartState({
    this.items = const [],
    this.appliedPromoId,
    this.discount = 0.0,
    this.deliveryFee = 0.0,
  });

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get total => (subtotal - discount + deliveryFee).clamp(0, double.infinity);

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  CartState copyWith({
    List<CartItem>? items,
    String? appliedPromoId,
    double? discount,
    double? deliveryFee,
  }) {
    return CartState(
      items: items ?? this.items,
      appliedPromoId: appliedPromoId ?? this.appliedPromoId,
      discount: discount ?? this.discount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
    );
  }
}

class CartItem {
  final int? id; // PK (auto increment)
  final String userId;
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final String? imageUrl;
  final DateTime createdAt;

  const CartItem({
    this.id,
    required this.userId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    this.imageUrl,
    required this.createdAt,
  });

  CartItem copyWith({
    int? id,
    String? userId,
    String? productId,
    String? productName,
    int? quantity,
    double? price,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'] as int?,
      userId: map['userId'],
      productId: map['productId'],
      productName: map['productName'],
      quantity: map['quantity'],
      price: (map['price'] as num).toDouble(),
      imageUrl: map['imageUrl'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  /// Calculates loyalty points for this cart item
  /// Returns the number of points earned (1 point per 10,000 in total price)
  int calculateLoyaltyPoints() {
    final totalPrice = price * quantity;
    return (totalPrice / 10000).floor();
  }

  /// Returns the total price of this cart item (price * quantity)
  double get totalPrice => price * quantity;
}



