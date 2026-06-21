// lib/controllers/score_controller.dart
// ignore_for_file: unused_local_variable

import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../config/constants.dart';
import '../services/score_service.dart';

class ScoreController {
  Router get router {
    final router = Router();

    router.get('/', getUserScore);
    router.get('/balance', getBalance);
    router.get('/history', getTransactionHistory);
    router.post('/purchase', purchasePoints);
    router.post('/debit', debitPoints);
    router.post('/credit', creditPoints);
    router.get('/stats', getStats);
    router.post('/refund', refundTransaction);

    return router;
  }

  /// GET /api/score
  Future<Response> getUserScore(Request request) async {
    try {
      // ✅ CORRECTION : Récupérer l'userId du contexte avec vérification
      final userId = request.context['userId'] as String?;
      if (userId == null) {
        return Response.unauthorized(
          jsonEncode({
            'success': false,
            'message': 'Utilisateur non authentifié',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final queryParams = request.url.queryParameters;
      final page = int.tryParse(queryParams['page'] ?? '1') ?? 1;
      final limit = int.tryParse(queryParams['limit'] ?? '20') ?? 20;

      final result = await ScoreService.getUserScore(userId, page: page, limit: limit);
      final score = result['score'];
      
      if (score == null) {
        // Créer un nouveau score
        await ScoreService.getOrCreateScore(userId);
        final newResult = await ScoreService.getUserScore(userId, page: page, limit: limit);
        return Response.ok(
          jsonEncode({
            'success': true,
            'data': newResult,
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode({
          'success': true,
          'data': result,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Erreur getUserScore: $e');
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'message': e.toString(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// GET /api/score/balance
  Future<Response> getBalance(Request request) async {
    try {
      // ✅ CORRECTION : Récupérer l'userId du contexte avec vérification
      final userId = request.context['userId'] as String?;
      if (userId == null) {
        return Response.unauthorized(
          jsonEncode({
            'success': false,
            'message': 'Utilisateur non authentifié',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final balance = await ScoreService.getBalance(userId);

      return Response.ok(
        jsonEncode({
          'success': true,
          'data': {'balance': balance},
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Erreur getBalance: $e');
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'message': e.toString(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// GET /api/score/history
  Future<Response> getTransactionHistory(Request request) async {
    try {
      // ✅ CORRECTION : Récupérer l'userId du contexte avec vérification
      final userId = request.context['userId'] as String?;
      if (userId == null) {
        return Response.unauthorized(
          jsonEncode({
            'success': false,
            'message': 'Utilisateur non authentifié',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final queryParams = request.url.queryParameters;
      final page = int.tryParse(queryParams['page'] ?? '1') ?? 1;
      final limit = int.tryParse(queryParams['limit'] ?? '20') ?? 20;

      final result = await ScoreService.getUserScore(userId, page: page, limit: limit);

      return Response.ok(
        jsonEncode({
          'success': true,
          'data': result,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Erreur getTransactionHistory: $e');
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'message': e.toString(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// POST /api/score/purchase
  Future<Response> purchasePoints(Request request) async {
    try {
      // ✅ CORRECTION : Récupérer l'userId du contexte avec vérification
      final userId = request.context['userId'] as String?;
      if (userId == null) {
        return Response.unauthorized(
          jsonEncode({
            'success': false,
            'message': 'Utilisateur non authentifié',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final body = jsonDecode(await request.readAsString());
      
      final amount = body['amount'] as int?;
      final paymentMethod = body['paymentMethod'] as String?;
      final paymentReference = body['paymentReference'] as String?;

      // Valider
      if (amount == null || amount < AppConstants.minPurchasePoints || amount > AppConstants.maxPurchasePoints) {
        return Response.badRequest(
          body: jsonEncode({
            'success': false,
            'message': 'Le nombre de points doit être entre ${AppConstants.minPurchasePoints} et ${AppConstants.maxPurchasePoints}',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (paymentMethod == null || paymentMethod.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({
            'success': false,
            'message': 'La méthode de paiement est requise',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final totalPrice = amount * AppConstants.pricePerPoint;

      // Simuler le paiement (à intégrer avec un vrai service)
      final result = await ScoreService.processPurchase(
        userId,
        amount,
        paymentMethod,
        paymentReference ?? 'SIM-${DateTime.now().millisecondsSinceEpoch}',
      );

      return Response.ok(
        jsonEncode({
          'success': true,
          'data': result,
          'message': '$amount points ajoutés avec succès pour $totalPrice FCFA',
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Erreur purchasePoints: $e');
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'message': e.toString(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// POST /api/score/debit (admin uniquement)
  Future<Response> debitPoints(Request request) async {
    try {
      // ✅ CORRECTION : Récupérer l'userId du contexte avec vérification
      final userId = request.context['userId'] as String?;
      if (userId == null) {
        return Response.unauthorized(
          jsonEncode({
            'success': false,
            'message': 'Utilisateur non authentifié',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final userRole = request.context['userRole'] as String?;
      
      // Vérifier les droits admin
      if (!['admin', 'super_admin'].contains(userRole)) {
        return Response.forbidden(
          jsonEncode({
            'success': false,
            'message': 'Non autorisé',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final body = jsonDecode(await request.readAsString());
      
      final targetUserId = body['userId'] as String?;
      final amount = body['amount'] as int?;
      final type = body['type'] as String?;
      final parcelId = body['parcelId'] as String?;
      final description = body['description'] as String?;

      if (targetUserId == null || amount == null || type == null || description == null) {
        return Response.badRequest(
          body: jsonEncode({
            'success': false,
            'message': 'userId, amount, type et description sont requis',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final result = await ScoreService.debitPoints(
        userId: targetUserId,
        amount: amount,
        type: type,
        parcelId: parcelId,
        description: description,
      );

      return Response.ok(
        jsonEncode({
          'success': true,
          'data': result,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Erreur debitPoints: $e');
      return Response.badRequest(
        body: jsonEncode({
          'success': false,
          'message': e.toString(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// POST /api/score/credit (admin uniquement)
  Future<Response> creditPoints(Request request) async {
    try {
      // ✅ CORRECTION : Récupérer l'userId du contexte avec vérification
      final userId = request.context['userId'] as String?;
      if (userId == null) {
        return Response.unauthorized(
          jsonEncode({
            'success': false,
            'message': 'Utilisateur non authentifié',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final userRole = request.context['userRole'] as String?;
      
      if (!['admin', 'super_admin'].contains(userRole)) {
        return Response.forbidden(
          jsonEncode({
            'success': false,
            'message': 'Non autorisé',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final body = jsonDecode(await request.readAsString());
      
      final targetUserId = body['userId'] as String?;
      final amount = body['amount'] as int?;
      final type = body['type'] as String?;
      final parcelId = body['parcelId'] as String?;
      final description = body['description'] as String?;

      if (targetUserId == null || amount == null || type == null || description == null) {
        return Response.badRequest(
          body: jsonEncode({
            'success': false,
            'message': 'userId, amount, type et description sont requis',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final result = await ScoreService.creditPoints(
        userId: targetUserId,
        amount: amount,
        type: type,
        parcelId: parcelId,
        description: description,
      );

      return Response.ok(
        jsonEncode({
          'success': true,
          'data': result,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Erreur creditPoints: $e');
      return Response.badRequest(
        body: jsonEncode({
          'success': false,
          'message': e.toString(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// GET /api/score/stats (admin uniquement)
  Future<Response> getStats(Request request) async {
    try {
      // ✅ CORRECTION : Récupérer l'userId du contexte avec vérification
      final userId = request.context['userId'] as String?;
      if (userId == null) {
        return Response.unauthorized(
          jsonEncode({
            'success': false,
            'message': 'Utilisateur non authentifié',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final userRole = request.context['userRole'] as String?;
      
      if (!['admin', 'super_admin'].contains(userRole)) {
        return Response.forbidden(
          jsonEncode({
            'success': false,
            'message': 'Non autorisé',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final stats = await ScoreService.getStats();

      return Response.ok(
        jsonEncode({
          'success': true,
          'data': stats,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Erreur getStats: $e');
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'message': e.toString(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// POST /api/score/refund (admin uniquement)
  Future<Response> refundTransaction(Request request) async {
    try {
      // ✅ CORRECTION : Récupérer l'userId du contexte avec vérification
      final userId = request.context['userId'] as String?;
      if (userId == null) {
        return Response.unauthorized(
          jsonEncode({
            'success': false,
            'message': 'Utilisateur non authentifié',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final userRole = request.context['userRole'] as String?;
      
      if (!['admin', 'super_admin'].contains(userRole)) {
        return Response.forbidden(
          jsonEncode({
            'success': false,
            'message': 'Non autorisé',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final body = jsonDecode(await request.readAsString());
      
      final targetUserId = body['userId'] as String?;
      final transactionId = body['transactionId'] as String?;
      final reason = body['reason'] as String? ?? 'Remboursement administratif';

      if (targetUserId == null || transactionId == null) {
        return Response.badRequest(
          body: jsonEncode({
            'success': false,
            'message': 'userId et transactionId sont requis',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final result = await ScoreService.refundTransaction(
        userId: targetUserId,
        transactionId: transactionId,
        reason: reason,
      );

      return Response.ok(
        jsonEncode({
          'success': true,
          'data': result,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('❌ Erreur refundTransaction: $e');
      return Response.badRequest(
        body: jsonEncode({
          'success': false,
          'message': e.toString(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}