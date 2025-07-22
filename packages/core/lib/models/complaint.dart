class Complaint {
  final String id;
  final String userId;
  final String vendorId;
  final String orderId;
  final String title;
  final String description;
  final String status; // pending, in_progress, resolved
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolution;
  final String? adminId;

  Complaint({
    required this.id,
    required this.userId,
    required this.vendorId,
    required this.orderId,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
    this.resolution,
    this.adminId,
  });

  factory Complaint.fromMap(String id, Map<String, dynamic> map) {
    return Complaint(
      id: id,
      userId: map['userId'] ?? '',
      vendorId: map['vendorId'] ?? '',
      orderId: map['orderId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as dynamic).toDate() 
          : DateTime.now(),
      resolvedAt: map['resolvedAt'] != null 
          ? (map['resolvedAt'] as dynamic).toDate() 
          : null,
      resolution: map['resolution'],
      adminId: map['adminId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'vendorId': vendorId,
      'orderId': orderId,
      'title': title,
      'description': description,
      'status': status,
      'createdAt': createdAt,
      'resolvedAt': resolvedAt,
      'resolution': resolution,
      'adminId': adminId,
    };
  }
}
