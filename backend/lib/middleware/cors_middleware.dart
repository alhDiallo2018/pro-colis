// backend/lib/middleware/cors_middleware.dart
import 'package:shelf/shelf.dart';

/// Middleware CORS pour gérer les requêtes cross-origin
Middleware corsMiddleware() {
  return (Handler handler) {
    return (Request request) async {
      // Gérer les requêtes OPTIONS (preflight)
      if (request.method == 'OPTIONS') {
        return Response.ok('OK', headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, PATCH, OPTIONS',
          'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization, X-Requested-With',
          'Access-Control-Allow-Credentials': 'true',
          'Access-Control-Max-Age': '86400',
        });
      }

      // Traiter la requête normale
      final response = await handler(request);
      
      // Ajouter les headers CORS à la réponse
      return response.change(headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, PATCH, OPTIONS',
        'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization, X-Requested-With',
        'Access-Control-Allow-Credentials': 'true',
        ...response.headers,
      });
    };
  };
}