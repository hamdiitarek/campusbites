class User {
  final String id;
  final String fullName;
  final String email;
  final String universityId;
  final String universityName;
  final String phoneNumber;
  final bool isEmailVerified;
  final String role; // 'student', 'vendor', or 'admin'
  final double walletBalance;
  final String profileImageUrl;

  const User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.universityId,
    required this.universityName,
    required this.phoneNumber,
    this.isEmailVerified = false,
    this.role = 'student',
    this.walletBalance = 0.0,
    this.profileImageUrl = '',
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      universityId: map['universityId'] ?? '',
      universityName: map['universityName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      isEmailVerified: map['isEmailVerified'] ?? false,
      role: map['role'] ?? 'student',
      walletBalance: (map['walletBalance'] ?? 0.0).toDouble(),
      profileImageUrl: map['profileImageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'universityId': universityId,
      'universityName': universityName,
      'phoneNumber': phoneNumber,
      'isEmailVerified': isEmailVerified,
      'role': role,
      'walletBalance': walletBalance,
      'profileImageUrl': profileImageUrl,
    };
  }

  User copyWith({
    String? fullName,
    String? phoneNumber,
    String? universityId,
    String? universityName,
    bool? isEmailVerified,
    String? role,
    double? walletBalance,
    String? profileImageUrl,
  }) {
    return User(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email,
      universityId: universityId ?? this.universityId,
      universityName: universityName ?? this.universityName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      role: role ?? this.role,
      walletBalance: walletBalance ?? this.walletBalance,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}
