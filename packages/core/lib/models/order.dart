class Order {
  final String id;
  final String userId;
  final String vendorId;
  final List<OrderItem> items;
  final double total;
  final String status; // pending, confirmed, ready, completed, cancelled
  final String paymentMethod;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.userId,
    required this.vendorId,
    required this.items,
    required this.total,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
  });

  factory Order.fromMap(String id, Map<String, dynamic> map) {
    List<OrderItem> orderItems = [];
    if (map['items'] is List) {
      orderItems = (map['items'] as List<dynamic>)
          .map((item) => OrderItem.fromMap(item))
          .toList();
    } else if (map['items'] is Map) {
      final itemsMap = map['items'] as Map<String, dynamic>;
      if (itemsMap.containsKey('0')) {
        int index = 0;
        while (itemsMap.containsKey(index.toString())) {
          final itemData = itemsMap[index.toString()];
          if (itemData is Map<String, dynamic>) {
            orderItems.add(OrderItem.fromMap(itemData));
          }
          index++;
        }
      }
    }

    return Order(
      id: id,
      userId: map['userId'] ?? '',
      vendorId: map['vendorId'] ?? '',
      items: orderItems,
      total: (map['total'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'pending',
      paymentMethod: map['paymentMethod'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'vendorId': vendorId,
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'status': status,
      'paymentMethod': paymentMethod,
      'createdAt': createdAt,
    };
  }

  // Create a copy of this order with a new status
  Order copyWithStatus(String newStatus) {
    return Order(
      id: id,
      userId: userId,
      vendorId: vendorId,
      items: items,
      total: total,
      status: newStatus,
      paymentMethod: paymentMethod,
      createdAt: createdAt,
    );
  }
}

class OrderItem {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final String note;
  final Map<String, dynamic> customizations;

  OrderItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.note = '',
    this.customizations = const {},
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      quantity: map['quantity'] ?? 1,
      note: map['note'] ?? '',
      customizations: Map<String, dynamic>.from(map['customizations'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'note': note,
      'customizations': customizations,
    };
  }
}
