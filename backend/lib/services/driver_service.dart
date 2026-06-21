// backend/lib/services/driver_service.dart
import 'package:procolis_backend/services/database_service.dart';
import 'package:procolis_backend/services/notification_service.dart';

class DriverService {
  final NotificationService _notificationService = NotificationService();

  Future<List<Map<String, dynamic>>> searchDrivers({
    String? query,
    int limit = 20,
  }) async {
    final db = await DatabaseService.getInstance();
    
    try {
      String sql = '''
        SELECT id, full_name, email, phone, vehicle_plate, vehicle_model, driver_status
        FROM users WHERE role = 'driver' AND status = 'active'
      ''';
      
      final List<dynamic> params = [];
      int paramCounter = 1;
      
      if (query != null && query.isNotEmpty) {
        sql += ' AND (full_name ILIKE \$$paramCounter OR email ILIKE \$$paramCounter OR phone ILIKE \$$paramCounter OR id::text ILIKE \$$paramCounter)';
        params.add('%$query%');
        paramCounter++;
      }
      
      sql += ' ORDER BY full_name ASC LIMIT \$$paramCounter';
      params.add(limit);
      
      print('🔍 SQL: $sql');
      print('🔍 Params: $params');
      
      final result = await db.connection.execute(sql, parameters: params);
      
      print('✅ ${result.length} chauffeurs trouvés');
      
      return result.map((row) => ({
        'id': row[0].toString(),
        'fullName': row[1].toString(),
        'email': row[2].toString(),
        'phone': row[3].toString(),
        'vehiclePlate': row[4]?.toString(),
        'vehicleModel': row[5]?.toString(),
        'driverStatus': row[6]?.toString() ?? 'offline',
      })).toList();
    } catch (e) {
      print('❌ Erreur searchDrivers: $e');
      return [];
    }
  }
  
  Future<Map<String, dynamic>?> getDriverById(String driverId) async {
    final db = await DatabaseService.getInstance();
    
    try {
      final result = await db.connection.execute(
        'SELECT id, full_name, email, phone, vehicle_plate, vehicle_model, driver_status '
        'FROM users WHERE id = \$1 AND role = \'driver\' AND status = \'active\'',
        parameters: [driverId]
      );
      
      if (result.isEmpty) return null;
      
      final row = result.first;
      return {
        'id': row[0].toString(),
        'fullName': row[1].toString(),
        'email': row[2].toString(),
        'phone': row[3].toString(),
        'vehiclePlate': row[4]?.toString(),
        'vehicleModel': row[5]?.toString(),
        'driverStatus': row[6]?.toString() ?? 'offline',
      };
    } catch (e) {
      print('❌ Erreur getDriverById: $e');
      return null;
    }
  }
  
  Future<List<Map<String, dynamic>>> getDriversByGarage(String garageId) async {
    final db = await DatabaseService.getInstance();
    
    try {
      final result = await db.connection.execute(
        'SELECT id, full_name, email, phone, vehicle_plate, vehicle_model, driver_status '
        'FROM users WHERE role = \'driver\' AND garage_id = \$1 AND status = \'active\' '
        'ORDER BY full_name ASC',
        parameters: [garageId]
      );
      
      return result.map((row) => ({
        'id': row[0].toString(),
        'fullName': row[1].toString(),
        'email': row[2].toString(),
        'phone': row[3].toString(),
        'vehiclePlate': row[4]?.toString(),
        'vehicleModel': row[5]?.toString(),
        'driverStatus': row[6]?.toString() ?? 'offline',
      })).toList();
    } catch (e) {
      print('❌ Erreur getDriversByGarage: $e');
      return [];
    }
  }
  
