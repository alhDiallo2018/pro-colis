// backend/lib/middleware/static_middleware.dart

import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_static/shelf_static.dart';

Middleware staticFilesMiddleware() {
  final uploadsPath = '${Directory.current.path}/uploads';

  print('📁 STATIC PATH: $uploadsPath');

  final staticHandler = createStaticHandler(
    uploadsPath,
    serveFilesOutsidePath: true,
    listDirectories: true,
  );

  return (Handler inner) {
    return (Request request) async {
      final path = request.url.path;

      // Exemple:
      // /uploads/profile/test.jpeg
      if (path.startsWith('uploads/')) {
        print('📸 STATIC FILE REQUEST: $path');

        // On enlève juste "uploads/"
        final relativePath = path.replaceFirst('uploads/', '');

        // Appel direct du fichier
        final file = File('$uploadsPath/$relativePath');

        print('📂 FILE PATH: ${file.path}');
        print('📂 EXISTS: ${await file.exists()}');

        if (await file.exists()) {
          return Response.ok(
            await file.readAsBytes(),
            headers: {
              'Content-Type': 'image/jpeg',
              'Access-Control-Allow-Origin': '*',
            },
          );
        }

        return Response.notFound('Fichier introuvable');
      }

      return inner(request);
    };
  };
}