// lib/services/auth_service.dart
import 'dart:async';

import 'package:procolis_backend/models/user.dart';
import 'package:procolis_backend/services/database_service.dart';
import 'package:uuid/uuid.dart';

import '../utils/jwt_helper.dart';
import 'email_service.dart';

class AuthService {
  final EmailService _emailService;
  final _uuid = Uuid();

  // Stockage temporaire des OTP (en production, utiliser Redis)
  final Map<String, Map<String, dynamic>> _otpStorage = {};

  // Mapping des IDs de garage numériques vers des UUIDs valides
  final Map<String, String> _garageUuidMapping = {
    '1': '11111111-1111-1111-1111-111111111111',
    '2': '22222222-2222-2222-2222-222222222222',
    '3': '33333333-3333-3333-3333-333333333333',
    '4': '44444444-4444-4444-4444-444444444444',
    '5': '55555555-5555-5555-5555-555555555555',
  };

  AuthService({required EmailService emailService})
      : _emailService = emailService;

  // Méthode utilitaire pour convertir un garage ID en UUID valide
  String? _convertGarageIdToUuid(dynamic garageId) {
    if (garageId == null) return null;

    final garageIdStr = garageId.toString();
    if (garageIdStr.isEmpty) return null;

    // Si c'est déjà un UUID valide
    if (RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
            caseSensitive: false)
        .hasMatch(garageIdStr)) {
      return garageIdStr;
    }

    // Si c'est un ID numérique (1,2,3...), utiliser le mapping
    if (_garageUuidMapping.containsKey(garageIdStr)) {
      return _garageUuidMapping[garageIdStr];
    }

    // Sinon, générer un UUID basé sur l'ID
    // ignore: deprecated_member_use
    return _uuid.v5(Uuid.NAMESPACE_DNS, garageIdStr);
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final db = await DatabaseService.getInstance();
    final userId = _uuid.v4();

