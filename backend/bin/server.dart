import 'dart:io';

import 'package:logging/logging.dart';
import 'package:procolis_backend/middleware/cors_middleware.dart';
import 'package:procolis_backend/middleware/static_middleware.dart';
import 'package:procolis_backend/routes/index.dart';
import 'package:procolis_backend/services/database_service.dart';
import 'package:procolis_backend/services/email_service.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';

void main() async {
  // ================= LOGS =================
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  // ================= ENVIRONNEMENT =================
  final isRender = Platform.environment['RENDER'] == 'true';
  final portEnv = Platform.environment['PORT'] ?? '8080';
  final port = int.parse(portEnv);
  final host = Platform.environment['HOST'] ?? '0.0.0.0';
  
  print('═══════════════════════════════════════════════════════════');
  print('🚀 PRO COLIS BACKEND v2.0');
  print('═══════════════════════════════════════════════════════════');
  print('🌍 Environnement: ${isRender ? 'RENDER (Production)' : 'LOCAL (Développement)'}');
  print('🔌 Port: $port');
  print('🏠 Host: $host');
  print('═══════════════════════════════════════════════════════════');

  // ================= BASE DE DONNÉES =================
  print('\n📊 CONFIGURATION BASE DE DONNÉES');
  print('─────────────────────────────────────────');
  
  // Priorité 1: Variables d'environnement Render
  // Priorité 2: Fichier .env (via DatabaseConfig)
  final db = await DatabaseService.getInstance();

  if (!db.isConnected) {
    print('❌ Base de données non connectée!');
    print('⚠️ Le serveur démarre sans base de données');
  } else {
    print('✅ Base de données connectée avec succès');
  }
  print('─────────────────────────────────────────');

  // ================= EMAIL =================
  print('\n📧 CONFIGURATION EMAIL');
  print('─────────────────────────────────────────');
  
  // Priorité 1: Variables d'environnement Render
  String smtpHost;
  int smtpPort;
  bool smtpSecure;
  String smtpUser;
  String smtpPass;
  String smtpFrom;
  
  if (isRender) {
    print('📧 Configuration depuis variables Render:');
    
    smtpHost = Platform.environment['SMTP_HOST'] ?? 'smtp.gmail.com';
    smtpPort = int.parse(Platform.environment['SMTP_PORT'] ?? '587');
    smtpSecure = Platform.environment['SMTP_SECURE'] == 'true';
    smtpUser = Platform.environment['SMTP_USER'] ?? 'alhassanegarki2018@gmail.com';
    smtpPass = Platform.environment['SMTP_PASS'] ?? 'izjbxackbgpdtmam';
    smtpFrom = Platform.environment['SMTP_FROM'] ?? 'PRO COLIS <noreply@proscolis.sn>';
    
    print('   SMTP_HOST: $smtpHost');
    print('   SMTP_PORT: $smtpPort');
    print('   SMTP_SECURE: $smtpSecure');
    print('   SMTP_USER: $smtpUser');
    print('   SMTP_FROM: $smtpFrom');
    print('   SMTP_PASS: ${smtpPass.isNotEmpty ? '✅ Configuré' : '❌ Manquant'}');
  } else {
    print('📧 Configuration locale - Chargement depuis .env');
    
    // En local, charger depuis .env via DatabaseConfig
    // Les valeurs par défaut seront utilisées si .env n'existe pas
    smtpHost = Platform.environment['SMTP_HOST'] ?? 'smtp.gmail.com';
    smtpPort = int.parse(Platform.environment['SMTP_PORT'] ?? '587');
    smtpSecure = Platform.environment['SMTP_SECURE'] == 'true';
    smtpUser = Platform.environment['SMTP_USER'] ?? 'alhassanegarki2018@gmail.com';
    smtpPass = Platform.environment['SMTP_PASS'] ?? 'izjbxackbgpdtmam';
    smtpFrom = Platform.environment['SMTP_FROM'] ?? 'PRO COLIS <noreply@proscolis.sn>';
    
    print('   SMTP_HOST: $smtpHost');
    print('   SMTP_PORT: $smtpPort');
    print('   SMTP_USER: ${smtpUser.isNotEmpty ? smtpUser : '❌ Non configuré'}');
    print('   SMTP_PASS: ${smtpPass.isNotEmpty ? '✅ Configuré' : '❌ Manquant'}');
  }
  
  // Vérification des credentials email
  if (smtpUser.isEmpty || smtpPass.isEmpty) {
    print('⚠️ ATTENTION: Credentials SMTP manquants!');
    print('   Les emails ne pourront pas être envoyés.');
    print('   Configurez SMTP_USER et SMTP_PASS dans .env ou les variables Render.');
  } else {
    print('✅ Configuration email complète');
  }
  
  final emailService = EmailService(
    smtpHost: smtpHost,
    smtpPort: smtpPort,
    smtpSecure: smtpSecure,
    smtpUser: smtpUser,
    smtpPass: smtpPass,
    smtpFrom: smtpFrom,
  );
  
  print('─────────────────────────────────────────');

  // ================= ROUTER =================
  print('\n🔄 INITIALISATION DES ROUTES');
  print('─────────────────────────────────────────');
  final router = AppRoutes.createRouter(emailService: emailService);
  print('✅ Routes initialisées');
  print('─────────────────────────────────────────');

  // ================= DOSSIERS UPLOADS =================
  print('\n📁 CONFIGURATION DES DOSSIERS');
  print('─────────────────────────────────────────');
  
  final uploadsDir = Directory('uploads');
  if (!await uploadsDir.exists()) {
    await uploadsDir.create(recursive: true);
    print('📁 Dossier uploads créé');
  }

  // Créer les sous-dossiers
  final parcelsDir = Directory('uploads/parcels');
  if (!await parcelsDir.exists()) {
    await parcelsDir.create(recursive: true);
    print('📁 Dossier uploads/parcels créé');
  }
  
  final profileDir = Directory('uploads/profile');
  if (!await profileDir.exists()) {
    await profileDir.create(recursive: true);
    print('📁 Dossier uploads/profile créé');
  }

  print('📁 STATIC PATH: ${uploadsDir.absolute.path}');
  print('─────────────────────────────────────────');

  // ================= PIPELINE =================
  print('\n🔧 CONFIGURATION DU SERVEUR');
  print('─────────────────────────────────────────');
  
  final handler = const Pipeline()
    .addMiddleware(logRequests())
    .addMiddleware(corsMiddleware())
    .addMiddleware(staticFilesMiddleware())
    .addHandler(router);

  print('✅ Middlewares configurés:');
  print('   - Logging');
  print('   - CORS');
  print('   - Static files');
  print('─────────────────────────────────────────');

  // ================= SERVEUR =================
  print('\n🚀 DÉMARRAGE DU SERVEUR');
  print('─────────────────────────────────────────');
  
  final server = await serve(handler, host, port);

  print('');
  print('═══════════════════════════════════════════════════════════');
  print('✅ SERVEUR PRÊT !');
  print('═══════════════════════════════════════════════════════════');
  print('🌐 URL: http://$host:${server.port}');
  if (host != '0.0.0.0') {
    print('🌐 Local: http://localhost:${server.port}');
  }
  print('📁 Static: http://$host:${server.port}/uploads/');
  print('');
  print('📋 Routes disponibles:');
  print('   🔓 PUBLIQUES:');
  print('      POST   /auth/register');
  print('      POST   /auth/send-otp');
  print('      POST   /auth/verify-otp');
  print('      POST   /auth/login-with-pin');
  print('      GET    /public/garages');
  print('      GET    /health');
  print('');
  print('   🔒 PROTÉGÉES:');
  print('      GET    /auth/me');
  print('      PUT    /auth/profile');
  print('      POST   /auth/logout');
  print('      /client/*');
  print('      /driver/*');
  print('      /garage-admin/*');
  print('      /super-admin/*');
  print('═══════════════════════════════════════════════════════════');
}