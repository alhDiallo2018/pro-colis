// lib/services/parcel_service.dart
import 'package:uuid/uuid.dart';

import '../utils/db_helper.dart';

class ParcelService {
  final _uuid = Uuid();
  
  Future<Map<String, dynamic>> createParcel(String userId, Map<String, dynamic> data) async {
    final db = await DbHelper.getInstance();
    final parcelId = _uuid.v4();
    final trackingNumber = 'PC-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}-${_uuid.v4().substring(0, 6).toUpperCase()}';
    
    // Récupérer les infos de l'expéditeur
    final senderResult = await db.connection.execute(
      'SELECT full_name, phone FROM users WHERE id = \$1',
      parameters: [userId],
    );
    
    final senderName = senderResult.first[0];
    final senderPhone = senderResult.first[1];
    
    await db.connection.execute('''
      INSERT INTO parcels (id, tracking_number, sender_id, sender_name, sender_phone, 
             receiver_name, receiver_phone, receiver_email, description, weight, type, status,
             departure_garage_id, departure_garage_name, arrival_garage_id, arrival_garage_name,
             price, driver_id, driver_name, driver_phone, created_at, updated_at)
      VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10, \$11, \$12, \$13, \$14, \$15, \$16, \$17, \$18, \$19, \$20, NOW(), NOW())
    ''', parameters: [
      parcelId, trackingNumber, userId, senderName, senderPhone,
      data['receiverName'], data['receiverPhone'], data['receiverEmail'],
      data['description'], data['weight'], data['type'] ?? 'package', 'pending',
      data['departureGarageId'], data['departureGarageName'],
      data['arrivalGarageId'], data['arrivalGarageName'],
      data['price'], data['driverId'], data['driverName'], data['driverPhone']
    ]);
    
    return {
      'success': true,
      'message': 'Colis créé avec succès',
      'parcel': {'id': parcelId, 'trackingNumber': trackingNumber}
    };
  }
  
  Future<List<Map<String, dynamic>>> getUserParcels(String userId) async {
    final db = await DbHelper.getInstance();
    
    try {
      final result = await db.connection.execute('''
        SELECT id, tracking_number, receiver_name, status, weight, price, created_at
        FROM parcels WHERE sender_id = \$1 ORDER BY created_at DESC
      ''', parameters: [userId]);
      
      return result.map((row) => ({
        'id': row[0], 'trackingNumber': row[1], 'receiverName': row[2],
        'status': row[3], 'weight': row[4], 'price': row[5],
        'createdAt': (row[6] as DateTime).toIso8601String(),
      })).toList();
    } catch (e) {
      return [];
    }
  }
  
  Future<Map<String, dynamic>?> trackParcel(String trackingNumber) async {
    final db = await DbHelper.getInstance();
    
    try {
      final result = await db.connection.execute('''
        SELECT id, tracking_number, sender_name, receiver_name, receiver_phone, status, 
               description, weight, price, created_at
        FROM parcels WHERE tracking_number = \$1
      ''', parameters: [trackingNumber]);
      
      if (result.isEmpty) return null;
      
      final row = result.first;
      return {
        'id': row[0], 'trackingNumber': row[1], 'senderName': row[2],
        'receiverName': row[3], 'receiverPhone': row[4], 'status': row[5],
        'description': row[6], 'weight': row[7], 'price': row[8],
        'createdAt': (row[9] as DateTime).toIso8601String(),
      };
    } catch (e) {
      return null;
    }
  }
  
  Future<Map<String, dynamic>?> getParcelById(String parcelId) async {
    final db = await DbHelper.getInstance();
    
    try {
      final result = await db.connection.execute(
        'SELECT * FROM parcels WHERE id = \$1',
        parameters: [parcelId],
      );
      
      if (result.isEmpty) return null;
      
      final row = result.first;
      return {
        'id': row[0], 'trackingNumber': row[1], 'senderName': row[3],
        'receiverName': row[5], 'status': row[11], 'price': row[19],
        'driverId': row[17], 'driverName': row[18],
        'createdAt': (row[26] as DateTime).toIso8601String(),
      };
    } catch (e) {
      return null;
    }
  }
  
