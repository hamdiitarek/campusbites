class OrderNotification {
  final String id;
  final String orderId;
  final String userId;
  final String title;
  final String body;
  final String status;
  final DateTime createdAt;
  final bool read;

  OrderNotification({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.title,
    required this.body,
    required this.status,
    required this.createdAt,
    this.read = false,
  });

  factory OrderNotification.fromJson(Map<String, dynamic> json, String id) {
    return OrderNotification(
      id: id,
      orderId: json['orderId'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      status: json['status'] ?? '',
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      read: json['read'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'userId': userId,
      'title': title,
      'body': body,
      'status': status,
      'createdAt': createdAt,
      'read': read,
    };
  }
}
