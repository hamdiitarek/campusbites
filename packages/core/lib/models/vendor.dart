class Vendor {
  final String id;
  final String name;
  final String userId;
  final String universityId;
  final String universityName;
  final String description;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final List<String> categories;
  final bool isOpen;
  final bool isApproved;
  final bool isSuspended;
  final List<dynamic> menuItems;

  Vendor({
    required this.id,
    required this.name,
    required this.userId,
    required this.universityId,
    required this.universityName,
    required this.description,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.categories,
    required this.isOpen,
    required this.isApproved,
    this.isSuspended = false,
    this.menuItems = const [],
  });

  factory Vendor.fromMap(String id, Map<String, dynamic> map) {
    return Vendor(
      id: id,
      name: map['name'] ?? '',
      userId: map['userId'] ?? '',
      universityId: map['universityId'] ?? '',
      universityName: map['universityName'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      categories: List<String>.from(map['categories'] ?? []),
      isOpen: map['isOpen'] ?? false,
      isApproved: map['isApproved'] ?? false,
      isSuspended: map['isSuspended'] ?? false,
      menuItems: [],
    );
  }

  factory Vendor.empty() {
    return Vendor(
      id: '',
      name: '',
      userId: '',
      universityId: '',
      universityName: '',
      description: '',
      imageUrl: '',
      rating: 0.0,
      reviewCount: 0,
      categories: [],
      isOpen: false,
      isApproved: false,
      isSuspended: false,
      menuItems: [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'userId': userId,
      'universityId': universityId,
      'universityName': universityName,
      'description': description,
      'imageUrl': imageUrl,
      'rating': rating,
      'reviewCount': reviewCount,
      'categories': categories,
      'isOpen': isOpen,
      'isApproved': isApproved,
      'isSuspended': isSuspended,
    };
  }

  Vendor copyWith({
    String? name,
    String? description,
    String? imageUrl,
    double? rating,
    int? reviewCount,
    List<String>? categories,
    bool? isOpen,
    bool? isApproved,
    bool? isSuspended,
    List<dynamic>? menuItems,
  }) {
    return Vendor(
      id: id,
      name: name ?? this.name,
      userId: userId,
      universityId: universityId,
      universityName: universityName,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      categories: categories ?? this.categories,
      isOpen: isOpen ?? this.isOpen,
      isApproved: isApproved ?? this.isApproved,
      isSuspended: isSuspended ?? this.isSuspended,
      menuItems: menuItems ?? this.menuItems,
    );
  }
}
