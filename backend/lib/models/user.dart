// backend/lib/models/user.dart
import 'package:uuid/uuid.dart';

class User {
  final String id;
  final String email;
  final String phone;
  final String fullName;
  final String? passwordHash;
  final UserRole role;
  final String? pin;
  final String? garageId;
  final String? garageName;
  final String? vehiclePlate;
  final String? vehicleModel;
  final String? vehicleColor;
  final int? vehicleYear;
  final String? address;
  final String? city;
  final String? region;
  final String? driverStatus;
  final String? profilePhotoUrl;
  final UserStatus status;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final bool isProfileComplete;
  final double? rating;
  final int? totalDeliveries;
  final int? completedDeliveries;
  final int? cancelledDeliveries;
  final String? gender;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final DateTime? lastActiveAt;
  final DateTime? updatedAt;

  User({
    String? id,
    required this.email,
    required this.phone,
    required this.fullName,
    this.passwordHash,
    required this.role,
    this.pin,
    this.garageId,
    this.garageName,
    this.vehiclePlate,
    this.vehicleModel,
    this.vehicleColor,
    this.vehicleYear,
    this.address,
    this.city,
    this.region,
    this.driverStatus,
    this.profilePhotoUrl,
    this.status = UserStatus.active,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.isProfileComplete = false,
    this.rating,
    this.totalDeliveries,
    this.completedDeliveries,
    this.cancelledDeliveries,
    this.gender,
    DateTime? createdAt,
    this.lastLogin,
    this.lastActiveAt,
    this.updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'phone': phone,
    'fullName': fullName,
    'role': role.name,
    'pin': pin,
    'garageId': garageId,
    'garageName': garageName,
    'vehiclePlate': vehiclePlate,
    'vehicleModel': vehicleModel,
    'vehicleColor': vehicleColor,
    'vehicleYear': vehicleYear,
    'address': address,
    'city': city,
    'region': region,
    'driverStatus': driverStatus,
    'profilePhotoUrl': profilePhotoUrl,
    'status': status.name,
    'isEmailVerified': isEmailVerified,
    'isPhoneVerified': isPhoneVerified,
    'isProfileComplete': isProfileComplete,
    'rating': rating,
    'totalDeliveries': totalDeliveries,
    'completedDeliveries': completedDeliveries,
    'cancelledDeliveries': cancelledDeliveries,
    'gender': gender,
    'createdAt': createdAt.toIso8601String(),
    'lastLogin': lastLogin?.toIso8601String(),
    'lastActiveAt': lastActiveAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    email: json['email'],
    phone: json['phone'],
    fullName: json['fullName'],
    passwordHash: json['passwordHash'],
    role: UserRole.values.firstWhere((e) => e.name == json['role']),
    pin: json['pin'],
    garageId: json['garageId'],
    garageName: json['garageName'],
    vehiclePlate: json['vehiclePlate'],
    vehicleModel: json['vehicleModel'],
    vehicleColor: json['vehicleColor'],
    vehicleYear: json['vehicleYear'],
    address: json['address'],
    city: json['city'],
    region: json['region'],
    driverStatus: json['driverStatus'],
    profilePhotoUrl: json['profilePhotoUrl'],
    status: UserStatus.values.firstWhere((e) => e.name == json['status']),
    isEmailVerified: json['isEmailVerified'] ?? false,
    isPhoneVerified: json['isPhoneVerified'] ?? false,
    isProfileComplete: json['isProfileComplete'] ?? false,
    rating: json['rating'] != null ? (json['rating'] is double ? json['rating'] : double.tryParse(json['rating'].toString())) : null,
    totalDeliveries: json['totalDeliveries'],
    completedDeliveries: json['completedDeliveries'],
    cancelledDeliveries: json['cancelledDeliveries'],
    gender: json['gender'],
    createdAt: DateTime.parse(json['createdAt']),
    lastLogin: json['lastLogin'] != null ? DateTime.parse(json['lastLogin']) : null,
    lastActiveAt: json['lastActiveAt'] != null ? DateTime.parse(json['lastActiveAt']) : null,
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
  );
  
  // Méthode utilitaire pour convertir un Object en int
  static int? _toInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  // Méthode utilitaire pour convertir un Object en double
  static double? _toDouble(Object? value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  // Méthode utilitaire pour convertir un Object en bool
  static bool _toBool(Object? value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }

  // Méthode utilitaire pour convertir un Object en DateTime
  static DateTime? _toDateTime(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Méthode utilitaire pour créer un User à partir d'une ligne de base de données
  factory User.fromDatabaseRow(List<dynamic> row) {
    // Ordre des colonnes dans la requête SQL:
    // 0: id, 1: email, 2: phone, 3: full_name, 4: password_hash,
    // 5: role, 6: status, 7: address, 8: city, 9: region,
    // 10: vehicle_plate, 11: vehicle_model, 12: driver_status, 13: pin, 14: garage_id,
    // 15: garage_name, 16: profile_photo_url, 17: is_email_verified, 18: is_phone_verified,
    // 19: is_profile_complete, 20: rating, 21: total_deliveries, 22: completed_deliveries,
    // 23: cancelled_deliveries, 24: gender, 25: created_at, 26: updated_at, 27: last_login, 28: last_active_at
    
    return User(
      id: row[0] as String,
      email: row[1] as String,
      phone: row[2] as String,
      fullName: row[3] as String,
      passwordHash: row[4] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.name == (row[5] as String? ?? 'client'),
        orElse: () => UserRole.client,
      ),
      status: UserStatus.values.firstWhere(
        (e) => e.name == (row[6] as String? ?? 'active'),
        orElse: () => UserStatus.active,
      ),
      address: row[7] as String?,
      city: row[8] as String?,
      region: row[9] as String?,
      vehiclePlate: row[10] as String?,
      vehicleModel: row[11] as String?,
      driverStatus: row[12] as String?,
      pin: row[13] as String?,
      garageId: row[14] as String?,
      garageName: row[15] as String?,
      profilePhotoUrl: row[16] as String?,
      isEmailVerified: _toBool(row[17]),
      isPhoneVerified: _toBool(row[18]),
      isProfileComplete: _toBool(row[19]),
      rating: _toDouble(row[20]),
      totalDeliveries: _toInt(row[21]),
      completedDeliveries: _toInt(row[22]),
      cancelledDeliveries: _toInt(row[23]),
      gender: row[24] as String?,
      createdAt: _toDateTime(row[25]) ?? DateTime.now(),
      updatedAt: _toDateTime(row[26]),
      lastLogin: _toDateTime(row[27]),
      lastActiveAt: _toDateTime(row[28]),
    );
  }

  // Propriétés calculées
  bool get isActive => status == UserStatus.active;
  bool get isSuspended => status == UserStatus.suspended;
  bool get isDeleted => status == UserStatus.deleted;
  
  bool get isSuperAdmin => role == UserRole.superAdmin;
  bool get isAdmin => role == UserRole.admin;
  bool get isDriver => role == UserRole.driver;
  bool get isClient => role == UserRole.client;
  
  bool get hasPin => pin != null && pin!.isNotEmpty;
  bool get hasProfilePhoto => profilePhotoUrl != null && profilePhotoUrl!.isNotEmpty;
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

  // Méthode pour mettre à jour les statistiques du chauffeur
  User updateDriverStats({int? newDelivery, bool completed = true}) {
    final newTotal = (totalDeliveries ?? 0) + (newDelivery ?? 0);
    final newCompleted = (completedDeliveries ?? 0) + (completed && newDelivery != null ? newDelivery : 0);
    final newRating = newCompleted > 0 ? (rating ?? 0) : rating;
    
    return copyWith(
      totalDeliveries: newTotal,
      completedDeliveries: newCompleted,
      rating: newRating,
    );
  }

  // Méthode copyWith pour les mises à jour immutables
  User copyWith({
    String? id,
    String? email,
    String? phone,
    String? fullName,
    String? passwordHash,
    UserRole? role,
    String? pin,
    String? garageId,
    String? garageName,
    String? vehiclePlate,
    String? vehicleModel,
    String? vehicleColor,
    int? vehicleYear,
    String? address,
    String? city,
    String? region,
    String? driverStatus,
    String? profilePhotoUrl,
    UserStatus? status,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    bool? isProfileComplete,
    double? rating,
    int? totalDeliveries,
    int? completedDeliveries,
    int? cancelledDeliveries,
    String? gender,
    DateTime? createdAt,
    DateTime? lastLogin,
    DateTime? lastActiveAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      passwordHash: passwordHash ?? this.passwordHash,
      role: role ?? this.role,
      pin: pin ?? this.pin,
      garageId: garageId ?? this.garageId,
      garageName: garageName ?? this.garageName,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      vehicleYear: vehicleYear ?? this.vehicleYear,
      address: address ?? this.address,
      city: city ?? this.city,
      region: region ?? this.region,
      driverStatus: driverStatus ?? this.driverStatus,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      status: status ?? this.status,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      rating: rating ?? this.rating,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      completedDeliveries: completedDeliveries ?? this.completedDeliveries,
      cancelledDeliveries: cancelledDeliveries ?? this.cancelledDeliveries,
      gender: gender ?? this.gender,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, fullName: $fullName, role: ${role.name})';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
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

// Statut du chauffeur
enum DriverStatus {
  available('available'),
  busy('busy'),
  offline('offline');

  final String name;
  const DriverStatus(this.name);
  
  String get label {
    switch (this) {
      case DriverStatus.available:
        return 'Disponible';
      case DriverStatus.busy:
        return 'En livraison';
      case DriverStatus.offline:
        return 'Hors ligne';
    }
  }
}

// Extension pour convertir String en DriverStatus
extension DriverStatusExtension on String {
  DriverStatus toDriverStatus() {
    switch (toLowerCase()) {
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