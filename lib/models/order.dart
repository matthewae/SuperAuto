// lib/models/order.dart
class Order {
  final String id;
  final String userId;
  final String? userName;
  final List<OrderItem> items; // hanya untuk keperluan Flutter
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
    this.userName,
    this.items = const [],
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
      'userName': userName,
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

  factory Order.fromMap(Map<String, dynamic> map, {List<OrderItem> items = const []}) {
    return Order(
      id: map['id'] as String,
      userId: map['userId'] as String,
      userName: map['userName'] as String?,
      items: items, // Gunakan items yang diberikan atau default ke list kosong
      total: (map['total'] as num).toDouble(),
      status: map['status'] as String? ?? 'pending',
      trackingNumber: map['trackingNumber'] as String?,
      shippingMethod: map['shippingMethod'] as String?,
      shippingAddress: map['shippingAddress'] as String?,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      paymentMethod: map['paymentMethod'] as String?,
    );
  }

  Order copyWith({
    String? id,
    String? userId,
    String? userName,
    List<OrderItem>? items,
    double? total,
    DateTime? updatedAt,
    DateTime? createdAt,
    String? status,
    String? paymentMethod,
    String? shippingMethod,
    String? shippingAddress,
    String? trackingNumber,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      items: items ?? List.from(this.items), // Buat salinan baru dari daftar items
      total: total ?? this.total,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      shippingMethod: shippingMethod ?? this.shippingMethod,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      trackingNumber: trackingNumber ?? this.trackingNumber,
    );
  }
}

class OrderItem {
  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final String? imageUrl;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] as String,
      orderId: map['orderId'] as String,
      productId: map['productId'] as String,
      productName: map['productName'] as String,
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'] as int,
      imageUrl: map['imageUrl'] as String?,
    );
  }
}
