class UserModel {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String locale;
  final List<String> roles;
  final bool isVerified;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    required this.locale,
    required this.roles,
    required this.isVerified,
    this.createdAt,
  });

  bool get isHost => roles.any((r) => ['owner', 'agency', 'hotelier', 'admin'].contains(r));
  bool get isGuest => roles.contains('tenant') || roles.isEmpty;
  bool get isAdmin => roles.contains('admin');

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'User',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      locale: json['locale'] as String? ?? 'fr',
      roles: (json['roles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isVerified: json['is_verified'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'locale': locale,
      'roles': roles,
      'is_verified': isVerified,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
