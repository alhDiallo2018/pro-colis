
import 'package:flutter/material.dart';

enum UserRole {
  client('client', 'Client', Icons.person, Colors.green),
  driver('driver', 'Chauffeur', Icons.delivery_dining, Colors.blue),
  admin('admin', 'Admin Garage', Icons.business, Colors.orange),
  superAdmin('super_admin', 'Super Admin', Icons.admin_panel_settings, Colors.red);

  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const UserRole(this.value, this.label, this.icon, this.color);

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.value == value,
      orElse: () => UserRole.client,
    );
  }
}

enum UserStatus {
  active('active', 'Actif', Colors.green),
  suspended('suspended', 'Suspendu', Colors.orange),
  blocked('blocked', 'Bloqué', Colors.red);

  final String value;
  final String label;
  final Color color;
  const UserStatus(this.value, this.label, this.color);
}

enum DriverStatus {
  available('available', 'Disponible', Colors.green),
  busy('busy', 'En course', Colors.orange),
  offline('offline', 'Hors ligne', Colors.red);

  final String value;
  final String label;
  final Color color;
  const DriverStatus(this.value, this.label, this.color);
}

enum Gender {
  male('male', 'Homme', Icons.male),
  female('female', 'Femme', Icons.female),
  other('other', 'Autre', Icons.person);

  final String value;
  final String label;
  final IconData icon;
  const Gender(this.value, this.label, this.icon);
}

class User {
  final String id;
  final String email;
  final String phone;
  final String fullName;
  final UserRole role;
  final UserStatus status;
  final String? profilePhoto;
  final String? address;
  final String? city;
  final String? region;
  final String? country;
  final String? garageId;
  final String? garageName;
  final String? vehiclePlate;
  final String? vehicleModel;
  final DriverStatus? driverStatus;
  final Gender? gender;
  final DateTime? birthDate;
  final String? nationalId;
  final String? emergencyContact;
  final String? emergencyPhone;
  final bool hasPin;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final bool isApproved;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLogin;
  final DateTime? lastActive;

  User({
    required this.id,
    required this.email,
    required this.phone,
    required this.fullName,
    required this.role,
    this.status = UserStatus.active,
    this.profilePhoto,
    this.address,
    this.city,
    this.region,
    this.country = 'Sénégal',
    this.garageId,
    this.garageName,
    this.vehiclePlate,
    this.vehicleModel,
    this.driverStatus,
    this.gender,
    this.birthDate,
    this.nationalId,
    this.emergencyContact,
    this.emergencyPhone,
    this.hasPin = false,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.isApproved = false,
    this.approvedBy,
    this.approvedAt,
    this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.lastLogin,
    this.lastActive,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      phone: json['phone'],
      fullName: json['fullName'],
      role: UserRole.fromString(json['role']),
      status: json['status'] != null 
          ? UserStatus.values.firstWhere((e) => e.value == json['status'])
          : UserStatus.active,
      profilePhoto: json['profilePhoto'],
      address: json['address'],
      city: json['city'],
      region: json['region'],
      country: json['country'] ?? 'Sénégal',
      garageId: json['garageId'],
      garageName: json['garageName'],
      vehiclePlate: json['vehiclePlate'],
      vehicleModel: json['vehicleModel'],
      driverStatus: json['driverStatus'] != null 
          ? DriverStatus.values.firstWhere((e) => e.value == json['driverStatus'])
          : null,
      gender: json['gender'] != null
          ? Gender.values.firstWhere((e) => e.value == json['gender'])
          : null,
      birthDate: json['birthDate'] != null ? DateTime.parse(json['birthDate']) : null,
      nationalId: json['nationalId'],
      emergencyContact: json['emergencyContact'],
      emergencyPhone: json['emergencyPhone'],
      hasPin: json['hasPin'] ?? false,
      isEmailVerified: json['isEmailVerified'] ?? false,
      isPhoneVerified: json['isPhoneVerified'] ?? false,
      isApproved: json['isApproved'] ?? false,
      approvedBy: json['approvedBy'],
      approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt']) : null,
      createdBy: json['createdBy'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      lastLogin: json['lastLogin'] != null ? DateTime.parse(json['lastLogin']) : null,
      lastActive: json['lastActive'] != null ? DateTime.parse(json['lastActive']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'phone': phone,
    'fullName': fullName,
    'role': role.value,
    'status': status.value,
    'profilePhoto': profilePhoto,
    'address': address,
    'city': city,
    'region': region,
    'country': country,
    'garageId': garageId,
    'garageName': garageName,
    'vehiclePlate': vehiclePlate,
    'vehicleModel': vehicleModel,
    'driverStatus': driverStatus?.value,
    'gender': gender?.value,
    'birthDate': birthDate?.toIso8601String(),
    'nationalId': nationalId,
    'emergencyContact': emergencyContact,
    'emergencyPhone': emergencyPhone,
    'hasPin': hasPin,
    'isEmailVerified': isEmailVerified,
    'isPhoneVerified': isPhoneVerified,
    'isApproved': isApproved,
    'approvedBy': approvedBy,
    'approvedAt': approvedAt?.toIso8601String(),
    'createdBy': createdBy,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'lastLogin': lastLogin?.toIso8601String(),
    'lastActive': lastActive?.toIso8601String(),
  };

  bool get isActive => status == UserStatus.active;
  bool get isSuperAdmin => role == UserRole.superAdmin;
  bool get isAdmin => role == UserRole.admin || role == UserRole.superAdmin;
  bool get isDriver => role == UserRole.driver;
  bool get isClient => role == UserRole.client;
}
