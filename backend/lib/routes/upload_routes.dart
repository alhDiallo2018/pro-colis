// backend/lib/routes/upload_routes.dart
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

class UploadRoutes {
  final _uuid = Uuid();
  
  Router get router {
    final router = Router();
    
    // Upload standard (multipart) - Mobile
    router.post('/', (Request request) async {
      try {
        // Pour l'instant, retourner une URL mock
        final fileId = _uuid.v4();
        final fileUrl = '/uploads/$fileId.jpg';
        
        return Response.ok(jsonEncode({
          'success': true,
          'url': fileUrl,
        }));
      } catch (e) {
        return Response.internalServerError(body: jsonEncode({
          'success': false,
          'message': e.toString()
        }));
      }
    });
    
    // Upload base64 - Web
    router.post('/base64', (Request request) async {
      try {
        final body = await request.readAsString();
        final data = jsonDecode(body);
        
        final base64Image = data['file'];
        final type = data['type'];
        final filename = data['filename'] ?? 'image.jpg';
        
        // Décoder base64
        final bytes = base64Decode(base64Image);
        
        // Créer le dossier si nécessaire
        final uploadDir = Directory('uploads/$type');
        if (!await uploadDir.exists()) {
          await uploadDir.create(recursive: true);
        }
        
        // Sauvegarder le fichier
        final fileId = _uuid.v4();
        final extension = filename.split('.').last;
        final filePath = '${uploadDir.path}/$fileId.$extension';
        
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        
        final fileUrl = '/uploads/$type/$fileId.$extension';
        
        print('✅ Fichier uploadé: $fileUrl');
        
        return Response.ok(jsonEncode({
          'success': true,
          'url': fileUrl,
          'fileId': fileId
        }));
      } catch (e) {
        print('❌ Erreur upload base64: $e');
        return Response.internalServerError(body: jsonEncode({
          'success': false,
          'message': e.toString()
        }));
      }
    });
    
    return router;
  }
}