  Future<List<Map<String, dynamic>>> getDriverParcels(String driverId) async {
    final db = await DbHelper.getInstance();
    
    try {
      final result = await db.connection.execute('''
        SELECT 
          p.id, 
          p.tracking_number, 
          p.sender_name, 
          p.sender_phone,
          p.receiver_name, 
          p.receiver_phone,
          p.receiver_email,
          p.description, 
          p.weight,
          p.type,
          p.status, 
          p.departure_garage_name,
          p.arrival_garage_name,
          p.driver_name,
          p.driver_phone,
          p.price,
          p.payment_method,
          p.payment_status,
          p.photo_urls,
          p.signature_url,
          p.pickup_date,
          p.delivery_date,
          p.created_at,
          p.updated_at
        FROM parcels p
        WHERE p.driver_id = \$1 
        ORDER BY p.created_at DESC
      ''', parameters: [driverId]);
      
      print('✅ ${result.length} colis trouvés pour le chauffeur $driverId');
      
      return result.map((row) => ({
        'id': row[0],
        'trackingNumber': row[1],
        'senderName': row[2],
        'senderPhone': row[3],
        'receiverName': row[4],
        'receiverPhone': row[5],
        'receiverEmail': row[6],
        'description': row[7],
        'weight': row[8],
        'type': row[9],
        'status': row[10],
        'departureGarageName': row[11],
        'arrivalGarageName': row[12],
        'driverName': row[13],
        'driverPhone': row[14],
        'price': row[15],
        'paymentMethod': row[16],
        'paymentStatus': row[17],
        'photoUrls': row[18] ?? [],
        'signatureUrl': row[19],
        'pickupDate': row[20] != null ? (row[20] as DateTime).toIso8601String() : null,
        'deliveryDate': row[21] != null ? (row[21] as DateTime).toIso8601String() : null,
        'createdAt': (row[22] as DateTime).toIso8601String(),
        'updatedAt': row[23] != null ? (row[23] as DateTime).toIso8601String() : null,
      })).toList();
    } catch (e) {
      print('❌ Erreur getDriverParcels: $e');
      return [];
    }
  }
  
  Future<void> confirmPickup(String parcelId, String driverId) async {
    final db = await DbHelper.getInstance();
    
    await db.connection.execute(
      'UPDATE parcels SET status = \'picked_up\', updated_at = NOW() WHERE id = \$1 AND driver_id = \$2',
      parameters: [parcelId, driverId],
    );
  }
  
  Future<void> confirmDelivery(String parcelId, String driverId, Map<String, dynamic> data) async {
    final db = await DbHelper.getInstance();
    
    await db.connection.execute('''
      UPDATE parcels SET status = 'delivered', signature_url = \$3, delivery_date = NOW(), updated_at = NOW()
      WHERE id = \$1 AND driver_id = \$2
    ''', parameters: [parcelId, driverId, data['signature']]);
  }
  
  // ==================== CORRECTION IMPORTANTE ====================
  // Ajout des champs driver_id et driver_name dans la requête
  Future<List<Map<String, dynamic>>> getGarageParcels(String garageId) async {
    final db = await DbHelper.getInstance();
    
    try {
      final result = await db.connection.execute('''
        SELECT 
          p.id, 
          p.tracking_number, 
          p.sender_name, 
          p.receiver_name, 
          p.receiver_phone,
          p.status, 
          p.driver_id,
          p.driver_name,
          p.description, 
          p.weight,
          p.type,
          p.price,
          p.created_at
        FROM parcels p
        WHERE p.departure_garage_id = \$1 OR p.arrival_garage_id = \$1
        ORDER BY p.created_at DESC
      ''', parameters: [garageId]);
      
      print('✅ ${result.length} colis trouvés pour le garage $garageId');
      
      return result.map((row) => ({
        'id': row[0],
        'trackingNumber': row[1],
        'senderName': row[2],
        'receiverName': row[3],
        'receiverPhone': row[4],
        'status': row[5],
        'driverId': row[6],        // ← AJOUTÉ
        'driverName': row[7],      // ← AJOUTÉ
        'description': row[8],
        'weight': row[9],
        'type': row[10],
        'price': row[11],
        'createdAt': (row[12] as DateTime).toIso8601String(),
      })).toList();
    } catch (e) {
      print('❌ Erreur getGarageParcels: $e');
      return [];
    }
  }
  
  Future<void> assignDriverToParcel(String parcelId, String driverId) async {
    final db = await DbHelper.getInstance();
    
    // Récupérer les infos du chauffeur
    final driverResult = await db.connection.execute(
      'SELECT full_name, phone FROM users WHERE id = \$1',
      parameters: [driverId],
    );
    
    await db.connection.execute('''
      UPDATE parcels SET driver_id = \$2, driver_name = \$3, driver_phone = \$4, 
             status = 'confirmed', updated_at = NOW()
      WHERE id = \$1
    ''', parameters: [parcelId, driverId, driverResult.first[0], driverResult.first[1]]);
  }
  