  Future<void> updateDriverStatus(String driverId, String status) async {
    final db = await DatabaseService.getInstance();
    
    try {
      // Récupérer les infos du chauffeur pour la notification
      final driverInfo = await db.connection.execute(
        'SELECT full_name FROM users WHERE id = \$1',
        parameters: [driverId],
      );
      
      final driverName = driverInfo.isNotEmpty ? driverInfo.first[0].toString() : 'Chauffeur';

      await db.connection.execute(
        'UPDATE users SET driver_status = \$2, updated_at = NOW() WHERE id = \$1',
        parameters: [driverId, status]
      );
      
      print('✅ Statut du chauffeur $driverId mis à jour: $status');

      // ✅ NOTIFICATION: Changement de statut du chauffeur
      final statusLabels = {
        'available': '🟢 Disponible',
        'busy': '🔴 En livraison',
        'offline': '⚪ Hors ligne',
      };

      await _notificationService.createNotification(
        userId: driverId,
        type: 'system',
        title: '🚚 Statut mis à jour',
        body: 'Votre statut a été changé vers : ${statusLabels[status] ?? status}',
        priority: status == 'busy' ? 'high' : 'normal',
        data: {
          'type': 'driver_status_changed',
          'newStatus': status,
        },
      );

      // Si le chauffeur devient disponible, notifier les clients potentiels
      if (status == 'available') {
        // Récupérer les clients qui ont des colis en attente de chauffeur
        final pendingParcels = await db.connection.execute('''
          SELECT sender_id, tracking_number, departure_garage_name 
          FROM parcels 
          WHERE driver_id IS NULL 
            AND status = 'pending' 
            AND is_free_for_bidding = false
          LIMIT 5
        ''');

        for (final parcel in pendingParcels) {
          final clientId = parcel[0].toString();
          final trackingNumber = parcel[1].toString();
          
          await _notificationService.createNotification(
            userId: clientId,
            type: 'system',
            title: '🚚 Chauffeur disponible !',
            body: 'Un nouveau chauffeur ($driverName) est disponible pour prendre votre colis $trackingNumber',
            priority: 'high',
            data: {
              'type': 'driver_available',
              'driverId': driverId,
              'driverName': driverName,
              'trackingNumber': trackingNumber,
            },
          );
        }
      }

    } catch (e) {
      print('❌ Erreur updateDriverStatus: $e');
    }
  }
  
  // Nouvelle méthode pour obtenir tous les chauffeurs avec plus de détails
  Future<List<Map<String, dynamic>>> getAllDrivers({int limit = 100}) async {
    final db = await DatabaseService.getInstance();
    
    try {
      final result = await db.connection.execute(
        'SELECT '
          'id, '
          'full_name, '
          'email, '
          'phone, '
          'vehicle_plate, '
          'vehicle_model, '
          'vehicle_color, '
          'driver_status, '
          'rating, '
          'total_deliveries, '
          'profile_photo, '
          'garage_id, '
          'garage_name '
        'FROM users '
        'WHERE role = \'driver\' AND status = \'active\' '
        'ORDER BY full_name ASC '
        'LIMIT \$1',
        parameters: [limit]
      );
      
      print('✅ ${result.length} chauffeurs chargés (getAllDrivers)');
      
      return result.map((row) => ({
        'id': row[0].toString(),
        'fullName': row[1].toString(),
        'email': row[2].toString(),
        'phone': row[3].toString(),
        'vehiclePlate': row[4]?.toString(),
        'vehicleModel': row[5]?.toString(),
        'vehicleColor': row[6]?.toString(),
        'driverStatus': row[7]?.toString() ?? 'offline',
        'rating': row[8] != null ? (row[8] is double ? row[8] : double.tryParse(row[8].toString()) ?? 0.0) : null,
        'totalDeliveries': row[9] != null ? (row[9] is int ? row[9] : int.tryParse(row[9].toString()) ?? 0) : null,
        'profilePhoto': row[10]?.toString(),
        'garageId': row[11]?.toString(),
        'garageName': row[12]?.toString(),
      })).toList();
    } catch (e) {
      print('❌ Erreur getAllDrivers: $e');
      return [];
    }
  }