    try {
      print('📝 [REGISTER] Données reçues: $data');

      // Vérifier si l'email existe déjà
      final existingUser = await db.connection.execute(
        'SELECT id FROM users WHERE email = \$1',
        parameters: [data['email']],
      );

      if (existingUser.isNotEmpty) {
        return {'success': false, 'message': 'Cet email est déjà utilisé'};
      }

      // Vérifier si le téléphone existe déjà
      final existingPhone = await db.connection.execute(
        'SELECT id FROM users WHERE phone = \$1',
        parameters: [data['phone']],
      );

      if (existingPhone.isNotEmpty) {
        return {
          'success': false,
          'message': 'Ce numéro de téléphone est déjà utilisé'
        };
      }

      // Convertir le garage_id en UUID valide
      final garageUuid = _convertGarageIdToUuid(data['garageId']);
      print(
          '🏢 [REGISTER] Garage ID: ${data['garageId']} -> UUID: $garageUuid');

      // Générer un OTP qui servira de PIN par défaut
      final defaultOtp = (100000 + _uuid.v4().hashCode % 900000).toString();

      // Nettoyer les valeurs null
      final address = _getStringValue(data, 'address');
      final city = _getStringValue(data, 'city');
      final region = _getStringValue(data, 'region');
      final vehiclePlate = _getStringValue(data, 'vehiclePlate');
      final vehicleModel = _getStringValue(data, 'vehicleModel');
      final vehicleColor = _getStringValue(data, 'vehicleColor');
      final vehicleYear = _getIntValue(data, 'vehicleYear');
      final role = _getStringValue(data, 'role') ?? 'client';

      print('🏢 [REGISTER] Données traitées:');
      print('   vehiclePlate: $vehiclePlate');
      print('   vehicleModel: $vehicleModel');
      print('   vehicleColor: $vehicleColor');
      print('   vehicleYear: $vehicleYear');
      print('   OTP/PIN par défaut: $defaultOtp');

      // Créer l'utilisateur avec l'OTP comme PIN par défaut
      await db.connection.execute('''
        INSERT INTO users (
          id, email, phone, full_name, role, pin, 
          address, city, region, 
          vehicle_plate, vehicle_model, vehicle_color, vehicle_year,
          garage_id, driver_status, created_at, updated_at
        )
        VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10, \$11, \$12, \$13, \$14, \$15, NOW(), NOW())
      ''', parameters: [
        userId,
        data['email'],
        data['phone'],
        data['fullName'],
        role,
        defaultOtp, // L'OTP devient le PIN par défaut
        address,
        city,
        region,
        vehiclePlate,
        vehicleModel,
        vehicleColor,
        vehicleYear,
        garageUuid,
        _getStringValue(data, 'driverStatus') ?? 'offline'
      ]);

      print('✅ [REGISTER] Utilisateur créé avec succès: $userId');

      // Stocker l'OTP pour vérification
      final expiresAt = DateTime.now().add(Duration(minutes: 10));
      _otpStorage[userId] = {
        'code': defaultOtp,
        'expiresAt': expiresAt.toIso8601String(),
        'type': 'login',
        'attempts': 0
      };

      // Envoyer l'email avec l'OTP (qui est aussi le PIN)
      unawaited(
          _emailService.sendOtpCode(data['email'], defaultOtp).then((success) {
        if (success) {
          print('✅ [REGISTER] Email envoyé avec OTP/PIN: $defaultOtp');
        } else {
          print(
              '⚠️ [REGISTER] Échec envoi email, mais OTP stocké: $defaultOtp');
        }
      }).catchError((error) {
        print('❌ [REGISTER] Erreur envoi email: $error');
      }));

      // Récupérer l'utilisateur créé
      final userResult = await db.connection.execute(
        'SELECT * FROM users WHERE id = \$1',
        parameters: [userId],
      );

      if (userResult.isEmpty) {
        return {
          'success': false,
          'message': 'Erreur lors de la récupération de l\'utilisateur'
        };
      }

      final user = User.fromDatabaseRow(userResult.first);

      return {
        'success': true,
        'message':
            'Inscription réussie. Votre code OTP/PIN a été envoyé par email.',
        'userId': userId,
        'user': user.toJson()
      };
    } catch (e) {
      print('❌ [REGISTER] Erreur: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> sendOtp(String identifier) async {
    final db = await DatabaseService.getInstance();
    final otp = (100000 + _uuid.v4().hashCode % 900000).toString();
    final expiresAt = DateTime.now().add(Duration(minutes: 5));

    try {
      print('📧 [OTP] Envoi OTP pour: $identifier');

      // Vérifier si l'utilisateur existe
      final user = await db.connection.execute(
        'SELECT id, email, phone, full_name FROM users WHERE email = \$1 OR phone = \$1',
        parameters: [identifier],
      );

      if (user.isEmpty) {
        print('❌ [OTP] Utilisateur non trouvé: $identifier');
        return {'success': false, 'message': 'Utilisateur non trouvé'};
      }

      final userId = user.first[0] as String;
      final email = user.first[1] as String;
      // ignore: unused_local_variable
      final fullName = user.first[3] as String? ?? 'Client';

      print('📧 [OTP] Utilisateur trouvé: $email, OTP: $otp');

      // Stocker l'OTP AVANT d'envoyer l'email
      _otpStorage[userId] = {
        'code': otp,
        'expiresAt': expiresAt.toIso8601String(),
        'type': 'login',
        'attempts': 0
      };

      // Envoyer l'email de manière asynchrone (ne pas bloquer la réponse)
      // Utiliser un completer pour ne pas attendre
      unawaited(_emailService.sendOtpCode(email, otp).then((success) {
        if (success) {
          print('✅ [OTP] Email envoyé avec succès à $email (OTP: $otp)');
        } else {
          print('⚠️ [OTP] Échec envoi email à $email, mais OTP est stocké');
        }
      }).catchError((error) {
        print('❌ [OTP] Erreur lors de l\'envoi email: $error');
      }));

      // Répondre immédiatement sans attendre l'email
      print(
          '✅ [OTP] Réponse immédiate pour $email (envoi email en arrière-plan)');

      return {
        'success': true,
        'message': 'OTP envoyé avec succès',
        'userId': userId
      };
    } catch (e) {
      print('❌ [OTP] Erreur: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> verifyOtp(
      String userId, String code, String type) async {
    print('🔐 [VERIFY] Vérification OTP pour userId: $userId, code: $code');

    final stored = _otpStorage[userId];

    if (stored == null) {
      print('❌ [VERIFY] Aucun OTP trouvé pour userId: $userId');
      return {
        'success': false,
        'message': 'Aucun OTP trouvé. Veuillez demander un nouveau code.'
      };
    }

    // Vérifier les tentatives
    final attempts = stored['attempts'] as int? ?? 0;
    if (attempts >= 3) {
      _otpStorage.remove(userId);
      print('❌ [VERIFY] Trop de tentatives pour userId: $userId');
      return {
        'success': false,
        'message': 'Trop de tentatives. Veuillez demander un nouveau code.'
      };
    }

    final expiresAt = DateTime.parse(stored['expiresAt']);
    if (DateTime.now().isAfter(expiresAt)) {
      _otpStorage.remove(userId);
      print('❌ [VERIFY] OTP expiré pour userId: $userId');
      return {
        'success': false,
        'message': 'OTP expiré. Veuillez demander un nouveau code.'
      };
    }

    if (stored['code'] != code) {
      stored['attempts'] = attempts + 1;
      print('❌ [VERIFY] Code incorrect. Tentative ${attempts + 1}/3');
      return {
        'success': false,
        'message': 'Code incorrect. Il vous reste ${2 - attempts} tentative(s).'
      };
    }

    // Générer le token
    final token = JwtHelper.generateToken(userId);
    _otpStorage.remove(userId);

    print('✅ [VERIFY] OTP validé avec succès pour userId: $userId');

    // Récupérer toutes les infos utilisateur
    final db = await DatabaseService.getInstance();
    final userResult = await db.connection.execute(
      'SELECT * FROM users WHERE id = \$1',
      parameters: [userId],
    );

    if (userResult.isEmpty) {
      print('❌ [VERIFY] Utilisateur non trouvé après validation OTP: $userId');
      return {'success': false, 'message': 'Utilisateur non trouvé'};
    }

    final user = User.fromDatabaseRow(userResult.first);

    // Mettre à jour last_login
    await db.connection.execute(
      'UPDATE users SET last_login = NOW() WHERE id = \$1',
      parameters: [userId],
    );

    print('✅ [VERIFY] Utilisateur authentifié: ${user.email}');

    return {'success': true, 'accessToken': token, 'user': user.toJson()};
  }

  Future<Map<String, dynamic>> loginWithPin(String pin, String identifier) async {
  final db = await DatabaseService.getInstance();

  try {
    print('🔐 [PIN_LOGIN] Tentative pour: $identifier avec PIN');
    
    // Chercher l'utilisateur par email OU téléphone ET par PIN
    final result = await db.connection.execute('''
      SELECT * FROM users 
      WHERE (email = \$1 OR phone = \$1) 
        AND pin = \$2 
        AND status = 'active'
    ''', parameters: [identifier, pin]);

    if (result.isEmpty) {
      print('❌ [PIN_LOGIN] Identifiant ou PIN incorrect');
      return {'success': false, 'message': 'Identifiant ou PIN incorrect'};
    }

    final user = User.fromDatabaseRow(result.first);
    final token = JwtHelper.generateToken(user.id);

    // Mettre à jour last_login
    await db.connection.execute(
      'UPDATE users SET last_login = NOW() WHERE id = \$1',
      parameters: [user.id],
    );

    print('✅ [PIN_LOGIN] Connexion réussie pour: ${user.email}');

    return {
      'success': true, 
      'accessToken': token, 
      'user': user.toJson()
    };
  } catch (e) {
    print('❌ [PIN_LOGIN] Erreur: $e');
    return {'success': false, 'message': e.toString()};
  }
}

  Future<Map<String, dynamic>> getUserById(String userId) async {
    final db = await DatabaseService.getInstance();

    try {
      final result = await db.connection.execute(
        'SELECT * FROM users WHERE id = \$1',
        parameters: [userId],
      );

      if (result.isEmpty) {
        return {'success': false, 'message': 'Utilisateur non trouvé'};
      }

      final user = User.fromDatabaseRow(result.first);

      return {'success': true, 'user': user.toJson()};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> changePin(
      String userId, String oldPin, String newPin) async {
    final db = await DatabaseService.getInstance();

    try {
      // Vérifier l'ancien PIN
      final result = await db.connection.execute(
        'SELECT id FROM users WHERE id = \$1 AND pin = \$2',
        parameters: [userId, oldPin],
      );

      if (result.isEmpty) {
        return {'success': false, 'message': 'PIN actuel incorrect'};
      }

      // Mettre à jour le nouveau PIN
      await db.connection.execute(
        'UPDATE users SET pin = \$1, updated_at = NOW() WHERE id = \$2',
        parameters: [newPin, userId],
      );

      return {'success': true, 'message': 'PIN modifié avec succès'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> resetPin(String email, String newPin) async {
    final db = await DatabaseService.getInstance();

    try {
      // Vérifier si l'utilisateur existe
      final result = await db.connection.execute(
        'SELECT id FROM users WHERE email = \$1',
        parameters: [email],
      );

      if (result.isEmpty) {
        return {'success': false, 'message': 'Email non trouvé'};
      }

      // Réinitialiser le PIN
      await db.connection.execute(
        'UPDATE users SET pin = \$1, updated_at = NOW() WHERE email = \$2',
        parameters: [newPin, email],
      );

      return {'success': true, 'message': 'PIN réinitialisé avec succès'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  String? _getStringValue(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) return null;
    if (value is String && value.isEmpty) return null;
    return value.toString();
  }

  int? _getIntValue(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) return null;
    if (value is int) return value;
    if (value is String && value.isNotEmpty) {
      return int.tryParse(value);
    }
    return null;
  }
}
