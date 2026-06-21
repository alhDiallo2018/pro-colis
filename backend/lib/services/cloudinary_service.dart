// backend/lib/services/cloudinary_service.dart
// ignore_for_file: unused_local_variable

import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

class CloudinaryService {
  final String cloudName;
  final String? apiKey;
  final String? apiSecret;
  final String? uploadPreset;
  final _log = Logger('CloudinaryService');

  // Constructeur pour upload signé (avec apiKey/apiSecret)
  CloudinaryService.signed({
    required this.cloudName,
    required this.apiKey,
    required this.apiSecret,
  }) : uploadPreset = null;

  // Constructeur pour upload non signé (avec uploadPreset)
  CloudinaryService.unsigned({
    required this.cloudName,
    required this.uploadPreset,
  }) : apiKey = null, apiSecret = null;

  /// Upload un fichier vers Cloudinary
  Future<String?> uploadFile({
    required List<int> fileBytes,
    required String fileName,
    String folder = 'procolis',
  }) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/upload');
      
      final request = http.MultipartRequest('POST', url);
      
      // Ajouter les paramètres selon le mode
      if (apiKey != null && apiSecret != null) {
        // Mode signé
        final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final signature = _generateSignature(
          timestamp: timestamp,
          folder: folder,
        );
        request.fields['api_key'] = apiKey!;
        request.fields['timestamp'] = timestamp.toString();
        request.fields['signature'] = signature;
        _log.fine('🔑 Upload signé avec signature: $signature');
      } else if (uploadPreset != null) {
        // Mode non signé
        request.fields['upload_preset'] = uploadPreset!;
        _log.fine('🔑 Upload non signé avec upload_preset: $uploadPreset');
      } else {
        _log.severe('❌ Aucune méthode d\'authentification configurée');
        return null;
      }
      
      request.fields['folder'] = folder;
      request.fields['use_filename'] = 'true';
      request.fields['unique_filename'] = 'true';
      request.fields['overwrite'] = 'true';
      
