import 'package:flutter/material.dart';

enum UserRole {
  client('client', 'Client', Icons.person),
  driver('driver', 'Chauffeur', Icons.delivery_dining),
  admin('admin', 'Admin Garage', Icons.business),
  superAdmin('super_admin', 'Super Admin', Icons.admin_panel_settings);

  final String value;
  final String label;
  final IconData icon;
  const UserRole(this.value, this.label, this.icon);

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.value == value,
      orElse: () => UserRole.client,
    );
  }
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

class User {
  final String id;
  final String email;
  final String phone;
  final String fullName;
  final UserRole role;
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
  final bool isVerified;
  final DateTime createdAt;
  final DateTime? lastLogin;

  User({
    required this.id,
    required this.email,
    required this.phone,
    required this.fullName,
    required this.role,
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
    this.isVerified = false,
    required this.createdAt,
    this.lastLogin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      phone: json['phone'],
      fullName: json['fullName'],
      role: UserRole.fromString(json['role']),
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
      isVerified: json['isVerified'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      lastLogin: json['lastLogin'] != null ? DateTime.parse(json['lastLogin']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'phone': phone,
    'fullName': fullName,
    'role': role.value,
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
    'isVerified': isVerified,
    'createdAt': createdAt.toIso8601String(),
    'lastLogin': lastLogin?.toIso8601String(),
  };
}
