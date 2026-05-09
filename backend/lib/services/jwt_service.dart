import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class JwtService {
  static const String _secretKey = 'PROCOLIS_SECRET_KEY_2024_CHANGE_ME';
  
  /// Génère un token JWT
  static String generateToken(String userId, Duration expiresIn, {String role = 'client'}) {
    final header = _base64UrlEncode(utf8.encode(jsonEncode({
      'alg': 'HS256',
      'typ': 'JWT',
    })));
    
    final expiresAt = DateTime.now().add(expiresIn).millisecondsSinceEpoch ~/ 1000;
    final issuedAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    final payload = _base64UrlEncode(utf8.encode(jsonEncode({
      'sub': userId,
      'role': role,
      'iat': issuedAt,
      'exp': expiresAt,
      'jti': _generateJti(),
    })));
    
    final signature = _generateSignature('$header.$payload');
    
    return '$header.$payload.$signature';
  }
  
  /// Génère un refresh token
  static String generateRefreshToken(String userId) {
    return generateToken(userId, const Duration(days: 30));
  }
  
  /// Vérifie et décode un token JWT
  static Map<String, dynamic>? verifyToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      final signature = _generateSignature('${parts[0]}.${parts[1]}');
      if (signature != parts[2]) return null;
      
      final payload = jsonDecode(utf8.decode(_base64UrlDecode(parts[1])));
      
      // Vérifier l'expiration
      final exp = payload['exp'] as int;
      if (DateTime.now().millisecondsSinceEpoch ~/ 1000 > exp) {
        return null;
      }
      
      return payload;
    } catch (e) {
      return null;
    }
  }
  
  /// Rafraîchit le token
  static String? refreshToken(String refreshToken) {
    final payload = verifyToken(refreshToken);
    if (payload == null) return null;
    
    return generateToken(
      payload['sub'], 
      const Duration(hours: 24),
      role: payload['role'] ?? 'client',
    );
  }
  
  static String _generateSignature(String data) {
    final key = utf8.encode(_secretKey);
    final bytes = utf8.encode(data);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    return _base64UrlEncode(digest.bytes);
  }
  
  static String _base64UrlEncode(List<int> bytes) {
    return base64Url.encode(bytes).replaceAll('=', '');
  }
  
  static List<int> _base64UrlDecode(String data) {
    String padded = data;
    while (padded.length % 4 != 0) {
      padded += '=';
    }
    return base64Url.decode(padded);
  }
  
  static String _generateJti() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return _base64UrlEncode(bytes);
  }
}
