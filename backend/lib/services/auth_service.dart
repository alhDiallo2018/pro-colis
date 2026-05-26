// lib/services/auth_service.dart
import 'package:uuid/uuid.dart';

import '../utils/db_helper.dart';
import '../utils/jwt_helper.dart';
import 'email_service.dart';

class AuthService {
  final EmailService _emailService;
  final _uuid = Uuid();
  
  // Stockage temporaire des OTP (en production, utiliser Redis)
  final Map<String, Map<String, dynamic>> _otpStorage = {};
  
  AuthService({required EmailService emailService}) : _emailService = emailService;
  
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final db = await DbHelper.getInstance();
    final userId = _uuid.v4();
    
    try {
      // Vérifier si l'email existe déjà
      final existingUser = await db.connection.execute(
        'SELECT id FROM users WHERE email = \$1',
        parameters: [data['email']],
      );
      
      if (existingUser.isNotEmpty) {
        return {'success': false, 'message': 'Cet email est déjà utilisé'};
      }
      
      // Créer l'utilisateur
      await db.connection.execute('''
        INSERT INTO users (id, email, phone, full_name, role, pin, address, city, region, 
                           vehicle_plate, vehicle_model, garage_id, created_at, updated_at)
        VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10, \$11, \$12, NOW(), NOW())
      ''', parameters: [
        userId, data['email'], data['phone'], data['fullName'],
        data['role'] ?? 'client', data['pin'] ?? '123456',
        data['address'], data['city'], data['region'],
        data['vehiclePlate'], data['vehicleModel'], data['garageId']
      ]);
      
      return {
        'success': true,
        'message': 'Inscription réussie',
        'userId': userId
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
  
  Future<Map<String, dynamic>> sendOtp(String identifier) async {
    final db = await DbHelper.getInstance();
    final otp = (100000 + _uuid.v4().hashCode % 900000).toString();
    final expiresAt = DateTime.now().add(Duration(minutes: 5));
    
    try {
      // Vérifier si l'utilisateur existe
      final user = await db.connection.execute(
        'SELECT id, email, phone FROM users WHERE email = \$1 OR phone = \$1',
        parameters: [identifier],
      );
      
      if (user.isEmpty) {
        return {'success': false, 'message': 'Utilisateur non trouvé'};
      }
      
      final userId = user.first[0] as String;
      final email = user.first[1] as String;
      
      // Stocker l'OTP
      _otpStorage[userId] = {
        'code': otp,
        'expiresAt': expiresAt.toIso8601String(),
        'type': 'login'
      };
      
      // Envoyer l'email
      await _emailService.sendOtpCode(email, otp);
      
      return {
        'success': true,
        'message': 'OTP envoyé',
        'userId': userId
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
  
  Future<Map<String, dynamic>> verifyOtp(String userId, String code, String type) async {
    final stored = _otpStorage[userId];
    
    if (stored == null) {
      return {'success': false, 'message': 'Aucun OTP trouvé'};
    }
    
    final expiresAt = DateTime.parse(stored['expiresAt']);
    if (DateTime.now().isAfter(expiresAt)) {
      _otpStorage.remove(userId);
      return {'success': false, 'message': 'OTP expiré'};
    }
    
    if (stored['code'] != code) {
      return {'success': false, 'message': 'Code incorrect'};
    }
    
    // Générer le token
    final token = JwtHelper.generateToken(userId);
    _otpStorage.remove(userId);
    
    // Récupérer les infos utilisateur
    final db = await DbHelper.getInstance();
    final userResult = await db.connection.execute(
      'SELECT id, email, phone, full_name, role FROM users WHERE id = \$1',
      parameters: [userId],
    );
    
    final user = {
      'id': userResult.first[0],
      'email': userResult.first[1],
      'phone': userResult.first[2],
      'fullName': userResult.first[3],
      'role': userResult.first[4],
    };
    
    return {
      'success': true,
      'accessToken': token,
      'user': user
    };
  }
  
  Future<Map<String, dynamic>> loginWithPin(String pin) async {
    final db = await DbHelper.getInstance();
    
    try {
      final result = await db.connection.execute(
        'SELECT id, email, phone, full_name, role FROM users WHERE pin = \$1',
        parameters: [pin],
      );
      
      if (result.isEmpty) {
        return {'success': false, 'message': 'PIN incorrect'};
      }
      
      final userId = result.first[0] as String;
      final token = JwtHelper.generateToken(userId);
      
      final user = {
        'id': userId,
        'email': result.first[1],
        'phone': result.first[2],
        'fullName': result.first[3],
        'role': result.first[4],
      };
      
      return {
        'success': true,
        'accessToken': token,
        'user': user
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
