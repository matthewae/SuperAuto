class CartItem {
  final String productId;
  final int quantity;
  final double price;
  const CartItem({required this.productId, required this.quantity, required this.price});
}

class Cart {
  final List<CartItem> items;
  final String? appliedPromoId;
  const Cart({this.items = const [], this.appliedPromoId});

  double get subtotal => items.fold(0.0, (sum, i) => sum + i.price * i.quantity);
}

