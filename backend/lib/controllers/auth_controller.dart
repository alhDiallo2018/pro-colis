import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';
import '../services/email_service.dart';

class AuthController {
  final EmailService emailService;
  final Map<String, Map<String, dynamic>> users;
  final _uuid = const Uuid();
  
  final Map<String, Map<String, dynamic>> _otps = {};

  AuthController({required this.emailService, required this.users});

  Router get router {
    final router = Router();
    
    router.post('/register', _register);
    router.post('/send-otp', _sendOtp);
    router.post('/verify-otp', _verifyOtp);
    
    return router;
  }

  Future<Response> _register(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      
      final userId = _uuid.v4();
      final user = {
        'id': userId,
        'email': data['email'],
        'phone': data['phone'],
        'fullName': data['fullName'],
        'password': data['password'],
        'role': 'client',
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      users[userId] = user;
      
      // Générer et envoyer OTP
      final otpCode = (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();
      _otps[userId] = {
        'code': otpCode,
        'expiresAt': DateTime.now().add(const Duration(minutes: 10)).toIso8601String(),
        'attempts': 0,
      };
      
      await emailService.sendOtpCode(data['email'], otpCode, 'verification');
      
      return Response.ok(jsonEncode({
        'success': true,
        'message': 'Compte créé avec succès',
        'userId': userId,
      }));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de l\'inscription: $e',
      }));
    }
  }

  Future<Response> _sendOtp(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final identifier = data['identifier'];
      
      String? userId;
      String? email;
      
      for (var entry in users.entries) {
        if (entry.value['email'] == identifier || entry.value['phone'] == identifier) {
          userId = entry.key;
          email = entry.value['email'];
          break;
        }
      }
      
      if (userId == null) {
        return Response.notFound(jsonEncode({
          'success': false,
          'message': 'Utilisateur non trouvé',
        }));
      }
      
      final otpCode = (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();
      _otps[userId] = {
        'code': otpCode,
        'expiresAt': DateTime.now().add(const Duration(minutes: 10)).toIso8601String(),
        'attempts': 0,
      };
      
      await emailService.sendOtpCode(email!, otpCode, 'login');
      
      return Response.ok(jsonEncode({
        'success': true,
        'message': 'Code OTP envoyé',
        'userId': userId,
      }));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de l\'envoi: $e',
      }));
    }
  }

  Future<Response> _verifyOtp(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final userId = data['userId'];
      final code = data['code'];
      
      final otpData = _otps[userId];
      
      if (otpData == null) {
        return Response.badRequest(body: jsonEncode({
          'success': false,
          'message': 'Aucun code OTP trouvé',
        }));
      }
      
      if (DateTime.now().isAfter(DateTime.parse(otpData['expiresAt']))) {
        return Response.badRequest(body: jsonEncode({
          'success': false,
          'message': 'Le code OTP a expiré',
        }));
      }
      
      if (otpData['attempts'] >= 5) {
        return Response.badRequest(body: jsonEncode({
          'success': false,
          'message': 'Trop de tentatives',
        }));
      }
      
      if (otpData['code'] != code) {
        _otps[userId] = {
          ...otpData,
          'attempts': otpData['attempts'] + 1,
        };
        return Response.badRequest(body: jsonEncode({
          'success': false,
          'message': 'Code OTP incorrect',
        }));
      }
      
      _otps.remove(userId);
      
      final user = users[userId];
      
      return Response.ok(jsonEncode({
        'success': true,
        'message': 'Authentification réussie',
        'accessToken': 'token_${user!['id']}',
        'refreshToken': 'refresh_${user['id']}',
        'user': user,
      }));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de la vérification: $e',
      }));
    }
  }
}
