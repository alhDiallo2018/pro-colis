// lib/routes/auth_routes.dart
import 'dart:convert';

import 'package:procolis_backend/services/database_service.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../services/auth_service.dart';
import '../services/email_service.dart';
import '../services/user_service.dart';
import '../utils/jwt_helper.dart';


class AuthRoutes {
  final AuthService _authService;
  final UserService _userService = UserService();

  AuthRoutes({required EmailService emailService})
      : _authService = AuthService(emailService: emailService);

  Router get router {
    final router = Router();

    // Route d'inscription
    router.post('/register', (Request request) async {
      try {
        final body = await request.readAsString();
        final data = jsonDecode(body);
        final result = await _authService.register(data);
        return Response.ok(jsonEncode(result));
      } catch (e) {
        return Response.internalServerError(
            body: jsonEncode({'success': false, 'message': e.toString()}));
      }
    });

    // Envoi OTP
    router.post('/send-otp', (Request request) async {
      try {
        final body = await request.readAsString();
        final data = jsonDecode(body);
        final result = await _authService.sendOtp(data['identifier']);
        return Response.ok(jsonEncode(result));
      } catch (e) {
        return Response.internalServerError(
            body: jsonEncode({'success': false, 'message': e.toString()}));
      }
    });

    // Vérification OTP
    router.post('/verify-otp', (Request request) async {
      try {
        final body = await request.readAsString();
        final data = jsonDecode(body);
        final result = await _authService.verifyOtp(
            data['userId'], data['code'], data['type']);
        return Response.ok(jsonEncode(result));
      } catch (e) {
        return Response.internalServerError(
            body: jsonEncode({'success': false, 'message': e.toString()}));
      }
    });

    // Login avec PIN
    router.post('/login-with-pin', (Request request) async {
      try {
        final body = await request.readAsString();
        final data = jsonDecode(body);
        final result = await _authService.loginWithPin(data['pin']);
        return Response.ok(jsonEncode(result));
      } catch (e) {
        return Response.internalServerError(
            body: jsonEncode({'success': false, 'message': e.toString()}));
      }
    });

    // Récupérer l'utilisateur connecté (après authentification)
    router.get('/me', (Request request) async {
      final userId = JwtHelper.extractUserId(request);
      if (userId == null) {
        return Response.forbidden(
            jsonEncode({'success': false, 'message': 'Non authentifié'}));
      }

      try {
        final db = await DatabaseService.getInstance();
        // Version sans vehicle_color et vehicle_year (colonnes qui n'existent pas)
        final result = await db.connection.execute('''
  SELECT 
    u.id,
    u.email,
    u.phone,
    u.full_name,
    u.role,
    u.status,
    u.address,
    u.city,
    u.region,
    u.vehicle_plate,
    u.vehicle_model,
    u.driver_status,
    u.garage_id,
    g.name AS garage_name,
    u.profile_photo,
    u.created_at,
    u.updated_at,
    u.last_login
  FROM users u
  LEFT JOIN garages g ON g.id = u.garage_id
  WHERE u.id = \$1
''', parameters: [userId]);

        if (result.isEmpty) {
          return Response.notFound(jsonEncode(
              {'success': false, 'message': 'Utilisateur non trouvé'}));
        }

        DateTime? toDate(dynamic v) {
          if (v == null) return null;
          if (v is DateTime) return v;
          return DateTime.tryParse(v.toString());
        }

        final row = result.first;
        final user = {
          'id': row[0],
          'email': row[1],
          'phone': row[2],
          'fullName': row[3],
          'role': row[4],
          'status': row[5],
          'address': row[6] ?? '',
          'city': row[7] ?? '',
          'region': row[8] ?? '',
          'vehiclePlate': row[9] ?? '',
          'vehicleModel': row[10] ?? '',
          'driverStatus': row[11],
          'garageId': row[12],
          'garageName': row[13], // 👈 IMPORTANT
          'profilePhoto': row[14],
          'createdAt': toDate(row[15])?.toIso8601String(),
          'updatedAt': toDate(row[16])?.toIso8601String(),
          'lastLogin': toDate(row[17])?.toIso8601String(),
        };

        print('✅ Utilisateur chargé: ${user}');

        return Response.ok(jsonEncode({'success': true, 'user': user}));
      } catch (e) {
        print('❌ Erreur /auth/me: $e');
        return Response.internalServerError(
            body: jsonEncode({'success': false, 'message': e.toString()}));
      }
    });

    // Logout
    router.post('/logout', (Request request) async {
      return Response.ok(
          jsonEncode({'success': true, 'message': 'Déconnexion réussie'}));
    });

    return router;
  }
}
