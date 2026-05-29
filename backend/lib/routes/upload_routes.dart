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
    
    // ✅ Upload standard (multipart/form-data) - Pour Mobile
    router.post('/', (Request request) async {
      try {
        print('📤 [UPLOAD] Upload multipart reçu');
        
        // Vérifier le content-type
        final contentType = request.headers['content-type'] ?? '';
        if (!contentType.contains('multipart/form-data')) {
          return Response.badRequest(body: jsonEncode({
            'success': false,
            'message': 'Content-Type doit être multipart/form-data'
          }));
        }
        
        // Lire le corps de la requête
        final body = await request.readAsString();
        
        // Extraire la boundary
        final boundaryMatch = RegExp(r'boundary=(.+)').firstMatch(contentType);
        if (boundaryMatch == null) {
          return Response.badRequest(body: jsonEncode({
            'success': false,
            'message': 'Boundary non trouvé'
          }));
        }
        
        final boundary = boundaryMatch.group(1)!.replaceAll('"', '');
        
        // Parser manuellement le multipart
        String? type = 'general';
        List<int>? fileBytes;
        String? filename;
        
        // Séparer les parties par la boundary
        final parts = body.split('--$boundary');
        
        for (final part in parts) {
          if (part.trim().isEmpty || part.contains('--')) continue;
          
          // Extraire le nom du champ
          final nameMatch = RegExp(r'name="([^"]+)"').firstMatch(part);
          if (nameMatch == null) continue;
          
          final fieldName = nameMatch.group(1)!;
          
          // Extraire le filename si présent
          final filenameMatch = RegExp(r'filename="([^"]+)"').firstMatch(part);
          
          // Extraire le contenu (après les deux retours à la ligne)
          final contentMatch = RegExp(r'\r\n\r\n(.*?)(?=\r\n--|\Z)', dotAll: true).firstMatch(part);
          if (contentMatch == null) continue;
          
          String content = contentMatch.group(1)!;
          
          if (fieldName == 'type') {
            type = content.trim();
          } else if (fieldName == 'file') {
            if (filenameMatch != null) {
              filename = filenameMatch.group(1);
            }
            
            // Pour les fichiers, le contenu peut être brut
            // Enlever les retours à la ligne au début et à la fin
            content = content.replaceAll(RegExp(r'^\r\n'), '').replaceAll(RegExp(r'\r\n$'), '');
            fileBytes = utf8.encode(content);
          }
        }
        
        if (fileBytes == null) {
          return Response.badRequest(body: jsonEncode({
            'success': false,
            'message': 'Aucun fichier trouvé'
          }));
        }
        
        // Créer le dossier si nécessaire
        final uploadDir = Directory('uploads/$type');
        if (!await uploadDir.exists()) {
          await uploadDir.create(recursive: true);
        }
        
        // Générer un nom unique
        final extension = filename != null && filename.contains('.') 
            ? filename.split('.').last 
            : 'jpg';
        final uniqueName = '${_uuid.v4()}.$extension';
        final filePath = '${uploadDir.path}/$uniqueName';
        
        // Sauvegarder le fichier
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);
        
        final publicUrl = '/uploads/$type/$uniqueName';
        
        print('✅ [UPLOAD] Fichier uploadé: $publicUrl');
        
        return Response.ok(jsonEncode({
          'success': true,
          'url': publicUrl,
          'fileId': uniqueName
        }));
      } catch (e) {
        print('❌ [UPLOAD] Erreur: $e');
        print('Stack trace: ${StackTrace.current}');
        return Response.internalServerError(body: jsonEncode({
          'success': false,
          'message': e.toString()
        }));
      }
    });
    
    // ✅ Upload base64 - Pour Web (recommandé pour mobile aussi)
    router.post('/base64', (Request request) async {
      try {
        final body = await request.readAsString();
        final data = jsonDecode(body);
        
        final base64Image = data['file'];
        final type = data['type'] ?? 'general';
        final filename = data['filename'] ?? 'image.jpg';
        
        if (base64Image == null || base64Image.isEmpty) {
          return Response.badRequest(body: jsonEncode({
            'success': false,
            'message': 'Fichier manquant'
          }));
        }
        
        // Nettoyer le base64 (enlever le préfixe data:image/xxx;base64, si présent)
        String cleanBase64 = base64Image;
        if (base64Image.contains(',')) {
          cleanBase64 = base64Image.split(',').last;
        }
        
        // Décoder base64
        final bytes = base64Decode(cleanBase64);
        
        // Créer le dossier si nécessaire
        final uploadDir = Directory('uploads/$type');
        if (!await uploadDir.exists()) {
          await uploadDir.create(recursive: true);
        }
        
        // Sauvegarder le fichier
        final extension = filename.split('.').last;
        final uniqueName = '${_uuid.v4()}.$extension';
        final filePath = '${uploadDir.path}/$uniqueName';
        
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        
        final publicUrl = '/uploads/$type/$uniqueName';
        
        print('✅ [BASE64] Fichier uploadé: $publicUrl');
        
        return Response.ok(jsonEncode({
          'success': true,
          'url': publicUrl,
          'fileId': uniqueName
        }));
      } catch (e) {
        print('❌ [BASE64] Erreur: $e');
        return Response.internalServerError(body: jsonEncode({
          'success': false,
          'message': e.toString()
        }));
      }
    });

    // ✅ Upload photo de colis
    router.post('/parcel-photo', (Request request) async {
      try {
        final body = await request.readAsString();
        final data = jsonDecode(body);
        
        final base64File = data['file'];
        final parcelId = data['parcelId'];
        final filename = data['filename'] ?? 'photo.jpg';
        
        if (base64File == null || base64File.isEmpty) {
          return Response.badRequest(body: jsonEncode({
            'success': false,
            'message': 'Fichier manquant'
          }));
        }
        
        // Nettoyer le base64
        String cleanBase64 = base64File;
        if (base64File.contains(',')) {
          cleanBase64 = base64File.split(',').last;
        }
        
        // Décoder le base64
        final bytes = base64Decode(cleanBase64);
        
        // Générer un nom unique
        final extension = filename.split('.').last;
        final uniqueName = '${_uuid.v4()}.$extension';
        
        // Créer le dossier si nécessaire
        final uploadDir = Directory('uploads/parcels');
        if (!await uploadDir.exists()) {
          await uploadDir.create(recursive: true);
        }
        
        // Sauvegarder le fichier
        final filePath = '${uploadDir.path}/$uniqueName';
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        
        // URL publique
        final publicUrl = '/uploads/parcels/$uniqueName';
        
        print('✅ [PARCEL_PHOTO] Photo uploadée pour colis $parcelId: $publicUrl');
        
        return Response.ok(jsonEncode({
          'success': true,
          'url': publicUrl,
          'parcelId': parcelId
        }));
      } catch (e) {
        print('❌ [PARCEL_PHOTO] Erreur: $e');
        return Response.internalServerError(body: jsonEncode({
          'success': false,
          'message': e.toString(),
        }));
      }
    });
    
    // ✅ Upload vidéo de colis
    router.post('/parcel-video', (Request request) async {
      try {
        final body = await request.readAsString();
        final data = jsonDecode(body);
        
        final base64File = data['file'];
        final parcelId = data['parcelId'];
        final filename = data['filename'] ?? 'video.mp4';
        
        if (base64File == null || base64File.isEmpty) {
          return Response.badRequest(body: jsonEncode({
            'success': false,
            'message': 'Fichier manquant'
          }));
        }
        
        // Nettoyer le base64
        String cleanBase64 = base64File;
        if (base64File.contains(',')) {
          cleanBase64 = base64File.split(',').last;
        }
        
        // Décoder le base64
        final bytes = base64Decode(cleanBase64);
        
        // Générer un nom unique
        final extension = filename.split('.').last;
        final uniqueName = '${_uuid.v4()}.$extension';
        
        // Créer le dossier si nécessaire
        final uploadDir = Directory('uploads/parcels');
        if (!await uploadDir.exists()) {
          await uploadDir.create(recursive: true);
        }
        
        // Sauvegarder le fichier
        final filePath = '${uploadDir.path}/$uniqueName';
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        
        // URL publique
        final publicUrl = '/uploads/parcels/$uniqueName';
        
        print('✅ [PARCEL_VIDEO] Vidéo uploadée pour colis $parcelId: $publicUrl');
        
        return Response.ok(jsonEncode({
          'success': true,
          'url': publicUrl,
          'parcelId': parcelId
        }));
      } catch (e) {
        print('❌ [PARCEL_VIDEO] Erreur: $e');
        return Response.internalServerError(body: jsonEncode({
          'success': false,
          'message': e.toString(),
        }));
      }
    });
    
    // ✅ Upload photo de profil
    router.post('/profile-photo', (Request request) async {
      try {
        final body = await request.readAsString();
        final data = jsonDecode(body);
        
        final base64File = data['file'];
        final userId = data['userId'];
        final filename = data['filename'] ?? 'profile.jpg';
        
        if (base64File == null || base64File.isEmpty) {
          return Response.badRequest(body: jsonEncode({
            'success': false,
            'message': 'Fichier manquant'
          }));
        }
        
        // Nettoyer le base64
        String cleanBase64 = base64File;
        if (base64File.contains(',')) {
          cleanBase64 = base64File.split(',').last;
        }
        
        // Décoder le base64
        final bytes = base64Decode(cleanBase64);
        
        // Générer un nom unique
        final extension = filename.split('.').last;
        final uniqueName = '${_uuid.v4()}.$extension';
        
        // Créer le dossier si nécessaire
        final uploadDir = Directory('uploads/profiles');
        if (!await uploadDir.exists()) {
          await uploadDir.create(recursive: true);
        }
        
        // Sauvegarder le fichier
        final filePath = '${uploadDir.path}/$uniqueName';
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        
        // URL publique
        final publicUrl = '/uploads/profiles/$uniqueName';
        
        print('✅ [PROFILE_PHOTO] Photo profil uploadée pour user $userId: $publicUrl');
        
        return Response.ok(jsonEncode({
          'success': true,
          'url': publicUrl,
          'userId': userId
        }));
      } catch (e) {
        print('❌ [PROFILE_PHOTO] Erreur: $e');
        return Response.internalServerError(body: jsonEncode({
          'success': false,
          'message': e.toString(),
        }));
      }
    });
    
    // ✅ Upload multiple (pour plusieurs fichiers)
    router.post('/multiple', (Request request) async {
      try {
        final body = await request.readAsString();
        final data = jsonDecode(body);
        
        final files = data['files'] as List<dynamic>?;
        final type = data['type'] ?? 'general';
        
        if (files == null || files.isEmpty) {
          return Response.badRequest(body: jsonEncode({
            'success': false,
            'message': 'Aucun fichier trouvé'
          }));
        }
        
        final List<String> urls = [];
        
        for (var fileData in files) {
          final base64File = fileData['file'];
          final filename = fileData['filename'] ?? 'file.jpg';
          
          if (base64File == null || base64File.isEmpty) continue;
          
          // Nettoyer le base64
          String cleanBase64 = base64File;
          if (base64File.contains(',')) {
            cleanBase64 = base64File.split(',').last;
          }
          
          // Décoder le base64
          final bytes = base64Decode(cleanBase64);
          
          // Créer le dossier si nécessaire
          final uploadDir = Directory('uploads/$type');
          if (!await uploadDir.exists()) {
            await uploadDir.create(recursive: true);
          }
          
          // Sauvegarder le fichier
          final extension = filename.split('.').last;
          final uniqueName = '${_uuid.v4()}.$extension';
          final filePath = '${uploadDir.path}/$uniqueName';
          
          final file = File(filePath);
          await file.writeAsBytes(bytes);
          
          final publicUrl = '/uploads/$type/$uniqueName';
          urls.add(publicUrl);
        }
        
        print('✅ [MULTIPLE] ${urls.length} fichiers uploadés');
        
        return Response.ok(jsonEncode({
          'success': true,
          'urls': urls
        }));
      } catch (e) {
        print('❌ [MULTIPLE] Erreur: $e');
        return Response.internalServerError(body: jsonEncode({
          'success': false,
          'message': e.toString()
        }));
      }
    });
    
    return router;
  }
}