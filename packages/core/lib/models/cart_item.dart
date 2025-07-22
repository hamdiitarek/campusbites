class CartItem {
  final String id; // Original menu item ID
  final String cartId; // Unique ID for this cart item
  final String name;
  final double price;
  int quantity;
  final String imageUrl;
  final String vendorId;
  final String vendorName;
  String note;
  final Map<String, dynamic> customizations;

  CartItem({
    required this.id,
    required this.cartId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    required this.vendorId,
    required this.vendorName,
    this.note = '',
    this.customizations = const {},
  });
}
