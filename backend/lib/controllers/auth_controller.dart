import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../services/jwt_service.dart';
import '../services/otp_service.dart';
import '../services/user_service.dart';

class AuthController {
  final UserService _userService;
  final OtpService _otpService;

  AuthController({
    required UserService userService,
    required OtpService otpService,
  }) : _userService = userService,
       _otpService = otpService;

  Router get router {
    final router = Router();
    
    router.post('/register', _register);
    router.post('/send-otp', _sendOtp);
    router.post('/verify-otp', _verifyOtp);
    router.post('/resend-otp', _resendOtp);
    router.post('/refresh-token', _refreshToken);
    router.get('/me', _getCurrentUser);
    router.post('/logout', _logout);
    
    return router;
  }

  Future<Response> _register(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      
      // Validation
      if (data['email'] == null || data['phone'] == null || data['fullName'] == null) {
        return Response.badRequest(body: jsonEncode({
          'success': false,
          'message': 'Email, téléphone et nom complet requis'
        }));
      }
      
      // Vérifier si l'utilisateur existe déjà
      var existingUser = await _userService.findByEmail(data['email']);
      if (existingUser != null) {
        return Response(409, body: jsonEncode({
          'success': false,
          'message': 'Un utilisateur avec cet email existe déjà'
        }));
      }
      
      existingUser = await _userService.findByPhone(data['phone']);
      if (existingUser != null) {
        return Response(409, body: jsonEncode({
          'success': false,
          'message': 'Un utilisateur avec ce téléphone existe déjà'
        }));
      }
      
      // Créer l'utilisateur
      final user = await _userService.createUser(
        email: data['email'],
        phone: data['phone'],
        fullName: data['fullName'],
        password: data['password'],
        role: data['role'] ?? 'client',
      );
      
      // Envoyer OTP pour vérification
      await _otpService.sendOtp(
        userId: user.id,
        type: OtpType.verification,
        phone: user.phone,
        email: user.email,
      );
      
      return Response.ok(jsonEncode({
        'success': true,
        'message': 'Compte créé avec succès. Un code OTP a été envoyé.',
        'userId': user.id,
        'user': user.toJson(),
      }));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de l\'inscription: $e'
      }));
    }
  }

  Future<Response> _sendOtp(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      
      final identifier = data['identifier'];
      final typeStr = data['type'] ?? 'login';
      
      OtpType type;
      switch (typeStr) {
        case 'verification':
          type = OtpType.verification;
          break;
        case 'passwordReset':
          type = OtpType.passwordReset;
          break;
        default:
          type = OtpType.login;
      }
      
      // Trouver l'utilisateur
      User? user = await _userService.findByEmail(identifier);
      user ??= await _userService.findByPhone(identifier);
      
      if (user == null) {
        return Response.notFound(jsonEncode({
          'success': false,
          'message': 'Utilisateur non trouvé'
        }));
      }
      
      // Envoyer OTP
      final otp = await _otpService.sendOtp(
        userId: user.id,
        type: type,
        phone: user.phone,
        email: user.email,
      );
      
      return Response.ok(jsonEncode({
        'success': true,
        'message': 'Code OTP envoyé',
        'userId': user.id,
        'sentTo': otp.phone != null ? 'phone' : 'email',
      }));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de l\'envoi du code: $e'
      }));
    }
  }

  Future<Response> _verifyOtp(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      
      final userId = data['userId'];
      final code = data['code'];
      final typeStr = data['type'] ?? 'login';
      
      if (userId == null || code == null) {
        return Response.badRequest(body: jsonEncode({
          'success': false,
          'message': 'userId et code requis'
        }));
      }
      
      OtpType type;
      switch (typeStr) {
        case 'verification':
          type = OtpType.verification;
          break;
        case 'passwordReset':
          type = OtpType.passwordReset;
          break;
        default:
          type = OtpType.login;
      }
      
      final result = await _otpService.verifyOtp(
        userId: userId,
        code: code.toString(),
        type: type,
      );
      
      if (result['success'] == true) {
        // Mettre à jour la date de dernier login
        await _userService.updateLastLogin(userId);
        
        // Récupérer l'utilisateur
        final user = await _userService.getUser(userId);
        
        return Response.ok(jsonEncode({
          'success': true,
          'message': 'Authentification réussie',
          'accessToken': result['accessToken'],
          'refreshToken': result['refreshToken'],
          'user': user?.toJson(),
        }));
      } else {
        return Response(401, body: jsonEncode({
          'success': false,
          'message': result['message'],
          'remainingAttempts': result['remainingAttempts'],
        }));
      }
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de la vérification: $e'
      }));
    }
  }

  Future<Response> _resendOtp(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      
      final userId = data['userId'];
      final typeStr = data['type'] ?? 'login';
      
      if (userId == null) {
        return Response.badRequest(body: jsonEncode({
          'success': false,
          'message': 'userId requis'
        }));
      }
      
      OtpType type;
      switch (typeStr) {
        case 'verification':
          type = OtpType.verification;
          break;
        case 'passwordReset':
          type = OtpType.passwordReset;
          break;
        default:
          type = OtpType.login;
      }
      
      // ignore: unused_local_variable
      final result = await _otpService.resendOtp(
        userId: userId,
        type: type,
      );
      
      return Response.ok(jsonEncode({
        'success': true,
        'message': 'Nouveau code OTP envoyé',
      }));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({
        'success': false,
        'message': 'Erreur lors du renvoi: $e'
      }));
    }
  }

  Future<Response> _refreshToken(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      
      final refreshToken = data['refreshToken'];
      if (refreshToken == null) {
        return Response.badRequest(body: jsonEncode({
          'success': false,
          'message': 'refreshToken requis'
        }));
      }
      
      final newAccessToken = JwtService.refreshToken(refreshToken);
      if (newAccessToken == null) {
        return Response(401, body: jsonEncode({
          'success': false,
          'message': 'Refresh token invalide ou expiré'
        }));
      }
      
      return Response.ok(jsonEncode({
        'success': true,
        'accessToken': newAccessToken,
      }));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({
        'success': false,
        'message': 'Erreur lors du rafraîchissement: $e'
      }));
    }
  }

  Future<Response> _getCurrentUser(Request request) async {
    final authHeader = request.headers['Authorization'];
    
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response(401, body: jsonEncode({
        'success': false,
        'message': 'Token manquant'
      }));
    }
    
    final token = authHeader.substring(7);
    final payload = JwtService.verifyToken(token);
    
    if (payload == null) {
      return Response(401, body: jsonEncode({
        'success': false,
        'message': 'Token invalide'
      }));
    }
    
    final user = await _userService.getUser(payload['sub']);
    if (user == null) {
      return Response.notFound(jsonEncode({
        'success': false,
        'message': 'Utilisateur non trouvé'
      }));
    }
    
    return Response.ok(jsonEncode({
      'success': true,
      'user': user.toJson(),
    }));
  }

  Future<Response> _logout(Request request) async {
    // Dans une implémentation réelle, on invaliderait le token
    return Response.ok(jsonEncode({
      'success': true,
      'message': 'Déconnecté avec succès',
    }));
  }
}
