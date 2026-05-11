import 'dart:convert';

import 'package:dotenv/dotenv.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_router/shelf_router.dart';

import '../lib/controllers/admin_controller.dart';
import '../lib/controllers/auth_controller.dart';
import '../lib/controllers/garage_controller.dart';
import '../lib/controllers/parcel_controller.dart';
import '../lib/controllers/payment_controller.dart';
import '../lib/services/email_service.dart';

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
  // print('🏢 ${garageController.router.routes.length} garages disponibles');

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
  print('║    📦 COLIS                                                        ║');
  print('║      POST /parcels/create    - Créer un colis                      ║');
  print('║      GET  /parcels/my-parcels - Mes colis                          ║');
  print('║      GET  /parcels/track/:id - Suivre un colis                     ║');
  print('║    💳 PAIEMENTS                                                    ║');
  print('║      POST /payments/init     - Initier paiement                    ║');
  print('║      GET  /payments/:id      - Statut paiement                     ║');
  print('║    🏢 GARAGES                                                      ║');
  print('║      GET  /garages           - Liste des garages                   ║');
  print('║      GET  /garages/:id       - Détail d\'un garage                  ║');
  print('║    👑 ADMIN                                                         ║');
  print('║      GET  /admin/stats/overview - Statistiques                     ║');
  print('║      GET  /admin/users       - Liste des utilisateurs              ║');
  print('╚════════════════════════════════════════════════════════════════════╝');
  print('');
}




