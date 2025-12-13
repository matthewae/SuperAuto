class Order {
  final String id;
  final String userId;
  final String? userName; // Bisa null
  final List<OrderItem> items;
  final double total;
  final DateTime createdAt;
  final String status;
  final String? trackingNumber; // Bisa null
  final String? shippingMethod; // Bisa null
  final String? shippingAddress; // Bisa null
  final DateTime? updatedAt; // Bisa null
  final String? paymentMethod; // Bisa null

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
      id: map['id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      userName: map['username'] as String?, // Bisa null
      items: items,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] as String? ?? 'pending', // Pastikan selalu ada nilai default
      trackingNumber: map['tracking_number'] as String?, // Bisa null
      shippingMethod: map['shipping_method'] as String?, // Bisa null
      shippingAddress: map['shipping_address'] as String?, // Bisa null
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
      paymentMethod: map['payment_method'] as String?, // Bisa null
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
  final String? imageUrl; // Bisa null

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

  // --- PERBAIKAN UTAMA ADA DI SINI ---
  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] as String? ?? '', // Tambahkan '??' untuk nilai default
      orderId: map['order_id'] as String? ?? '', // Tambahkan '??' untuk nilai default
      productId: map['product_id'] as String? ?? '', // Tambahkan '??' untuk nilai default
      productName: map['product_name'] as String? ?? 'Unknown Product', // Tambahkan '??' untuk nilai default
      price: (map['price'] as num?)?.toDouble() ?? 0.0, // Tambahkan '?' dan nilai default
      quantity: map['quantity'] as int? ?? 0, // Tambahkan '?' dan nilai default
      imageUrl: map['image_url'] as String?, // Ini aman karena sudah nullable
    );
  }
}