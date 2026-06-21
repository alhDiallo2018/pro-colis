// backend/lib/services/notification_service.dart
import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:procolis_backend/services/database_service.dart';
import 'package:uuid/uuid.dart';

class NotificationService {
  final _uuid = const Uuid();
  final _log = Logger('NotificationService');

  // ==================== MÉTHODES CRUD ====================

  Future<void> createNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    String? parcelId,
    String? bidId,
    String? senderId,
    String? senderName,
    Map<String, dynamic>? data,
    String priority = 'normal',
  }) async {
    final db = await DatabaseService.getInstance();
    final notificationId = _uuid.v4();
    final now = DateTime.now();

    try {
      await db.connection.execute('''
        INSERT INTO notifications (
          id, user_id, parcel_id, bid_id, sender_id, sender_name,
          type, title, body, data, is_read, priority, created_at
        ) VALUES (
          \$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10, false, \$11, \$12
        )
      ''', parameters: [
        notificationId,
        userId,
        parcelId,
        bidId,
        senderId,
        senderName,
        type,
        title,
        body,
        jsonEncode(data ?? {}),
        priority,
        now,
      ]);

      _log.info('✅ Notification créée pour $userId: $title');
    } catch (e) {
      _log.severe('❌ Erreur création notification: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getNotifications(
    String userId, {
    String? type,
    bool? isRead,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await DatabaseService.getInstance();

    try {
      var query = '''
        SELECT 
          id, user_id, parcel_id, bid_id, sender_id, sender_name,
          type, title, body, data, is_read, priority, created_at, read_at
        FROM notifications
        WHERE user_id = \$1
      ''';
      final params = <dynamic>[userId];
      var paramIndex = 2;

      if (type != null) {
        query += ' AND type = \$$paramIndex';
        params.add(type);
        paramIndex++;
      }

      if (isRead != null) {
        query += ' AND is_read = \$$paramIndex';
        params.add(isRead);
        paramIndex++;
      }

      query += ' ORDER BY created_at DESC LIMIT \$$paramIndex OFFSET \$${paramIndex + 1}';
      params.add(limit);
      params.add(offset);

      final result = await db.connection.execute(query, parameters: params);

      return result.map((row) {
        Map<String, dynamic> data = {};
        try {
          final dataStr = row[9]?.toString();
          if (dataStr != null && dataStr.isNotEmpty && dataStr != 'null') {
            data = jsonDecode(dataStr);
          }
        } catch (e) {
          data = {};
        }

        return {
          'id': row[0],
          'userId': row[1],
          'parcelId': row[2],
          'bidId': row[3],
          'senderId': row[4],
          'senderName': row[5],
          'type': row[6],
          'title': row[7],
          'body': row[8],
          'data': data,
          'isRead': row[10] == true,
          'priority': row[11],
          'createdAt': (row[12] as DateTime).toIso8601String(),
          'readAt': row[13] != null ? (row[13] as DateTime).toIso8601String() : null,
        };
      }).toList();
    } catch (e) {
      _log.severe('❌ Erreur getNotifications: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getNotification(String notificationId) async {
    final db = await DatabaseService.getInstance();

    try {
      final result = await db.connection.execute('''
        SELECT 
          id, user_id, parcel_id, bid_id, sender_id, sender_name,
          type, title, body, data, is_read, priority, created_at, read_at
        FROM notifications
        WHERE id = \$1
      ''', parameters: [notificationId]);

      if (result.isEmpty) return null;

      final row = result.first;
      Map<String, dynamic> data = {};
      try {
        final dataStr = row[9]?.toString();
        if (dataStr != null && dataStr.isNotEmpty && dataStr != 'null') {
          data = jsonDecode(dataStr);
        }
      } catch (e) {
        data = {};
      }

      return {
        'id': row[0],
        'userId': row[1],
        'parcelId': row[2],
        'bidId': row[3],
        'senderId': row[4],
        'senderName': row[5],
        'type': row[6],
        'title': row[7],
        'body': row[8],
        'data': data,
        'isRead': row[10] == true,
        'priority': row[11],
        'createdAt': (row[12] as DateTime).toIso8601String(),
        'readAt': row[13] != null ? (row[13] as DateTime).toIso8601String() : null,
      };
    } catch (e) {
      _log.severe('❌ Erreur getNotification: $e');
      return null;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final db = await DatabaseService.getInstance();

    try {
      await db.connection.execute('''
        UPDATE notifications 
        SET is_read = true, read_at = NOW()
        WHERE id = \$1
      ''', parameters: [notificationId]);
      
      _log.info('✅ Notification marquée comme lue: $notificationId');
    } catch (e) {
      _log.severe('❌ Erreur markAsRead: $e');
    }
  }

  Future<void> markAllAsRead(String userId) async {
    final db = await DatabaseService.getInstance();

    try {
      await db.connection.execute('''
        UPDATE notifications 
        SET is_read = true, read_at = NOW()
        WHERE user_id = \$1 AND is_read = false
      ''', parameters: [userId]);
      
      _log.info('✅ Toutes les notifications marquées comme lues pour $userId');
    } catch (e) {
      _log.severe('❌ Erreur markAllAsRead: $e');
    }
  }

  Future<int> getUnreadCount(String userId) async {
    final db = await DatabaseService.getInstance();

    try {
      final result = await db.connection.execute('''
        SELECT COUNT(*) FROM notifications
        WHERE user_id = \$1 AND is_read = false
      ''', parameters: [userId]);

      return int.parse(result.first[0].toString());
    } catch (e) {
      _log.severe('❌ Erreur getUnreadCount: $e');
      return 0;
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    final db = await DatabaseService.getInstance();

    try {
      await db.connection.execute('''
        DELETE FROM notifications WHERE id = \$1
      ''', parameters: [notificationId]);
      
      _log.info('🗑️ Notification supprimée: $notificationId');
    } catch (e) {
      _log.severe('❌ Erreur deleteNotification: $e');
    }
  }

  Future<void> deleteAllNotifications(String userId) async {
    final db = await DatabaseService.getInstance();

    try {
      await db.connection.execute('''
        DELETE FROM notifications WHERE user_id = \$1
      ''', parameters: [userId]);
      
      _log.info('🗑️ Toutes les notifications supprimées pour $userId');
    } catch (e) {
      _log.severe('❌ Erreur deleteAllNotifications: $e');
    }
  }

  // ==================== MÉTHODES DE NOTIFICATION SPÉCIFIQUES ====================

  /// Notification: Colis créé
  Future<void> notifyParcelCreated({
    required String parcelId,
    required String senderId,
    required String senderEmail,
    required String receiverId,
    required String trackingNumber,
    required String receiverName,
  }) async {
    // Notifier l'expéditeur
    await createNotification(
      userId: senderId,
      type: 'parcel_created',
      title: '📦 Nouveau colis créé',
      body: 'Votre colis $trackingNumber a été créé avec succès',
      parcelId: parcelId,
      data: {
        'type': 'parcel_created',
        'trackingNumber': trackingNumber,
        'receiverName': receiverName,
        'role': 'sender',
      },
      priority: 'normal',
    );

    // Notifier le destinataire
    await createNotification(
      userId: receiverId,
      type: 'parcel_created',
      title: '📦 Nouveau colis en route',
      body: 'Un colis $trackingNumber vous a été envoyé par $senderEmail',
      parcelId: parcelId,
      data: {
        'type': 'parcel_created',
        'trackingNumber': trackingNumber,
        'senderEmail': senderEmail,
        'role': 'receiver',
      },
      priority: 'normal',
    );

    _log.info('📦 Notification: Colis créé - $trackingNumber');
  }

  /// Notification: Mise à jour de statut
  Future<void> notifyStatusUpdate({
    required String parcelId,
    required String userId,
    required String status,
    required String trackingNumber,
    String? userName,
  }) async {
    final statusLabels = {
      'confirmed': '✅ Colis confirmé',
      'picked_up': '📦 Colis ramassé',
      'in_transit': '🚚 Colis en transit',
      'arrived': '📍 Colis arrivé',
      'out_for_delivery': '🚛 Colis en livraison',
      'delivered': '🎉 Colis livré',
      'cancelled': '❌ Colis annulé',
    };

    final statusBodies = {
      'confirmed': 'Votre colis $trackingNumber a été confirmé',
      'picked_up': 'Votre colis $trackingNumber a été ramassé',
      'in_transit': 'Votre colis $trackingNumber est en transit',
      'arrived': 'Votre colis $trackingNumber est arrivé au garage',
      'out_for_delivery': 'Votre colis $trackingNumber est en cours de livraison',
      'delivered': 'Votre colis $trackingNumber a été livré avec succès 🎉',
      'cancelled': 'Votre colis $trackingNumber a été annulé',
    };

    await createNotification(
      userId: userId,
      type: 'parcel_status',
      title: statusLabels[status] ?? '📦 Mise à jour du colis',
      body: statusBodies[status] ?? 'Mise à jour du statut de votre colis $trackingNumber',
      parcelId: parcelId,
      data: {
        'type': 'parcel_status',
        'status': status,
        'trackingNumber': trackingNumber,
        'userName': userName,
      },
      priority: status == 'delivered' || status == 'cancelled' ? 'high' : 'normal',
    );

    _log.info('📢 Notification: Statut mis à jour - $trackingNumber -> $status');
  }

  /// Notification: Ramassage confirmé
  Future<void> notifyPickupConfirmed({
    required String parcelId,
    required String senderId,
    required String receiverId,
    required String trackingNumber,
    required String driverName,
  }) async {
    // Notifier l'expéditeur
    await createNotification(
      userId: senderId,
      type: 'parcel_status',
      title: '📦 Colis ramassé',
      body: 'Votre colis $trackingNumber a été ramassé par le chauffeur $driverName',
      parcelId: parcelId,
      data: {
        'type': 'pickup_confirmed',
        'trackingNumber': trackingNumber,
        'driverName': driverName,
        'role': 'sender',
      },
      priority: 'high',
    );

    // Notifier le destinataire
    await createNotification(
      userId: receiverId,
      type: 'parcel_status',
      title: '📦 Colis en route',
      body: 'Votre colis $trackingNumber a été ramassé et est en route vers vous',
      parcelId: parcelId,
      data: {
        'type': 'pickup_confirmed',
        'trackingNumber': trackingNumber,
        'driverName': driverName,
        'role': 'receiver',
      },
      priority: 'high',
    );

    _log.info('✅ Notification: Colis ramassé - $trackingNumber');
  }

  /// Notification: Colis livré
  Future<void> notifyDelivered({
    required String parcelId,
    required String senderId,
    required String receiverId,
    required String trackingNumber,
    required String receiverName,
    required String? signature,
  }) async {
    // Notifier l'expéditeur
    await createNotification(
      userId: senderId,
      type: 'delivery_confirmed',
      title: '🎉 Colis livré !',
      body: 'Votre colis $trackingNumber a été livré avec succès à $receiverName',
      parcelId: parcelId,
      data: {
        'type': 'delivery_confirmed',
        'trackingNumber': trackingNumber,
        'receiverName': receiverName,
        'signature': signature,
        'role': 'sender',
      },
      priority: 'urgent',
    );

    // Notifier le destinataire
    await createNotification(
      userId: receiverId,
      type: 'delivery_confirmed',
      title: '🎉 Colis reçu !',
      body: 'Vous avez bien reçu le colis $trackingNumber',
      parcelId: parcelId,
      data: {
        'type': 'delivery_confirmed',
        'trackingNumber': trackingNumber,
        'signature': signature,
        'role': 'receiver',
      },
      priority: 'urgent',
    );

    _log.info('🎉 Notification: Colis livré - $trackingNumber');
  }

  /// Notification: Offre créée
  Future<void> notifyBidCreated({
    required String parcelId,
    required String clientId,
    required String driverId,
    required String driverName,
    required double price,
    required String trackingNumber,
  }) async {
    await createNotification(
      userId: clientId,
      type: 'bid_created',
      title: '💰 Nouvelle offre reçue',
      body: '$driverName a fait une offre de ${price.toStringAsFixed(0)} FCFA sur votre colis $trackingNumber',
      parcelId: parcelId,
      senderId: driverId,
      senderName: driverName,
      data: {
        'type': 'bid_created',
        'driverId': driverId,
        'driverName': driverName,
        'price': price,
        'trackingNumber': trackingNumber,
      },
      priority: 'high',
    );

    _log.info('💰 Notification: Nouvelle offre sur $trackingNumber');
  }

  /// Notification: Offre acceptée
  Future<void> notifyBidAccepted({
    required String parcelId,
    required String driverId,
    required String clientId,
    required String clientName,
    required double price,
    required String trackingNumber,
  }) async {
    await createNotification(
      userId: driverId,
      type: 'bid_accepted',
      title: '✅ Offre acceptée',
      body: 'Votre offre de ${price.toStringAsFixed(0)} FCFA a été acceptée par $clientName pour le colis $trackingNumber',
      parcelId: parcelId,
      senderId: clientId,
      senderName: clientName,
      data: {
        'type': 'bid_accepted',
        'clientId': clientId,
        'clientName': clientName,
        'price': price,
        'trackingNumber': trackingNumber,
      },
      priority: 'high',
    );

    _log.info('✅ Notification: Offre acceptée sur $trackingNumber');
  }

  /// Notification: Offre refusée
  Future<void> notifyBidRejected({
    required String parcelId,
    required String driverId,
    required String clientName,
    required String trackingNumber,
    String? responseMessage,
  }) async {
    await createNotification(
      userId: driverId,
      type: 'bid_rejected',
      title: '❌ Offre refusée',
      body: 'Votre offre a été refusée par $clientName pour le colis $trackingNumber${responseMessage != null ? ' : $responseMessage' : ''}',
      parcelId: parcelId,
      data: {
        'type': 'bid_rejected',
        'clientName': clientName,
        'trackingNumber': trackingNumber,
        'responseMessage': responseMessage,
      },
      priority: 'normal',
    );

    _log.info('❌ Notification: Offre refusée sur $trackingNumber');
  }

  /// Notification: Chauffeur assigné
  Future<void> notifyDriverAssigned({
    required String parcelId,
    required String userId,
    required String driverName,
    required String trackingNumber,
  }) async {
    await createNotification(
      userId: userId,
      type: 'driver_assigned',
      title: '🚚 Chauffeur assigné',
      body: 'Le chauffeur $driverName a été assigné à votre colis $trackingNumber',
      parcelId: parcelId,
      data: {
        'type': 'driver_assigned',
        'driverName': driverName,
        'trackingNumber': trackingNumber,
      },
      priority: 'high',
    );

    _log.info('🚚 Notification: Chauffeur assigné à $trackingNumber');
  }

  /// Notification: Paiement confirmé
  Future<void> notifyPaymentConfirmed({
    required String paymentId,
    required String userId,
    required double amount,
    required String paymentMethod,
    required String trackingNumber,
  }) async {
    await createNotification(
      userId: userId,
      type: 'system',
      title: '💰 Paiement confirmé',
      body: 'Votre paiement de ${amount.toStringAsFixed(0)} FCFA par $paymentMethod pour le colis $trackingNumber a été confirmé',
      data: {
        'type': 'payment_confirmed',
        'paymentId': paymentId,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'trackingNumber': trackingNumber,
      },
      priority: 'high',
    );

    _log.info('💰 Notification: Paiement confirmé pour $trackingNumber');
  }

  /// Notification: Colis annulé
  Future<void> notifyCancelled({
    required String parcelId,
    required String userId,
    required String trackingNumber,
    required String reason,
  }) async {
    await createNotification(
      userId: userId,
      type: 'parcel_status',
      title: '❌ Colis annulé',
      body: 'Votre colis $trackingNumber a été annulé : $reason',
      parcelId: parcelId,
      data: {
        'type': 'parcel_cancelled',
        'trackingNumber': trackingNumber,
        'reason': reason,
      },
      priority: 'urgent',
    );

    _log.info('❌ Notification: Colis annulé - $trackingNumber');
  }

  /// Notification: Message reçu
  Future<void> notifyMessageReceived({
    required String userId,
    required String senderId,
    required String senderName,
    required String message,
    String? parcelId,
  }) async {
    await createNotification(
      userId: userId,
      type: 'message',
      title: '💬 Nouveau message',
      body: '$senderName vous a envoyé un message : "${message.length > 50 ? '${message.substring(0, 50)}...' : message}"',
      parcelId: parcelId,
      senderId: senderId,
      senderName: senderName,
      data: {
        'type': 'message_received',
        'message': message,
        'senderId': senderId,
        'senderName': senderName,
      },
      priority: 'normal',
    );

    _log.info('💬 Notification: Nouveau message de $senderName');
  }

  /// Notification: Offre de contre-offre
  Future<void> notifyCounterOffer({
    required String parcelId,
    required String userId,
    required String senderName,
    required double price,
    required String trackingNumber,
  }) async {
    await createNotification(
      userId: userId,
      type: 'bid_created',
      title: '🔄 Contre-offre reçue',
      body: '$senderName propose une contre-offre de ${price.toStringAsFixed(0)} FCFA pour le colis $trackingNumber',
      parcelId: parcelId,
      data: {
        'type': 'counter_offer',
        'senderName': senderName,
        'price': price,
        'trackingNumber': trackingNumber,
      },
      priority: 'high',
    );

    _log.info('🔄 Notification: Contre-offre sur $trackingNumber');
  }
}