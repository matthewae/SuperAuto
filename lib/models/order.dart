// lib/models/order.dart
class Order {
  final String id;
  final int userId;
  final List<OrderItem> items;
  final double total;
  final DateTime createdAt;
  final String status;
  final String? trackingNumber;
  final String? shippingMethod;
  final String? shippingAddress;
  final DateTime? updatedAt;
  final String? paymentMethod;

  const Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.total,
    required this.createdAt,
    this.status = 'pending',
    this.trackingNumber,
    this.shippingMethod,
    this.shippingAddress,
    this.updatedAt,
    this.paymentMethod,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'status': status,
      'trackingNumber': trackingNumber,
      'shippingMethod': shippingMethod,
      'shippingAddress': shippingAddress,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'paymentMethod': paymentMethod,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] as String,
      userId: map['userId'],
      items: (map['items'] as List<dynamic>)
          .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      total: (map['total'] as num).toDouble(),
      status: map['status'] as String? ?? 'pending',
      trackingNumber: map['trackingNumber'] as String?,
      shippingMethod: map['shippingMethod'] as String?,
      shippingAddress: map['shippingAddress'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      paymentMethod: map['paymentMethod'] as String?,
    );
  }

  Order copyWith({
    String? id,
    String? userId,
    List<OrderItem>? items,
    double? total,
    DateTime? createdAt,
    String? status,
    String? trackingNumber,
    String? shippingMethod,
    String? shippingAddress,
    DateTime? updatedAt,
    String? paymentMethod,
  }) {
    return Order(
      id: id ?? this.id,
      userId:this.userId,
      items: items ?? this.items,
      total: total ?? this.total,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      shippingMethod: shippingMethod ?? this.shippingMethod,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      updatedAt: updatedAt ?? this.updatedAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}

class OrderItem {
  final String id;
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String? imageUrl;

  const OrderItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] as String,
      productId: map['productId'] as String,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'] as int,
      imageUrl: map['imageUrl'] as String?,
    );
  }

  OrderItem copyWith({
    String? id,
    String? productId,
    String? name,
    double? price,
    int? quantity,
    String? imageUrl,
  }) {
    return OrderItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}