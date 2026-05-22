import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:logging/logging.dart';
import 'package:procolis_backend/middleware/cors_middleware.dart';
import 'package:procolis_backend/middleware/static_middleware.dart';
import 'package:procolis_backend/routes/index.dart';
import 'package:procolis_backend/services/database_service.dart';
import 'package:procolis_backend/services/email_service.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_static/shelf_static.dart';

void main() async {
  // ================= LOGS =================
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  // ================= DB =================
  print('🔄 Initialisation de la base de données...');
  final db = await DatabaseService.getInstance();

  if (!db.isConnected) {
    print('❌ Base de données non connectée!');
    return;
  }

  print('✅ Base de données initialisée');

  // ================= ENV =================
  var env = DotEnv(includePlatformEnvironment: true)..load();

  // ================= EMAIL =================
  final emailService = EmailService(
    smtpHost: env['SMTP_HOST'] ?? 'smtp.gmail.com',
    smtpPort: int.parse(env['SMTP_PORT'] ?? '587'),
    smtpSecure: env['SMTP_SECURE'] == 'true',
    smtpUser: env['SMTP_USER'] ?? '',
    smtpPass: env['SMTP_PASS'] ?? '',
    smtpFrom: env['SMTP_FROM'] ?? 'PRO COLIS <noreply@proscolis.sn>',
  );

  print('📧 Email configuré');

  // ================= ROUTER =================
  final router = AppRoutes.createRouter(emailService: emailService);

  // ================= UPLOADS DIR =================
  final uploadsDir = Directory('uploads');

  if (!await uploadsDir.exists()) {
    await uploadsDir.create(recursive: true);
    print('📁 Dossier uploads créé');
  }

  print("📁 STATIC PATH: ${uploadsDir.path}");
  print("📁 EXISTS: ${await uploadsDir.exists()}");

  // ================= STATIC HANDLER =================
  final staticHandler = createStaticHandler(
    'uploads',
    listDirectories: false,
  );

  // ================= PIPELINE =================
  final handler = const Pipeline()
    .addMiddleware(logRequests())
    .addMiddleware(corsMiddleware())
    .addMiddleware(staticFilesMiddleware())
    .addHandler(router);

      print("CWD = ${Directory.current.path}");
print("ABS uploads = ${Directory('uploads').absolute.path}");
print("EXISTS = ${Directory('uploads').existsSync()}");
print("FILES = ${Directory('uploads/profile').listSync()}");

  // ================= SERVER =================
  final port = int.parse(env['PORT'] ?? '8080');
  final server = await serve(handler, '0.0.0.0', port);

  print('');
  print('🚀 PRO COLIS BACKEND v2.0');
  print('👉 http://localhost:${server.port}');
  print('📁 STATIC: http://localhost:${server.port}/uploads/');
}