      // Ajouter des paramètres optionnels pour l'optimisation
      request.fields['quality'] = 'auto';
      request.fields['fetch_format'] = 'auto';
      
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      ));
      
      _log.info('📤 Upload en cours vers Cloudinary: $fileName');
      
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final secureUrl = data['secure_url'] ?? data['url'];
        final publicId = data['public_id'];
        final bytes = data['bytes'];
        final format = data['format'];
        
        _log.info('✅ Fichier uploadé sur Cloudinary: $secureUrl');
        _log.fine('   Public ID: $publicId');
        _log.fine('   Taille: ${(bytes / 1024).toStringAsFixed(1)} KB');
        _log.fine('   Format: $format');
        
        return secureUrl;
      } else {
        final error = data['error']?['message'] ?? 'Erreur inconnue';
        _log.severe('❌ Erreur Cloudinary: $error');
        _log.severe('   Code: ${response.statusCode}');
        _log.severe('   Réponse: $responseBody');
        return null;
      }
    } catch (e) {
      _log.severe('❌ Exception Cloudinary: $e');
      return null;
    }
  }

  /// Upload multiple fichiers vers Cloudinary
  Future<List<String?>> uploadMultipleFiles({
    required List<List<int>> filesBytes,
    required List<String> filesNames,
    String folder = 'procolis',
  }) async {
    final results = <String?>[];
    
    for (var i = 0; i < filesBytes.length; i++) {
      final url = await uploadFile(
        fileBytes: filesBytes[i],
        fileName: filesNames[i],
        folder: folder,
      );
      results.add(url);
      
      // Petit délai pour éviter les limites de rate
      if (i < filesBytes.length - 1) {
        await Future.delayed(Duration(milliseconds: 500));
      }
    }
    
    return results;
  }

  /// Supprimer un fichier de Cloudinary
  Future<bool> deleteFile(String publicId) async {
    if (apiKey == null || apiSecret == null) {
      _log.warning('⚠️ Impossible de supprimer sans apiKey/apiSecret');
      return false;
    }

    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/resources/image/upload/$publicId');
      
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final signature = _generateSignature(
        timestamp: timestamp,
        folder: '',
      );
      
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'api_key': apiKey,
          'timestamp': timestamp.toString(),
          'signature': signature,
        }),
      );
      
      if (response.statusCode == 200) {
        _log.info('✅ Fichier supprimé de Cloudinary: $publicId');
        return true;
      } else {
        _log.severe('❌ Erreur suppression Cloudinary: ${response.body}');
        return false;
      }
    } catch (e) {
      _log.severe('❌ Exception suppression: $e');
      return false;
    }
  }

  /// Génère la signature SHA-256 pour l'upload
  String _generateSignature({
    required int timestamp,
    required String folder,
  }) {
    if (apiSecret == null) {
      _log.severe('❌ Impossible de générer une signature sans apiSecret');
      return '';
    }
    
    // Construire la chaîne à signer selon la documentation Cloudinary
    // format: folder=folder&timestamp=timestamp + apiSecret
    final toSign = 'folder=$folder&timestamp=$timestamp${apiSecret!}';
    
    // Générer la signature SHA-256
    final digest = sha256.convert(utf8.encode(toSign));
    final signature = digest.toString();
    
    _log.fine('🔐 Signature générée: $signature');
    return signature;
  }

  /// Vérifier la configuration Cloudinary
  Future<bool> checkConfiguration() async {
    try {
      if (apiKey != null && apiSecret != null) {
        _log.info('✅ Cloudinary configuré en mode signé');
        _log.info('   Cloud Name: $cloudName');
        _log.info('   API Key: ${apiKey!.substring(0, 4)}...');
        return true;
      } else if (uploadPreset != null) {
        _log.info('✅ Cloudinary configuré en mode non signé');
        _log.info('   Cloud Name: $cloudName');
        _log.info('   Upload Preset: $uploadPreset');
        return true;
      } else {
        _log.warning('⚠️ Cloudinary non configuré');
        return false;
      }
    } catch (e) {
      _log.severe('❌ Erreur vérification Cloudinary: $e');
      return false;
    }
  }

  /// Obtenir les informations d'un fichier
  Future<Map<String, dynamic>?> getFileInfo(String publicId) async {
    if (apiKey == null || apiSecret == null) {
      return null;
    }

    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/resources/image/upload/$publicId');
      
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final signature = _generateSignature(
        timestamp: timestamp,
        folder: '',
      );
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'publicId': data['public_id'],
          'format': data['format'],
          'version': data['version'],
          'resourceType': data['resource_type'],
          'type': data['type'],
          'createdAt': data['created_at'],
          'bytes': data['bytes'],
          'width': data['width'],
          'height': data['height'],
          'url': data['url'],
          'secureUrl': data['secure_url'],
        };
      } else {
        return null;
      }
    } catch (e) {
      _log.severe('❌ Erreur getFileInfo: $e');
      return null;
    }
  }

  /// Transformer une URL Cloudinary avec des options
  String transformUrl(String url, {
    int? width,
    int? height,
    String? crop = 'fit',
    String? quality = 'auto',
    String? format = 'auto',
    bool? progressive,
    List<String>? effects,
  }) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      final baseUrl = '${uri.scheme}://${uri.host}';
      
      // Construire les options de transformation
      final transforms = <String>[];
      
      if (width != null && height != null) {
        transforms.add('c_$crop,w_$width,h_$height');
      } else if (width != null) {
        transforms.add('c_$crop,w_$width');
      } else if (height != null) {
        transforms.add('c_$crop,h_$height');
      }
      
      if (quality != null && quality != 'auto') {
        transforms.add('q_$quality');
      }
      
      if (format != null && format != 'auto') {
        transforms.add('f_$format');
      }
      
      if (progressive == true) {
        transforms.add('fl_progressive');
      }
      
      if (effects != null && effects.isNotEmpty) {
        transforms.addAll(effects);
      }
      
      if (transforms.isEmpty) {
        return url;
      }
      
      // Construire l'URL transformée
      final transformString = transforms.join(',');
      final pathParts = path.split('/');
      final fileName = pathParts.removeLast();
      
      // Vérifier si le chemin contient déjà 'upload'
      final uploadIndex = pathParts.indexOf('upload');
      if (uploadIndex != -1) {
        // Insérer les transformations après 'upload'
        pathParts.insert(uploadIndex + 1, transformString);
      } else {
        // Ajouter 'upload' et les transformations
        pathParts.add('upload');
        pathParts.add(transformString);
      }
      
      final newPath = '${pathParts.join('/')}/$fileName';
      return '$baseUrl$newPath';
    } catch (e) {
      _log.warning('⚠️ Erreur transformation URL: $e');
      return url;
    }
  }
}