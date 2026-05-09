import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:logging/logging.dart';
import '../lib/routes/api.dart';

void main() async {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.message}');
  });

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addHandler(ApiRouter.router);

  final server = await serve(handler, 'localhost', 8080);
  
  print('');
  print('╔════════════════════════════════════════════════════════════╗');
  print('║                     PRO COLIS BACKEND                      ║');
  print('╠════════════════════════════════════════════════════════════╣');
  print('║ 🚀 Serveur démarré sur http://localhost:${server.port}    ║');
  print('║ ✅ Health check: http://localhost:${server.port}/health    ║');
  print('╚════════════════════════════════════════════════════════════╝');
}
