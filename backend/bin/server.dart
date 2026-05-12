import 'dart:convert';

import 'package:dotenv/dotenv.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import '../lib/controllers/admin_controller.dart';
import '../lib/controllers/auth_controller.dart';
import '../lib/controllers/garage_controller.dart';
import '../lib/controllers/parcel_controller.dart';
import '../lib/controllers/payment_controller.dart';
import '../lib/services/email_service.dart';

// Créer une instance de Uuid
final _uuid = Uuid();

void main() async {
  // Configuration du logging
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  // Chargement des variables d'environnement
  var env = DotEnv(includePlatformEnvironment: true)..load();

  // Initialisation des services
  final emailService = EmailService(
    smtpHost: env['SMTP_HOST'] ?? 'smtp.gmail.com',
    smtpPort: int.parse(env['SMTP_PORT'] ?? '587'),
    smtpSecure: env['SMTP_SECURE'] == 'true',
    smtpUser: env['SMTP_USER'] ?? '',
    smtpPass: env['SMTP_PASS'] ?? '',
    smtpFrom: env['SMTP_FROM'] ?? 'PRO COLIS <noreply@proscolis.sn>',
  );

  // Stockage partagé des utilisateurs
  final Map<String, Map<String, dynamic>> users = {};

  // Initialisation des contrôleurs
  final authController = AuthController(emailService: emailService, users: users);
  final parcelController = ParcelController(users: users);
  final paymentController = PaymentController();
  final garageController = GarageController();
  final adminController = AdminController(users: users);

  print('📧 Service email configuré avec: ${env['SMTP_USER']}');

  // Configuration du router
  final router = Router();
  
  // Monter toutes les routes
  router.mount('/auth', authController.router);
  router.mount('/parcels', parcelController.router);
  router.mount('/payments', paymentController.router);
  router.mount('/garages', garageController.router);
  router.mount('/admin', adminController.router);
  
  // Route pour voir les utilisateurs (debug)
  router.get('/debug/users', (Request request) {
    return Response.ok(jsonEncode({
      'success': true,
      'count': users.length,
      'users': users.values.toList(),
    }));
  });
  
  // Route de test email
  router.post('/test-email', (Request request) async {
    final success = await emailService.sendOtpCode(
      'alhassanegarki2018@gmail.com',
      '123456', 
      'test'
    );
    return Response.ok('{"success": $success}');
  });

  // Route de connexion par PIN
  router.post('/auth/login-with-pin', (Request request) async {
    final body = await request.readAsString();
    final data = jsonDecode(body);
    final pin = data['pin'];
    
    // Chercher l'utilisateur avec ce PIN
    String? userId;
    Map<String, dynamic>? user;
    
    for (var entry in users.entries) {
      if (entry.value['pin'] == pin) {
        userId = entry.key;
        user = entry.value;
        break;
      }
    }
    
    if (userId == null) {
      return Response.forbidden(jsonEncode({
        'success': false,
        'message': 'PIN incorrect',
      }));
    }
    
    return Response.ok(jsonEncode({
      'success': true,
      'message': 'Connexion réussie',
      'accessToken': 'token_$userId',
      'user': user,
    }));
  });
  
  router.get('/health', (Request request) {
    return Response.ok('{"status": "ok", "timestamp": "${DateTime.now()}"}');
  });
  
  router.get('/', (Request request) {
    return Response.ok('{"message": "PRO COLIS API is running", "version": "1.0.0"}');
  });

  // Route pour mettre à jour le profil utilisateur
  router.put('/users/profile', (Request request) async {
    final token = request.headers['Authorization']?.replaceFirst('Bearer ', '');
    if (token == null) {
      return Response.forbidden(jsonEncode({'success': false, 'message': 'Token manquant'}));
    }
    
    final body = await request.readAsString();
    final data = jsonDecode(body);
    
    final userId = token.split('_')[1];
    
    if (!users.containsKey(userId)) {
      return Response.notFound(jsonEncode({'success': false, 'message': 'Utilisateur non trouvé'}));
    }
    
    users[userId] = {
      ...users[userId]!,
      'fullName': data['fullName'],
      'email': data['email'],
      'phone': data['phone'],
      'address': data['address'],
      'city': data['city'],
      'region': data['region'],
      'vehiclePlate': data['vehiclePlate'],
      'vehicleModel': data['vehicleModel'],
    };
    
    return Response.ok(jsonEncode({
      'success': true,
      'message': 'Profil mis à jour',
      'user': users[userId],
    }));
  });

  // Route pour mettre à jour le PIN
  router.put('/users/pin', (Request request) async {
    final token = request.headers['Authorization']?.replaceFirst('Bearer ', '');
    if (token == null) {
      return Response.forbidden(jsonEncode({'success': false, 'message': 'Token manquant'}));
    }
    
    final body = await request.readAsString();
    final data = jsonDecode(body);
    
    final userId = token.split('_')[1];
    
    if (!users.containsKey(userId)) {
      return Response.notFound(jsonEncode({'success': false, 'message': 'Utilisateur non trouvé'}));
    }
    
    if (users[userId]!['pin'] != data['currentPin']) {
      return Response.forbidden(jsonEncode({'success': false, 'message': 'PIN actuel incorrect'}));
    }
    
    users[userId]!['pin'] = data['newPin'];
    
    return Response.ok(jsonEncode({
      'success': true,
      'message': 'PIN mis à jour avec succès',
    }));
  });

  // Route pour récupérer l'utilisateur courant
  router.get('/users/me', (Request request) async {
    final token = request.headers['Authorization']?.replaceFirst('Bearer ', '');
    if (token == null) {
      return Response.forbidden(jsonEncode({'success': false, 'message': 'Token manquant'}));
    }
    
    final userId = token.split('_')[1];
    
    if (!users.containsKey(userId)) {
      return Response.notFound(jsonEncode({'success': false, 'message': 'Utilisateur non trouvé'}));
    }
    
    return Response.ok(jsonEncode({
      'success': true,
      'user': users[userId],
    }));
  });

  // Admin: Récupérer tous les utilisateurs
  router.get('/admin/users', (Request request) async {
    final token = request.headers['Authorization']?.replaceFirst('Bearer ', '');
    if (token == null) {
      return Response.forbidden(jsonEncode({'success': false, 'message': 'Token manquant'}));
    }
    
    final usersList = users.values.map((user) {
      return {
        'id': user['id'],
        'email': user['email'],
        'phone': user['phone'],
        'fullName': user['fullName'],
        'role': user['role'],
        'status': user['status'] ?? 'active',
        'address': user['address'],
        'city': user['city'],
        'region': user['region'],
        'vehiclePlate': user['vehiclePlate'],
        'vehicleModel': user['vehicleModel'],
        'driverStatus': user['driverStatus'],
        'hasPin': user['pin'] != null,
        'isEmailVerified': user['isEmailVerified'] ?? false,
        'isPhoneVerified': user['isPhoneVerified'] ?? false,
        'createdAt': user['createdAt'],
        'lastLogin': user['lastLogin'],
      };
    }).toList();
    
    return Response.ok(jsonEncode({'success': true, 'users': usersList}));
  });

  // Admin: Créer un utilisateur
  router.post('/admin/users', (Request request) async {
    final token = request.headers['Authorization']?.replaceFirst('Bearer ', '');
    if (token == null) {
      return Response.forbidden(jsonEncode({'success': false, 'message': 'Token manquant'}));
    }
    
    final body = await request.readAsString();
    final data = jsonDecode(body);
    
    final userId = _uuid.v4();
    final pin = data['pin'] ?? '123456';
    
    users[userId] = {
      'id': userId,
      'email': data['email'],
      'phone': data['phone'],
      'fullName': data['fullName'],
      'role': data['role'] ?? 'client',
      'status': data['status'] ?? 'active',
      'address': data['address'],
      'city': data['city'],
      'region': data['region'],
      'pin': pin,
      'gender': data['gender'],
      'vehiclePlate': data['vehiclePlate'],
      'vehicleModel': data['vehicleModel'],
      'driverStatus': data['driverStatus'],
      'createdAt': DateTime.now().toIso8601String(),
      'isEmailVerified': false,
      'isPhoneVerified': false,
    };
    
    return Response.ok(jsonEncode({
      'success': true,
      'message': 'Utilisateur créé avec succès',
      'userId': userId,
      'pin': pin,
    }));
  });

  // Admin: Modifier un utilisateur
  router.put('/admin/users/<id>', (Request request, String id) async {
    final token = request.headers['Authorization']?.replaceFirst('Bearer ', '');
    if (token == null) {
      return Response.forbidden(jsonEncode({'success': false, 'message': 'Token manquant'}));
    }
    
    if (!users.containsKey(id)) {
      return Response.notFound(jsonEncode({'success': false, 'message': 'Utilisateur non trouvé'}));
    }
    
    final body = await request.readAsString();
    final data = jsonDecode(body);
    
    users[id] = {
      ...users[id]!,
      'fullName': data['fullName'],
      'email': data['email'],
      'phone': data['phone'],
      'role': data['role'],
      'status': data['status'],
      'address': data['address'],
      'city': data['city'],
      'region': data['region'],
      'vehiclePlate': data['vehiclePlate'],
      'vehicleModel': data['vehicleModel'],
      'driverStatus': data['driverStatus'],
      'updatedAt': DateTime.now().toIso8601String(),
    };
    
    return Response.ok(jsonEncode({'success': true, 'message': 'Utilisateur modifié'}));
  });

  // Admin: Changer le statut d'un utilisateur
  router.patch('/admin/users/<id>/status', (Request request, String id) async {
    final token = request.headers['Authorization']?.replaceFirst('Bearer ', '');
    if (token == null) {
      return Response.forbidden(jsonEncode({'success': false, 'message': 'Token manquant'}));
    }
    
    if (!users.containsKey(id)) {
      return Response.notFound(jsonEncode({'success': false, 'message': 'Utilisateur non trouvé'}));
    }
    
    final body = await request.readAsString();
    final data = jsonDecode(body);
    
    users[id]!['status'] = data['status'];
    users[id]!['updatedAt'] = DateTime.now().toIso8601String();
    
    return Response.ok(jsonEncode({'success': true, 'message': 'Statut mis à jour'}));
  });

  // Admin: Supprimer un utilisateur
  router.delete('/admin/users/<id>', (Request request, String id) async {
    final token = request.headers['Authorization']?.replaceFirst('Bearer ', '');
    if (token == null) {
      return Response.forbidden(jsonEncode({'success': false, 'message': 'Token manquant'}));
    }
    
    if (!users.containsKey(id)) {
      return Response.notFound(jsonEncode({'success': false, 'message': 'Utilisateur non trouvé'}));
    }
    
    users.remove(id);
    
    return Response.ok(jsonEncode({'success': true, 'message': 'Utilisateur supprimé'}));
  });

  // Admin: Réinitialiser le PIN d'un utilisateur
  router.post('/admin/users/<id>/reset-pin', (Request request, String id) async {
    final token = request.headers['Authorization']?.replaceFirst('Bearer ', '');
    if (token == null) {
      return Response.forbidden(jsonEncode({'success': false, 'message': 'Token manquant'}));
    }
    
    if (!users.containsKey(id)) {
      return Response.notFound(jsonEncode({'success': false, 'message': 'Utilisateur non trouvé'}));
    }
    
    users[id]!['pin'] = '123456';
    users[id]!['updatedAt'] = DateTime.now().toIso8601String();
    
    return Response.ok(jsonEncode({'success': true, 'message': 'PIN réinitialisé à 123456'}));
  });

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addHandler(router.call);

  final port = int.parse(env['PORT'] ?? '8080');
  final server = await serve(handler, 'localhost', port);
  
  print('');
  print('╔════════════════════════════════════════════════════════════════════╗');
  print('║                         PRO COLIS BACKEND                          ║');
  print('╠════════════════════════════════════════════════════════════════════╣');
  print('║ 🚀 Serveur démarré sur http://localhost:${server.port}            ║');
  print('║ ✅ Health check: http://localhost:${server.port}/health            ║');
  print('║ 📧 Email configuré: ${env['SMTP_USER']}                            ║');
  print('╠════════════════════════════════════════════════════════════════════╣');
  print('║ 📋 Routes disponibles:                                             ║');
  print('║    🔐 AUTHENTIFICATION                                             ║');
  print('║      POST /auth/register     - Inscription                         ║');
  print('║      POST /auth/send-otp     - Envoyer OTP                         ║');
  print('║      POST /auth/verify-otp   - Vérifier OTP                        ║');
  print('║      POST /auth/login-with-pin - Connexion par PIN                 ║');
  print('║    👤 UTILISATEURS                                                 ║');
  print('║      GET  /users/me          - Mon profil                          ║');
  print('║      PUT  /users/profile     - Modifier profil                     ║');
  print('║      PUT  /users/pin         - Modifier PIN                        ║');
  print('║    📦 COLIS (dans ParcelController)                                ║');
  print('║      POST /parcels/create    - Créer un colis                      ║');
  print('║      GET  /parcels/my-parcels - Mes colis                          ║');
  print('║      GET  /parcels/driver/assigned - Colis assignés (chauffeur)    ║');
  print('║      GET  /parcels/track/:id - Suivre un colis                     ║');
  print('║      PUT  /parcels/:id/status - Mettre à jour statut               ║');
  print('║      PUT  /parcels/:id/assign-driver - Assigner chauffeur          ║');
  print('║      PUT  /parcels/:id/cancel - Annuler un colis                   ║');
  print('║    💳 PAIEMENTS                                                    ║');
  print('║      POST /payments/init     - Initier paiement                    ║');
  print('║      GET  /payments/:id      - Statut paiement                     ║');
  print('║    🏢 GARAGES                                                      ║');
  print('║      GET  /garages           - Liste des garages                   ║');
  print('║      GET  /garages/:id       - Détail d\'un garage                  ║');
  print('║    👑 ADMIN                                                         ║');
  print('║      GET  /admin/users       - Liste des utilisateurs              ║');
  print('║      POST /admin/users       - Créer un utilisateur                ║');
  print('║      PUT  /admin/users/:id   - Modifier un utilisateur             ║');
  print('║      PATCH /admin/users/:id/status - Changer statut                ║');
  print('║      DELETE /admin/users/:id - Supprimer un utilisateur            ║');
  print('║      POST /admin/users/:id/reset-pin - Réinitialiser PIN           ║');
  print('╚════════════════════════════════════════════════════════════════════╝');
  print('');
}