// backend/lib/routes/notification_routes.dart
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../services/notification_service.dart';
import '../utils/jwt_helper.dart';

class NotificationRoutes {
  final NotificationService _notificationService = NotificationService();

  Router get router {
    final router = Router();

    // Middleware d'authentification
    Future<Response?> _authMiddleware(Request request) async {
      final userId = JwtHelper.extractUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'success': false, 'message': 'Non authentifié'}),
        );
      }
      return null;
    }

    // Récupérer toutes les notifications
    router.get('/', (Request request) async {
      final authCheck = await _authMiddleware(request);
      if (authCheck != null) return authCheck;

      final userId = JwtHelper.extractUserId(request)!;
      final queryParams = request.url.queryParameters;
      
      final type = queryParams['type'];
      final isRead = queryParams['isRead'] != null 
          ? queryParams['isRead'] == 'true' 
          : null;
      final limit = int.tryParse(queryParams['limit'] ?? '50') ?? 50;
      final offset = int.tryParse(queryParams['offset'] ?? '0') ?? 0;

      final notifications = await _notificationService.getNotifications(
        userId,
        type: type,
        isRead: isRead,
        limit: limit,
        offset: offset,
      );

      final unreadCount = await _notificationService.getUnreadCount(userId);

      return Response.ok(jsonEncode({
        'success': true,
        'notifications': notifications,
        'unreadCount': unreadCount,
        'total': notifications.length,
      }));
    });

    // Récupérer le nombre de notifications non lues
    router.get('/unread-count', (Request request) async {
      final authCheck = await _authMiddleware(request);
      if (authCheck != null) return authCheck;

      final userId = JwtHelper.extractUserId(request)!;
      final count = await _notificationService.getUnreadCount(userId);

      return Response.ok(jsonEncode({
        'success': true,
        'unreadCount': count,
      }));
    });

    // Marquer une notification comme lue
    router.patch('/<notificationId>/read', (Request request, String notificationId) async {
      final authCheck = await _authMiddleware(request);
      if (authCheck != null) return authCheck;

      final userId = JwtHelper.extractUserId(request)!;

      // Vérifier que la notification appartient à l'utilisateur
      final notification = await _notificationService.getNotification(notificationId);
      if (notification == null || notification['userId'] != userId) {
        return Response.forbidden(
          jsonEncode({'success': false, 'message': 'Accès non autorisé'}),
        );
      }

      await _notificationService.markAsRead(notificationId);

      return Response.ok(jsonEncode({
        'success': true,
        'message': 'Notification marquée comme lue',
      }));
    });

    // Marquer toutes les notifications comme lues
    router.post('/read-all', (Request request) async {
      final authCheck = await _authMiddleware(request);
      if (authCheck != null) return authCheck;

      final userId = JwtHelper.extractUserId(request)!;
      await _notificationService.markAllAsRead(userId);

      return Response.ok(jsonEncode({
        'success': true,
        'message': 'Toutes les notifications ont été marquées comme lues',
      }));
    });

    // Supprimer une notification
    router.delete('/<notificationId>', (Request request, String notificationId) async {
      final authCheck = await _authMiddleware(request);
      if (authCheck != null) return authCheck;

      final userId = JwtHelper.extractUserId(request)!;

      // Vérifier que la notification appartient à l'utilisateur
      final notification = await _notificationService.getNotification(notificationId);
      if (notification == null || notification['userId'] != userId) {
        return Response.forbidden(
          jsonEncode({'success': false, 'message': 'Accès non autorisé'}),
        );
      }

      await _notificationService.deleteNotification(notificationId);

      return Response.ok(jsonEncode({
        'success': true,
        'message': 'Notification supprimée',
      }));
    });

    // Supprimer toutes les notifications
    router.delete('/all', (Request request) async {
      final authCheck = await _authMiddleware(request);
      if (authCheck != null) return authCheck;

      final userId = JwtHelper.extractUserId(request)!;
      await _notificationService.deleteAllNotifications(userId);

      return Response.ok(jsonEncode({
        'success': true,
        'message': 'Toutes les notifications ont été supprimées',
      }));
    });

    return router;
  }
}