  Future<void> cancelParcel(String parcelId, String userId) async {
    final db = await DbHelper.getInstance();
    
    await db.connection.execute(
      'UPDATE parcels SET status = \'cancelled\', updated_at = NOW() WHERE id = \$1 AND sender_id = \$2',
      parameters: [parcelId, userId],
    );
  }

  Future<void> cancelParcelWithReason(String parcelId, String userId, String? reason) async {
    final db = await DbHelper.getInstance();
    
    await db.connection.execute('''
      UPDATE parcels 
      SET status = 'cancelled', 
          cancellation_reason = \$3,
          cancelled_by = \$2,
          cancelled_at = NOW(),
          updated_at = NOW()
      WHERE id = \$1
    ''', parameters: [parcelId, userId, reason]);
    
    // Créer un événement d'annulation
    await createParcelEvent(
      parcelId, 
      'cancelled', 
      'Colis annulé: ${reason ?? "Annulation par l\'admin"}', 
      userId: userId
    );
  }
  
  Future<List<Map<String, dynamic>>> getAllParcels() async {
    final db = await DbHelper.getInstance();
    
    try {
      final result = await db.connection.execute('''
        SELECT id, tracking_number, sender_name, receiver_name, status, price, created_at
        FROM parcels ORDER BY created_at DESC
      ''');
      
      return result.map((row) => ({
        'id': row[0], 'trackingNumber': row[1], 'senderName': row[2],
        'receiverName': row[3], 'status': row[4], 'price': row[5],
        'createdAt': (row[6] as DateTime).toIso8601String(),
      })).toList();
    } catch (e) {
      return [];
    }
  }
  
  Future<void> updateParcel(String parcelId, Map<String, dynamic> data) async {
    final db = await DbHelper.getInstance();
    
    await db.connection.execute('''
      UPDATE parcels SET status = \$2, price = \$3, driver_id = \$4, updated_at = NOW()
      WHERE id = \$1
    ''', parameters: [parcelId, data['status'], data['price'], data['driverId']]);
  }

  Future<List<Map<String, dynamic>>> getParcelEvents(String parcelId) async {
    final db = await DbHelper.getInstance();
    
    try {
      final result = await db.connection.execute('''
        SELECT id, parcel_id, status, description, location, user_id, user_name, metadata, created_at
        FROM parcel_events 
        WHERE parcel_id = \$1 
        ORDER BY created_at ASC
      ''', parameters: [parcelId]);
      
      return result.map((row) => ({
        'id': row[0],
        'parcelId': row[1],
        'status': row[2],
        'description': row[3],
        'location': row[4],
        'userId': row[5],
        'userName': row[6],
        'metadata': row[7],
        'timestamp': (row[8] as DateTime).toIso8601String(),
      })).toList();
    } catch (e) {
      print('❌ Erreur getParcelEvents: $e');
      return [];
    }
  }

  Future<void> createParcelEvent(String parcelId, String status, String description, 
      {String? location, String? userId, String? userName}) async {
    final db = await DbHelper.getInstance();
    final eventId = _uuid.v4();
    
    await db.connection.execute('''
      INSERT INTO parcel_events (id, parcel_id, status, description, location, user_id, user_name, created_at)
      VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, NOW())
    ''', parameters: [eventId, parcelId, status, description, location, userId, userName]);
  }

  Future<void> updateParcelStatus(String parcelId, String status, 
      {String? location, String? userId, String? userName}) async {
    final db = await DbHelper.getInstance();
    
    // Mettre à jour le statut du colis
    await db.connection.execute('''
      UPDATE parcels SET status = \$2, updated_at = NOW() WHERE id = \$1
    ''', parameters: [parcelId, status]);
    
    // Créer un événement
    await createParcelEvent(
      parcelId, 
      status, 
      _getStatusDescription(status), 
      location: location,
      userId: userId,
      userName: userName
    );
  }

  String _getStatusDescription(String status) {
    switch (status) {
      case 'pending': return 'Colis créé';
      case 'confirmed': return 'Colis confirmé';
      case 'picked_up': return 'Colis ramassé';
      case 'in_transit': return 'Colis en transit';
      case 'arrived': return 'Colis arrivé au garage';
      case 'out_for_delivery': return 'Colis en livraison';
      case 'delivered': return 'Colis livré';
      case 'cancelled': return 'Colis annulé';
      default: return 'Statut mis à jour';
    }
  }
  
  Future<void> deleteParcel(String parcelId) async {
    final db = await DbHelper.getInstance();
    
    await db.connection.execute('DELETE FROM parcels WHERE id = \$1', parameters: [parcelId]);
  }
}