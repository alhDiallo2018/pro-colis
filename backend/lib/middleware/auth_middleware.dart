import 'package:shelf/shelf.dart';
import '../services/jwt_service.dart';

class AuthMiddleware {
  /// Vérifie que l'utilisateur est authentifié
  static Middleware verify = (Handler innerHandler) {
    return (Request request) async {
      final authHeader = request.headers['Authorization'];
      
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response(401, body: '{"error": "Token manquant"}');
      }
      
      final token = authHeader.substring(7);
      final payload = JwtService.verifyToken(token);
      
      if (payload == null) {
        return Response(401, body: '{"error": "Token invalide ou expiré"}');
      }
      
      final newRequest = request.change(
        context: {
          ...request.context,
          'userId': payload['sub'],
          'userRole': payload['role'] ?? 'client',
        },
      );
      
      return await innerHandler(newRequest);
    };
  };
  
  /// Vérifie que l'utilisateur est Super Admin
  static Middleware verifySuperAdmin = (Handler innerHandler) {
    return (Request request) async {
      final authHeader = request.headers['Authorization'];
      
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response(401, body: '{"error": "Token manquant"}');
      }
      
      final token = authHeader.substring(7);
      final payload = JwtService.verifyToken(token);
      
      if (payload == null) {
        return Response(401, body: '{"error": "Token invalide"}');
      }
      
      if (payload['role'] != 'super_admin') {
        return Response(403, body: '{"error": "Accès non autorisé"}');
      }
      
      final newRequest = request.change(
        context: {
          ...request.context,
          'userId': payload['sub'],
          'userRole': payload['role'],
        },
      );
      
      return await innerHandler(newRequest);
    };
  };
  
  /// Vérifie que l'utilisateur est Admin
  static Middleware verifyAdmin = (Handler innerHandler) {
    return (Request request) async {
      final authHeader = request.headers['Authorization'];
      
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response(401, body: '{"error": "Token manquant"}');
      }
      
      final token = authHeader.substring(7);
      final payload = JwtService.verifyToken(token);
      
      if (payload == null) {
        return Response(401, body: '{"error": "Token invalide"}');
      }
      
      final role = payload['role'];
      if (role != 'admin' && role != 'super_admin') {
        return Response(403, body: '{"error": "Accès non autorisé"}');
      }
      
      final newRequest = request.change(
        context: {
          ...request.context,
          'userId': payload['sub'],
          'userRole': role,
        },
      );
      
      return await innerHandler(newRequest);
    };
  };
  
  /// Vérifie que l'utilisateur est Driver
  static Middleware verifyDriver = (Handler innerHandler) {
    return (Request request) async {
      final authHeader = request.headers['Authorization'];
      
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response(401, body: '{"error": "Token manquant"}');
      }
      
      final token = authHeader.substring(7);
      final payload = JwtService.verifyToken(token);
      
      if (payload == null) {
        return Response(401, body: '{"error": "Token invalide"}');
      }
      
      if (payload['role'] != 'driver') {
        return Response(403, body: '{"error": "Accès non autorisé"}');
      }
      
      final newRequest = request.change(
        context: {
          ...request.context,
          'userId': payload['sub'],
          'userRole': payload['role'],
        },
      );
      
      return await innerHandler(newRequest);
    };
  };
}
