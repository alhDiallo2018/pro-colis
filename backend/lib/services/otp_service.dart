// ignore_for_file: unused_local_variable

import 'dart:math';

import '../services/jwt_service.dart';

enum OtpType {
  login,
  verification,
  passwordReset,
}

class OtpCode {
  final String id;
  final String userId;
  final String code;
  final OtpType type;
  final String? phone;
  final String? email;
  bool isUsed;
  final DateTime expiresAt;
  final DateTime createdAt;
  int attempts;

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
}

class OtpService {
  final List<OtpCode> _otpCodes = [];
  
  String _generateCode() {
    final random = Random.secure();
    return (100000 + random.nextInt(900000)).toString();
  }
  
  Future<OtpCode> sendOtp({
    required String userId,
    required OtpType type,
    String? phone,
    String? email,
    bool resend = false,
  }) async {
    // Invalider les anciens OTP
    _invalidateOldOtps(userId, type);
    
    final code = _generateCode();
    final expiresAt = DateTime.now().add(const Duration(minutes: 10));
    final otpId = DateTime.now().millisecondsSinceEpoch.toString();
    
    final otp = OtpCode(
      id: otpId,
      userId: userId,
      code: code,
      type: type,
      phone: phone,
      email: email,
      expiresAt: expiresAt,
      createdAt: DateTime.now(),
    );
    
    _otpCodes.add(otp);
    
    print('�� OTP généré pour user $userId: $code (valable 10 min)');
    
    return otp;
  }
  
  Future<Map<String, dynamic>> verifyOtp({
    required String userId,
    required String code,
    required OtpType type,
  }) async {
    // Récupérer l'OTP actif
    final otpList = _otpCodes.where((o) => 
      o.userId == userId && 
      o.type == type && 
      !o.isUsed && 
      o.expiresAt.isAfter(DateTime.now())
    ).toList()
     ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    if (otpList.isEmpty) {
      return {'success': false, 'message': 'Aucun code OTP valide trouvé'};
    }
    
    final otp = otpList.first;
    
    // Vérifier les tentatives
    if (otp.attempts >= 5) {
      otp.isUsed = true;
      return {'success': false, 'message': 'Trop de tentatives, demandez un nouveau code'};
    }
    
    // Vérifier le code
    if (otp.code != code) {
      otp.attempts++;
      final remainingAttempts = 4 - otp.attempts;
      return {
        'success': false,
        'message': 'Code incorrect, $remainingAttempts tentative(s) restante(s)',
        'remainingAttempts': remainingAttempts,
      };
    }
    
    // Valider l'OTP
    otp.isUsed = true;
    
    // Générer les tokens JWT
    final accessToken = JwtService.generateToken(userId, const Duration(hours: 24), role: 'client');
    final refreshToken = JwtService.generateToken(userId, const Duration(days: 30), role: 'client');
    
    return {
      'success': true,
      'message': 'Code OTP valide',
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }
  
  void _invalidateOldOtps(String userId, OtpType type) {
    for (final otp in _otpCodes) {
      if (otp.userId == userId && otp.type == type && !otp.isUsed) {
        otp.isUsed = true;
      }
    }
  }
  
  Future<Map<String, dynamic>> resendOtp({
    required String userId,
    required OtpType type,
  }) async {
    // Invalider les anciens
    _invalidateOldOtps(userId, type);
    
    // Trouver l'utilisateur pour obtenir phone/email
    // Dans une implémentation réelle, on récupérerait depuis la DB
    final otp = await sendOtp(
      userId: userId,
      type: type,
      resend: true,
    );
    
    return {
      'success': true,
      'message': 'Nouveau code envoyé',
    };
  }
}
