// backend/lib/models/user.dart
// ignore_for_file: unused_element

import 'package:uuid/uuid.dart';

// ==================== ENUMS ====================

enum UserRole {
  superAdmin('super_admin', 'Super Admin'),
  admin('admin', 'Admin Garage'),
  driver('driver', 'Chauffeur'),
  client('client', 'Client');

  final String value;
  final String label;

  const UserRole(this.value, this.label);

  static UserRole fromString(String value) {
    switch (value) {
      case 'super_admin':
        return UserRole.superAdmin;
      case 'admin':
        return UserRole.admin;
      case 'driver':
        return UserRole.driver;
      case 'client':
        return UserRole.client;
      default:
        return UserRole.client;
    }
  }
}

enum UserStatus {
  active('active', 'Actif'),
  suspended('suspended', 'Suspendu'),
  deleted('deleted', 'Supprimé');

  final String value;
  final String label;

  const UserStatus(this.value, this.label);

  static UserStatus fromString(String value) {
    switch (value) {
      case 'active':
        return UserStatus.active;
      case 'suspended':
        return UserStatus.suspended;
      case 'deleted':
        return UserStatus.deleted;
      default:
        return UserStatus.active;
    }
  }
}

enum DriverStatus {
  available('available', 'Disponible'),
  busy('busy', 'En livraison'),
  offline('offline', 'Hors ligne');

  final String value;
  final String label;

  const DriverStatus(this.value, this.label);

  static DriverStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'available':
        return DriverStatus.available;
      case 'busy':
        return DriverStatus.busy;
      case 'offline':
        return DriverStatus.offline;
      default:
        return DriverStatus.offline;
    }
  }
}

enum Gender {
  male('male', 'Homme'),
  female('female', 'Femme'),
  other('other', 'Autre');

  final String value;
  final String label;

  const Gender(this.value, this.label);

  static Gender fromString(String value) {
    switch (value.toLowerCase()) {
      case 'male':
        return Gender.male;
      case 'female':
        return Gender.female;
      default:
        return Gender.other;
    }
  }
}

// ==================== CLASSE USER ====================

class User {
  // Informations de base
  final String id;
  final String email;
  final String phone;
  final String fullName;
  final String? passwordHash;
  final UserRole role;
  final UserStatus status;
  final String? pin;

  // Profil
  final String? profilePhoto; // ✅ Changé: profilePhotoUrl -> profilePhoto (comme frontend)
  final String? address;
  final String? city;
  final String? region;
  final String? country;
  final Gender? gender;

  // Affiliation garage
  final String? garageId;
  final String? garageName;

  // Informations chauffeur
  final String? vehiclePlate;
  final String? vehicleModel;
  final String? vehicleColor;
  final int? vehicleYear;
  final DriverStatus? driverStatus;

  // Statistiques chauffeur
  final double? rating;
  final int? totalDeliveries;
  final int? completedDeliveries;
  final int? cancelledDeliveries;

  // Vérifications
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final bool isProfileComplete;

  // Dates
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLogin;
  final DateTime? lastActiveAt;

