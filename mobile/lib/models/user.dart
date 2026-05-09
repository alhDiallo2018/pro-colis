enum UserRole {
  superAdmin,
  admin,
  driver,
  client,
}

class User {
  final String id;
  final String email;
  final String phone;
  final String fullName;
  final UserRole role;
  final String? garageId;
  final String? vehiclePlate;
  final String? profilePhotoUrl;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final DateTime createdAt;
  final DateTime? lastLogin;

  User({
    required this.id,
    required this.email,
    required this.phone,
    required this.fullName,
    required this.role,
    this.garageId,
    this.vehiclePlate,
    this.profilePhotoUrl,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    required this.createdAt,
    this.lastLogin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    UserRole role;
    switch (json['role']) {
      case 'super_admin':
        role = UserRole.superAdmin;
        break;
      case 'admin':
        role = UserRole.admin;
        break;
      case 'driver':
        role = UserRole.driver;
        break;
      default:
        role = UserRole.client;
    }

    return User(
      id: json['id'],
      email: json['email'],
      phone: json['phone'],
      fullName: json['fullName'],
      role: role,
      garageId: json['garageId'],
      vehiclePlate: json['vehiclePlate'],
      profilePhotoUrl: json['profilePhotoUrl'],
      isEmailVerified: json['isEmailVerified'] ?? false,
      isPhoneVerified: json['isPhoneVerified'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      lastLogin: json['lastLogin'] != null ? DateTime.parse(json['lastLogin']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'phone': phone,
    'fullName': fullName,
    'role': role.name,
    'garageId': garageId,
    'vehiclePlate': vehiclePlate,
    'profilePhotoUrl': profilePhotoUrl,
    'isEmailVerified': isEmailVerified,
    'isPhoneVerified': isPhoneVerified,
    'createdAt': createdAt.toIso8601String(),
    'lastLogin': lastLogin?.toIso8601String(),
  };

  bool get isSuperAdmin => role == UserRole.superAdmin;
  bool get isAdmin => role == UserRole.admin || role == UserRole.superAdmin;
  bool get isDriver => role == UserRole.driver;
  bool get isClient => role == UserRole.client;
}