  // ✅ NOUVELLE MÉTHODE: Assigner un chauffeur à un colis
  Future<Map<String, dynamic>> assignDriverToParcel({
    required String parcelId,
    required String driverId,
    String? assignedBy,
  }) async {
    final db = await DatabaseService.getInstance();

    try {
      // Vérifier que le chauffeur existe et est disponible
      final driverResult = await db.connection.execute(
        'SELECT full_name, phone, driver_status FROM users WHERE id = \$1 AND role = \'driver\' AND status = \'active\'',
        parameters: [driverId],
      );

      if (driverResult.isEmpty) {
        return {'success': false, 'message': 'Chauffeur non trouvé ou inactif'};
      }

      final driverName = driverResult.first[0].toString();
      final driverPhone = driverResult.first[1].toString();
      final driverStatus = driverResult.first[2]?.toString() ?? 'offline';

      if (driverStatus == 'busy') {
        return {'success': false, 'message': 'Ce chauffeur est actuellement en livraison'};
      }

      // Récupérer les infos du colis
      final parcelResult = await db.connection.execute(
        'SELECT tracking_number, sender_id, receiver_name FROM parcels WHERE id = \$1 AND driver_id IS NULL',
        parameters: [parcelId],
      );

      if (parcelResult.isEmpty) {
        return {'success': false, 'message': 'Colis non trouvé ou déjà assigné'};
      }

      final trackingNumber = parcelResult.first[0].toString();
      final senderId = parcelResult.first[1].toString();
      final receiverName = parcelResult.first[2].toString();

      // Assigner le chauffeur
      await db.connection.execute('''
        UPDATE parcels 
        SET driver_id = \$2, driver_name = \$3, driver_phone = \$4, status = 'confirmed', updated_at = NOW()
        WHERE id = \$1
      ''', parameters: [parcelId, driverId, driverName, driverPhone]);

      // ✅ NOTIFICATION: Chauffeur assigné au client
      await _notificationService.createNotification(
        userId: senderId,
        type: 'driver_assigned',
        title: '🚚 Chauffeur assigné à votre colis !',
        body: 'Le chauffeur $driverName a été assigné à votre colis $trackingNumber',
        parcelId: parcelId,
        priority: 'high',
        data: {
          'type': 'driver_assigned_to_parcel',
          'driverId': driverId,
          'driverName': driverName,
          'driverPhone': driverPhone,
          'trackingNumber': trackingNumber,
          'receiverName': receiverName,
        },
      );

      // ✅ NOTIFICATION: Nouveau colis assigné au chauffeur
      await _notificationService.createNotification(
        userId: driverId,
        type: 'system',
        title: '📦 Nouveau colis assigné !',
        body: 'Vous avez été assigné au colis $trackingNumber pour $receiverName',
        parcelId: parcelId,
        priority: 'high',
        data: {
          'type': 'new_parcel_assigned',
          'parcelId': parcelId,
          'trackingNumber': trackingNumber,
          'receiverName': receiverName,
        },
      );

      // Mettre à jour le statut du chauffeur
      await updateDriverStatus(driverId, 'busy');

      return {
        'success': true,
        'message': 'Chauffeur assigné avec succès',
        'driverId': driverId,
        'driverName': driverName,
        'trackingNumber': trackingNumber,
      };
    } catch (e) {
      print('❌ Erreur assignDriverToParcel: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ✅ NOUVELLE MÉTHODE: Libérer un chauffeur
  Future<Map<String, dynamic>> releaseDriver(String driverId) async {
    final db = await DatabaseService.getInstance();

    try {
      // Vérifier que le chauffeur n'a pas de colis en cours
      final activeParcels = await db.connection.execute(
        'SELECT id FROM parcels WHERE driver_id = \$1 AND status NOT IN (\'delivered\', \'cancelled\')',
        parameters: [driverId],
      );

      if (activeParcels.isNotEmpty) {
        return {
          'success': false,
          'message': 'Ce chauffeur a encore ${activeParcels.length} colis en cours'
        };
      }

      // Mettre à jour le statut
      await updateDriverStatus(driverId, 'available');

      // ✅ NOTIFICATION: Chauffeur disponible
      await _notificationService.createNotification(
        userId: driverId,
        type: 'system',
        title: '🚚 Vous êtes maintenant disponible',
        body: 'Vous pouvez accepter de nouvelles livraisons',
        priority: 'normal',
        data: {
          'type': 'driver_released',
          'status': 'available',
        },
      );

      return {
        'success': true,
        'message': 'Chauffeur libéré avec succès',
        'status': 'available',
      };
    } catch (e) {
      print('❌ Erreur releaseDriver: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ✅ NOUVELLE MÉTHODE: Obtenir les statistiques d'un chauffeur
  Future<Map<String, dynamic>> getDriverStats(String driverId) async {
    final db = await DatabaseService.getInstance();

    try {
      final result = await db.connection.execute('''
        SELECT 
          COUNT(*) as total,
          SUM(CASE WHEN status = 'delivered' THEN 1 ELSE 0 END) as delivered,
          SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) as cancelled,
          SUM(CASE WHEN status IN ('picked_up', 'in_transit', 'arrived', 'out_for_delivery') THEN 1 ELSE 0 END) as in_progress,
          COALESCE(AVG(r.rating), 0) as avg_rating
        FROM parcels p
        LEFT JOIN ratings r ON r.driver_id = p.driver_id
        WHERE p.driver_id = \$1
      ''', parameters: [driverId]);

      if (result.isEmpty) {
        return {
          'success': true,
          'stats': {
            'total': 0,
            'delivered': 0,
            'cancelled': 0,
            'inProgress': 0,
            'rating': 0,
          }
        };
      }

      final row = result.first;
      return {
        'success': true,
        'stats': {
          'total': row[0] as int? ?? 0,
          'delivered': row[1] as int? ?? 0,
          'cancelled': row[2] as int? ?? 0,
          'inProgress': row[3] as int? ?? 0,
          'rating': row[4] != null ? (row[4] is double ? row[4] : double.tryParse(row[4].toString()) ?? 0.0) : 0.0,
        }
      };
    } catch (e) {
      print('❌ Erreur getDriverStats: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
}