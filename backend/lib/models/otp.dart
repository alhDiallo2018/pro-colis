// backend/lib/models/otp.dart
class OtpCode {
  final String id;
  final String userId;
  final String code;
  final OtpType type;
  final String? phone;
  final String? email;
  final bool isUsed;
  final DateTime expiresAt;
  final DateTime createdAt;
  final int attempts;

  OtpCode({
    required this.id,
    required this.userId,
    required this.code,
    required this.type,
    this.phone,
    this.email,
    this.isUsed = false,
    required this.expiresAt,
    required this.createdAt,
    this.attempts = 0,
  });

  bool get isValid => !isUsed && expiresAt.isAfter(DateTime.now()) && attempts < 5;

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'code': code,
    'type': type.name,
    'phone': phone,
    'email': email,
    'isUsed': isUsed,
    'expiresAt': expiresAt.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'attempts': attempts,
  };
}

enum OtpType {
  login('login'),
  verification('verification'),
  passwordReset('password_reset');

  final String name;
  const OtpType(this.name);
}