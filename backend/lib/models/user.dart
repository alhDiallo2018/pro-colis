// backend/lib/models/user.dart
import 'package:uuid/uuid.dart';

class User {
  final String id;
  final String email;
  final String phone;
  final String fullName;
  final String? passwordHash;
  final UserRole role;
  final String? garageId;
  final String? vehiclePlate;
  final String? profilePhotoUrl;
  final UserStatus status;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final DateTime? updatedAt;

  User({
    String? id,
    required this.email,
    required this.phone,
    required this.fullName,
    this.passwordHash,
    required this.role,
    this.garageId,
    this.vehiclePlate,
    this.profilePhotoUrl,
    this.status = UserStatus.active,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    DateTime? createdAt,
    this.lastLogin,
    this.updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'phone': phone,
    'fullName': fullName,
    'role': role.name,
    'garageId': garageId,
    'vehiclePlate': vehiclePlate,
    'profilePhotoUrl': profilePhotoUrl,
    'status': status.name,
    'isEmailVerified': isEmailVerified,
    'isPhoneVerified': isPhoneVerified,
    'createdAt': createdAt.toIso8601String(),
    'lastLogin': lastLogin?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    email: json['email'],
    phone: json['phone'],
    fullName: json['fullName'],
    passwordHash: json['passwordHash'],
    role: UserRole.values.firstWhere((e) => e.name == json['role']),
    garageId: json['garageId'],
    vehiclePlate: json['vehiclePlate'],
    profilePhotoUrl: json['profilePhotoUrl'],
    status: UserStatus.values.firstWhere((e) => e.name == json['status']),
    isEmailVerified: json['isEmailVerified'] ?? false,
    isPhoneVerified: json['isPhoneVerified'] ?? false,
    createdAt: DateTime.parse(json['createdAt']),
    lastLogin: json['lastLogin'] != null ? DateTime.parse(json['lastLogin']) : null,
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
  );
}

enum UserRole {
  superAdmin('super_admin'),
  admin('admin'),
  driver('driver'),
  client('client');

  final String name;
  const UserRole(this.name);
}

enum UserStatus {
  active('active'),
  suspended('suspended'),
  deleted('deleted');

  final String name;
  const UserStatus(this.name);
}