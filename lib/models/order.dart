class Order {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double total;
  final DateTime createdAt;
  final String shippingMethod;
  final String status; // e.g., pending, paid, shipped, completed

  const Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.total,
    required this.createdAt,
    required this.shippingMethod,
    required this.status,
  });
}

class OrderItem {
  final String productId;
  final int quantity;
  final double price;
  const OrderItem({required this.productId, required this.quantity, required this.price});
}