  // Constructeur
  User({
    String? id,
    required this.email,
    required this.phone,
    required this.fullName,
    this.passwordHash,
    required this.role,
    this.status = UserStatus.active,
    this.pin,
    this.profilePhoto,
    this.address,
    this.city,
    this.region,
    this.country,
    this.garageId,
    this.garageName,
    this.vehiclePlate,
    this.vehicleModel,
    this.vehicleColor,
    this.vehicleYear,
    this.driverStatus,
    this.gender,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.isProfileComplete = false,
    this.rating,
    this.totalDeliveries,
    this.completedDeliveries,
    this.cancelledDeliveries,
    DateTime? createdAt,
    this.updatedAt,
    this.lastLogin,
    this.lastActiveAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  // ==================== FABRICS ====================

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? json['full_name']?.toString() ?? '',
      passwordHash: json['passwordHash']?.toString() ?? json['password_hash']?.toString(),
      role: json['role'] != null 
          ? UserRole.fromString(json['role'].toString())
          : UserRole.client,
      status: json['status'] != null
          ? UserStatus.fromString(json['status'].toString())
          : UserStatus.active,
      pin: json['pin']?.toString(),
      profilePhoto: json['profilePhoto']?.toString() ?? json['profile_photo']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      region: json['region']?.toString(),
      country: json['country']?.toString(),
      garageId: json['garageId']?.toString() ?? json['garage_id']?.toString(),
      garageName: json['garageName']?.toString() ?? json['garage_name']?.toString(),
      vehiclePlate: json['vehiclePlate']?.toString() ?? json['vehicle_plate']?.toString(),
      vehicleModel: json['vehicleModel']?.toString() ?? json['vehicle_model']?.toString(),
      vehicleColor: json['vehicleColor']?.toString() ?? json['vehicle_color']?.toString(),
      vehicleYear: _toInt(json['vehicleYear'] ?? json['vehicle_year']),
      driverStatus: json['driverStatus'] != null
          ? DriverStatus.fromString(json['driverStatus'].toString())
          : json['driver_status'] != null
              ? DriverStatus.fromString(json['driver_status'].toString())
              : null,
      gender: json['gender'] != null
          ? Gender.fromString(json['gender'].toString())
          : null,
      isEmailVerified: _toBool(json['isEmailVerified'] ?? json['is_email_verified']),
      isPhoneVerified: _toBool(json['isPhoneVerified'] ?? json['is_phone_verified']),
      isProfileComplete: _toBool(json['isProfileComplete'] ?? json['is_profile_complete']),
      rating: _toDouble(json['rating']),
      totalDeliveries: _toInt(json['totalDeliveries'] ?? json['total_deliveries']),
      completedDeliveries: _toInt(json['completedDeliveries'] ?? json['completed_deliveries']),
      cancelledDeliveries: _toInt(json['cancelledDeliveries'] ?? json['cancelled_deliveries']),
      createdAt: _toDateTime(json['createdAt'] ?? json['created_at']) ?? DateTime.now(),
      updatedAt: _toDateTime(json['updatedAt'] ?? json['updated_at']),
      lastLogin: _toDateTime(json['lastLogin'] ?? json['last_login']),
      lastActiveAt: _toDateTime(json['lastActiveAt'] ?? json['last_active_at']),
    );
  }

