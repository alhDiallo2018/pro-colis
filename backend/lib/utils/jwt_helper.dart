// lib/utils/jwt_helper.dart
import 'package:shelf/shelf.dart';

import '../utils/db_helper.dart';

class JwtHelper {
  // Génère un token simple (format: token_{userId}_{timestamp})
  static String generateToken(String userId) {
    return 'token_${userId}_${DateTime.now().millisecondsSinceEpoch}';
  }
  
  // Extrait l'userId du token
  static String? extractUserIdFromToken(String token) {
    if (token.isEmpty) return null;
    
    final parts = token.split('_');
    if (parts.length < 2) return null;
    
    // Format: token_{userId}_{timestamp}
    return parts[1];
  }
  
  // Extrait l'userId de la requête (header Authorization)
  static String? extractUserId(Request request) {
    final authHeader = request.headers['Authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return null;
    }
    final token = authHeader.substring(7);
    return extractUserIdFromToken(token);
  }
  
  // Vérifie si l'utilisateur est un super admin
  static Future<bool> isSuperAdmin(String userId) async {
    if (userId.isEmpty) return false;
    
    final db = await DbHelper.getInstance();
    try {
      final result = await db.connection.execute(
        'SELECT role FROM users WHERE id = \$1',
        parameters: [userId],
      );
      return result.isNotEmpty && result.first[0] == 'super_admin';
    } catch (e) {
      return false;
    }
  }
  
  // Vérifie si l'utilisateur est un admin garage
  static Future<bool> isAdmin(String userId) async {
    if (userId.isEmpty) return false;
    
    final db = await DbHelper.getInstance();
    try {
      final result = await db.connection.execute(
        'SELECT role FROM users WHERE id = \$1',
        parameters: [userId],
      );
      return result.isNotEmpty && (result.first[0] == 'admin' || result.first[0] == 'super_admin');
    } catch (e) {
      return false;
    }
  }
  
  // Vérifie si l'utilisateur est un chauffeur
  static Future<bool> isDriver(String userId) async {
    if (userId.isEmpty) return false;
    
    final db = await DbHelper.getInstance();
    try {
      final result = await db.connection.execute(
        'SELECT role FROM users WHERE id = \$1',
        parameters: [userId],
      );
      return result.isNotEmpty && result.first[0] == 'driver';
    } catch (e) {
      return false;
    }
  }
  
  // Vérifie si l'utilisateur est un client
  static Future<bool> isClient(String userId) async {
    if (userId.isEmpty) return false;
    
    final db = await DbHelper.getInstance();
    try {
      final result = await db.connection.execute(
        'SELECT role FROM users WHERE id = \$1',
        parameters: [userId],
      );
      return result.isNotEmpty && result.first[0] == 'client';
    } catch (e) {
      return false;
    }
  }
  
  // Récupère le rôle de l'utilisateur
  static Future<String?> getUserRole(String userId) async {
    if (userId.isEmpty) return null;
    
    final db = await DbHelper.getInstance();
    try {
      final result = await db.connection.execute(
        'SELECT role FROM users WHERE id = \$1',
        parameters: [userId],
      );
      return result.isNotEmpty ? result.first[0] as String? : null;
    } catch (e) {
      return null;
    }
  }
  
  // Vérifie si le token est valide (non expiré)
  static Future<bool> isTokenValid(String token) async {
    // Pour l'instant, vérification simple
    // En production, vérifier dans la base de données
    if (token.isEmpty || token.isEmpty) return false;
    
    final userId = extractUserIdFromToken(token);
    if (userId == null) return false;
    
    // Vérifier si l'utilisateur existe et est actif
    final db = await DbHelper.getInstance();
    try {
      final result = await db.connection.execute(
        'SELECT status FROM users WHERE id = \$1',
        parameters: [userId],
      );
      return result.isNotEmpty && result.first[0] == 'active';
    } catch (e) {
      return false;
    }
  }
}