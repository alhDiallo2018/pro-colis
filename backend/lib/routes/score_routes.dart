// lib/routes/score_routes.dart
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../controllers/score_controller.dart';
import '../utils/jwt_helper.dart';

class ScoreRoutes {
  final ScoreController _controller = ScoreController();

  Router get router {
    final router = Router();

    // Route public pour la santé du service
    router.get('/health', (Request request) {
      return Response.ok(
        '{"status": "ok", "service": "score", "timestamp": "${DateTime.now().toIso8601String()}"}',
        headers: {'Content-Type': 'application/json'},
      );
    });

    // ==================== MIDDLEWARE ====================
    // Même approche que client_routes.dart et driver_routes.dart
    Future<Response?> _authMiddleware(Request request) async {
      final userId = JwtHelper.extractUserId(request);
      print('🔐 Auth middleware - userId extrait: $userId');

      if (userId == null) {
        return Response.forbidden(
            jsonEncode({'success': false, 'message': 'Non authentifié'}));
      }

      print('✅ Auth OK pour utilisateur: $userId');
      return null;
    }

    // Middleware pour vérifier les droits admin
    Future<Response?> _adminMiddleware(Request request) async {
      final userId = JwtHelper.extractUserId(request);
      print('🔐 Admin auth - userId extrait: $userId');

      if (userId == null) {
        return Response.forbidden(
            jsonEncode({'success': false, 'message': 'Non authentifié'}));
      }

      final isAdmin = await JwtHelper.isAdmin(userId);
      if (!isAdmin) {
        return Response.forbidden(jsonEncode(
            {'success': false, 'message': 'Accès réservé aux administrateurs'}));
      }

      print('✅ Admin auth OK pour: $userId');
      return null;
    }

    // ==================== ROUTES PROTÉGÉES ====================
    
    // GET /api/score - Récupérer le score de l'utilisateur
    router.get('/', (Request request) async {
      final authCheck = await _authMiddleware(request);
      if (authCheck != null) return authCheck;

      final userId = JwtHelper.extractUserId(request)!;
      // Ajouter l'userId au contexte pour le controller
      final updatedRequest = request.change(
        context: {...request.context, 'userId': userId},
      );
      return await _controller.getUserScore(updatedRequest);
    });

    // GET /api/score/balance - Récupérer le solde
    router.get('/balance', (Request request) async {
      final authCheck = await _authMiddleware(request);
      if (authCheck != null) return authCheck;

      final userId = JwtHelper.extractUserId(request)!;
      final updatedRequest = request.change(
        context: {...request.context, 'userId': userId},
      );
      return await _controller.getBalance(updatedRequest);
    });

    // GET /api/score/history - Historique des transactions
    router.get('/history', (Request request) async {
      final authCheck = await _authMiddleware(request);
      if (authCheck != null) return authCheck;

      final userId = JwtHelper.extractUserId(request)!;
      final updatedRequest = request.change(
        context: {...request.context, 'userId': userId},
      );
      return await _controller.getTransactionHistory(updatedRequest);
    });

    // POST /api/score/purchase - Acheter des points
    router.post('/purchase', (Request request) async {
      final authCheck = await _authMiddleware(request);
      if (authCheck != null) return authCheck;

      final userId = JwtHelper.extractUserId(request)!;
      final updatedRequest = request.change(
        context: {...request.context, 'userId': userId},
      );
      return await _controller.purchasePoints(updatedRequest);
    });

    // ==================== ROUTES ADMIN ====================
    
    // POST /api/score/debit - Débiter des points (Admin/SuperAdmin)
    router.post('/debit', (Request request) async {
      final authCheck = await _authMiddleware(request);
      if (authCheck != null) return authCheck;

      final userId = JwtHelper.extractUserId(request)!;
      final updatedRequest = request.change(
        context: {...request.context, 'userId': userId, 'userRole': 'admin'},
      );
      return await _controller.debitPoints(updatedRequest);
    });

    // POST /api/score/credit - Créditer des points (Admin/SuperAdmin)
    router.post('/credit', (Request request) async {
      final authCheck = await _adminMiddleware(request);
      if (authCheck != null) return authCheck;

      final userId = JwtHelper.extractUserId(request)!;
      final updatedRequest = request.change(
        context: {...request.context, 'userId': userId, 'userRole': 'admin'},
      );
      return await _controller.creditPoints(updatedRequest);
    });

    // GET /api/score/stats - Statistiques (Admin/SuperAdmin)
    router.get('/stats', (Request request) async {
      final authCheck = await _adminMiddleware(request);
      if (authCheck != null) return authCheck;

      final userId = JwtHelper.extractUserId(request)!;
      final updatedRequest = request.change(
        context: {...request.context, 'userId': userId, 'userRole': 'admin'},
      );
      return await _controller.getStats(updatedRequest);
    });

    // POST /api/score/refund - Remboursement (Admin/SuperAdmin)
    router.post('/refund', (Request request) async {
      final authCheck = await _adminMiddleware(request);
      if (authCheck != null) return authCheck;

      final userId = JwtHelper.extractUserId(request)!;
      final updatedRequest = request.change(
        context: {...request.context, 'userId': userId, 'userRole': 'admin'},
      );
      return await _controller.refundTransaction(updatedRequest);
    });

    return router;
  }
}