  factory User.fromDatabaseRow(List<dynamic> row) {
    // Ordre des colonnes:
    // 0: id, 1: email, 2: phone, 3: full_name, 4: password_hash,
    // 5: role, 6: status, 7: address, 8: city, 9: region, 10: country,
    // 11: vehicle_plate, 12: vehicle_model, 13: vehicle_color, 14: vehicle_year,
    // 15: driver_status, 16: pin, 17: garage_id, 18: garage_name, 19: profile_photo,
    // 20: is_email_verified, 21: is_phone_verified, 22: is_profile_complete,
    // 23: rating, 24: total_deliveries, 25: completed_deliveries, 26: cancelled_deliveries,
    // 27: gender, 28: created_at, 29: updated_at, 30: last_login, 31: last_active_at

    String? _safeString(dynamic value) {
      if (value == null) return null;
      if (value is String) return value.isEmpty ? null : value;
      return value.toString();
    }

    int? _safeInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
        return parsed;
      }
      return null;
    }

    double? _safeDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        return parsed;
      }
      return null;
    }

    bool _safeBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) {
        final str = value.toLowerCase();
        return str == 'true' || str == '1';
      }
      return false;
    }

    DateTime? _safeDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    return User(
      id: row[0] as String,
      email: row[1] as String,
      phone: row[2] as String,
      fullName: row[3] as String,
      passwordHash: _safeString(row[4]),
      role: UserRole.fromString(row[5] as String? ?? 'client'),
      status: UserStatus.fromString(row[6] as String? ?? 'active'),
      address: _safeString(row[7]),
      city: _safeString(row[8]),
      region: _safeString(row[9]),
      country: _safeString(row[10]),
      vehiclePlate: _safeString(row[11]),
      vehicleModel: _safeString(row[12]),
      vehicleColor: _safeString(row[13]),
      vehicleYear: _safeInt(row[14]),
      driverStatus: row[15] != null ? DriverStatus.fromString(row[15].toString()) : null,
      pin: _safeString(row[16]),
      garageId: _safeString(row[17]),
      garageName: _safeString(row[18]),
      profilePhoto: _safeString(row[19]), // ✅ profile_photo
      isEmailVerified: _safeBool(row[20]),
      isPhoneVerified: _safeBool(row[21]),
      isProfileComplete: _safeBool(row[22]),
      rating: _safeDouble(row[23]),
      totalDeliveries: _safeInt(row[24]),
      completedDeliveries: _safeInt(row[25]),
      cancelledDeliveries: _safeInt(row[26]),
      gender: row[27] != null ? Gender.fromString(row[27].toString()) : null,
      createdAt: _safeDateTime(row[28]) ?? DateTime.now(),
      updatedAt: _safeDateTime(row[29]),
      lastLogin: _safeDateTime(row[30]),
      lastActiveAt: _safeDateTime(row[31]),
    );
  }

  // ==================== TO JSON ====================

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'phone': phone,
    'fullName': fullName,
    'role': role.value,
    'status': status.value,
    'pin': pin,
    'profilePhoto': profilePhoto,
    'address': address,
    'city': city,
    'region': region,
    'country': country,
    'garageId': garageId,
    'garageName': garageName,
    'vehiclePlate': vehiclePlate,
    'vehicleModel': vehicleModel,
    'vehicleColor': vehicleColor,
    'vehicleYear': vehicleYear,
    'driverStatus': driverStatus?.value,
    'gender': gender?.value,
    'isEmailVerified': isEmailVerified,
    'isPhoneVerified': isPhoneVerified,
    'isProfileComplete': isProfileComplete,
    'rating': rating,
    'totalDeliveries': totalDeliveries,
    'completedDeliveries': completedDeliveries,
    'cancelledDeliveries': cancelledDeliveries,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'lastLogin': lastLogin?.toIso8601String(),
    'lastActiveAt': lastActiveAt?.toIso8601String(),
  };

  // ==================== METHODES STATIQUES DE CONVERSION ====================

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static bool _toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final str = value.toLowerCase();
      return str == 'true' || str == '1';
    }
    return false;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  // ==================== PROPRIÉTÉS CALCULÉES ====================

  bool get isActive => status == UserStatus.active;
  bool get isSuspended => status == UserStatus.suspended;
  bool get isDeleted => status == UserStatus.deleted;

  bool get isSuperAdmin => role == UserRole.superAdmin;
  bool get isAdmin => role == UserRole.admin;
  bool get isDriver => role == UserRole.driver;
  bool get isClient => role == UserRole.client;

  bool get hasPin => pin != null && pin!.isNotEmpty;
  bool get hasProfilePhoto => profilePhoto != null && profilePhoto!.isNotEmpty;
  bool get hasVehicleInfo => vehiclePlate != null || vehicleModel != null;

  String get vehicleInfo {
    final parts = <String>[];
    if (vehiclePlate != null && vehiclePlate!.isNotEmpty) parts.add(vehiclePlate!);
    if (vehicleModel != null && vehicleModel!.isNotEmpty) parts.add(vehicleModel!);
    if (vehicleColor != null && vehicleColor!.isNotEmpty) parts.add(vehicleColor!);
    return parts.join(' - ');
  }

  String get formattedRating => rating?.toStringAsFixed(1) ?? 'N/A';
  String get formattedTotalDeliveries => totalDeliveries?.toString() ?? '0';

  double get successRate {
    if (totalDeliveries == null || totalDeliveries == 0) return 0.0;
    final completed = completedDeliveries ?? 0;
    return completed / totalDeliveries!;
  }

  String get formattedSuccessRate => '${(successRate * 100).toStringAsFixed(0)}%';

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  String get formattedPhone {
    String rawPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (rawPhone.startsWith('221') && rawPhone.length > 9) {
      return '+${rawPhone.substring(0, 3)} ${rawPhone.substring(3, 6)} ${rawPhone.substring(6, 8)} ${rawPhone.substring(8, 10)}';
    }
    if (rawPhone.startsWith('77') && rawPhone.length == 9) {
      return '+221 $rawPhone';
    }
    return phone;
  }

  // ==================== COPY WITH ====================

  User copyWith({
    String? id,
    String? email,
    String? phone,
    String? fullName,
    String? passwordHash,
    UserRole? role,
    UserStatus? status,
    String? pin,
    String? profilePhoto,
    String? address,
    String? city,
    String? region,
    String? country,
    String? garageId,
    String? garageName,
    String? vehiclePlate,
    String? vehicleModel,
    String? vehicleColor,
    int? vehicleYear,
    DriverStatus? driverStatus,
    Gender? gender,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    bool? isProfileComplete,
    double? rating,
    int? totalDeliveries,
    int? completedDeliveries,
    int? cancelledDeliveries,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLogin,
    DateTime? lastActiveAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      passwordHash: passwordHash ?? this.passwordHash,
      role: role ?? this.role,
      status: status ?? this.status,
      pin: pin ?? this.pin,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      address: address ?? this.address,
      city: city ?? this.city,
      region: region ?? this.region,
      country: country ?? this.country,
      garageId: garageId ?? this.garageId,
      garageName: garageName ?? this.garageName,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      vehicleYear: vehicleYear ?? this.vehicleYear,
      driverStatus: driverStatus ?? this.driverStatus,
      gender: gender ?? this.gender,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      rating: rating ?? this.rating,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      completedDeliveries: completedDeliveries ?? this.completedDeliveries,
      cancelledDeliveries: cancelledDeliveries ?? this.cancelledDeliveries,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLogin: lastLogin ?? this.lastLogin,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, fullName: $fullName, role: ${role.value})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}