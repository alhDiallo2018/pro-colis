// lib/routes/client_routes.dart
import 'dart:convert';

import 'package:procolis_backend/services/database_service.dart';
import 'package:procolis_backend/services/email_service.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import '../services/parcel_service.dart';
import '../services/user_service.dart';
import '../utils/jwt_helper.dart';

class ClientRoutes {
  late ParcelService _parcelService;
  final UserService _userService = UserService();

  ClientRoutes({required EmailService emailService}) {
    _parcelService = ParcelService(emailService: emailService);
  }

  Router get router {
    final router = Router();

    // Middleware pour vérifier l'authentification
    Future<Response?> _authMiddleware(Request request) async {
      final userId = JwtHelper.extractUserId(request);
      if (userId == null) {
        return Response.forbidden(
            jsonEncode({'success': false, 'message': 'Non authentifié'}));
      }
      return null;
    }

    // ==================== PROFIL ====================

    router.get('/users/me', (Request request) async {
      final authCheck = await _authMiddleware(request);
      if (authCheck != null) return authCheck;

      final userId = JwtHelper.extractUserId(request)!;
      try {
        final user = await _userService.getUserById(userId);
        if (user == null) {
          return Response.notFound(jsonEncode(
              {'success': false, 'message': 'Utilisateur non trouvé'}));
        }
        return Response.ok(jsonEncode({'success': true, 'user': user}));
      } catch (e) {
        return Response.internalServerError(
            body: jsonEncode({'success': false, 'message': e.toString()}));
      }
    });

    router.put('/profile', (Request request) async {
      final authCheck = await _authMiddleware(request);
      if (authCheck != null) return authCheck;

      final userId = JwtHelper.extractUserId(request)!;
      try {
        final body = await request.readAsString();
        final data = jsonDecode(body);
        await _userService.updateProfile(userId, data);
        return Response.ok(
            jsonEncode({'success': true, 'message': 'Profil mis à jour'}));
      } catch (e) {
        return Response.internalServerError(
            body: jsonEncode({'success': false, 'message': e.toString()}));
      }
    });

    router.put('/users/pin', (Request request) async {
      final authCheck = await _authMiddleware(request);
      if (authCheck != null) return authCheck;

      final userId = JwtHelper.extractUserId(request)!;
      try {
        final body = await request.readAsString();
        final data = jsonDecode(body);
        await _userService.updatePin(
            userId, data['currentPin'], data['newPin']);
        return Response.ok(
            jsonEncode({'success': true, 'message': 'PIN mis à jour'}));
      } catch (e) {
        return Response.internalServerError(
            body: jsonEncode({'success': false, 'message': e.toString()}));
      }
    });

    router.put('/profile-photo', (Request request) async {
      final authCheck = await _authMiddleware(request);
      if (authCheck != null) return authCheck;

      final userId = JwtHelper.extractUserId(request)!;

      try {
        final body = await request.readAsString();
        final data = jsonDecode(body);
        final photoUrl = data['photoUrl'];

        if (photoUrl == null || photoUrl.isEmpty) {
          return Response.badRequest(
              body: jsonEncode(
                  {'success': false, 'message': 'URL de photo invalide'}));
        }

        final db = await DatabaseService.getInstance();
        await db.connection.execute('''
          UPDATE users 
          SET profile_photo = \$2, updated_at = NOW()
          WHERE id = \$1
        ''', parameters: [userId, photoUrl]);

        print('✅ Photo de profil mise à jour: $userId');

        return Response.ok(jsonEncode({
          'success': true,
          'message': 'Photo de profil mise à jour avec succès'
        }));
      } catch (e) {
        print('❌ Erreur update profile photo: $e');
        return Response.internalServerError(
            body: jsonEncode({'success': false, 'message': e.toString()}));
      }
    });

    // ==================== COLIS ====================

    router.post('/parcels/create', (Request request) async {
      final authCheck = await _authMiddleware(request);
      if (authCheck != null) return authCheck;

      final userId = JwtHelper.extractUserId(request)!;
      try {
        final body = await request.readAsString();
        final data = jsonDecode(body);
        final result = await _parcelService.createParcel(userId, data);
        return Response.ok(jsonEncode(result));
      } catch (e) {
        return Response.internalServerError(
            body: jsonEncode({'success': false, 'message': e.toString()}));
      }
    });

    router.get('/parcels/my-parcels', (Request request) async {
      final authCheck = await _authMiddleware(request);
      if (authCheck != null) return authCheck;

      final userId = JwtHelper.extractUserId(request)!;
      try {
        final parcels = await _parcelService.getUserParcels(userId);
        return Response.ok(jsonEncode({'success': true, 'parcels': parcels}));
      } catch (e) {
        return Response.internalServerError(
            body: jsonEncode({'success': false, 'message': e.toString()}));
      }
    });

    router.get('/parcels/track/<trackingNumber>',
        (Request request, String trackingNumber) async {
      try {
        final parcel = await _parcelService.trackParcel(trackingNumber);
        if (parcel == null) {
          return Response.notFound(
              jsonEncode({'success': false, 'message': 'Colis non trouvé'}));
        }
        return Response.ok(jsonEncode({'success': true, 'parcel': parcel}));
      } catch (e) {
        return Response.internalServerError(
            body: jsonEncode({'success': false, 'message': e.toString()}));
      }
    });

    router.get('/parcels/<parcelId>', (Request request, String parcelId) async {
      final authCheck = await _authMiddleware(request);
      if (authCheck != null) return authCheck;

      try {
        final parcel = await _parcelService.getParcelById(parcelId);
        if (parcel == null) {
          return Response.notFound(
              jsonEncode({'success': false, 'message': 'Colis non trouvé'}));
        }
        return Response.ok(jsonEncode({'success': true, 'parcel': parcel}));
      } catch (e) {
        return Response.internalServerError(
            body: jsonEncode({'success': false, 'message': e.toString()}));
      }
    });

    router.put('/parcels/<parcelId>/cancel',
        (Request request, String parcelId) async {
      final authCheck = await _authMiddleware(request);
      if (authCheck != null) return authCheck;

      final userId = JwtHelper.extractUserId(request)!;
      try {
        await _parcelService.cancelParcel(parcelId, userId);
        return Response.ok(
            jsonEncode({'success': true, 'message': 'Colis annulé'}));
      } catch (e) {
        return Response.internalServerError(
            body: jsonEncode({'success': false, 'message': e.toString()}));
      }
    });

    router.get('/parcels/<parcelId>/events',
        (Request request, String parcelId) async {
      final authCheck = await _authMiddleware(request);
      if (authCheck != null) return authCheck;

      final userId = JwtHelper.extractUserId(request)!;
      try {
        // Vérifier que l'utilisateur a accès à ce colis
        final parcel = await _parcelService.getParcelById(parcelId);
        if (parcel == null) {
          return Response.notFound(
              jsonEncode({'success': false, 'message': 'Colis non trouvé'}));
        }

        // Vérifier que l'utilisateur est le sender, le driver, ou un admin
        if (parcel['sender_id'] != userId &&
            parcel['driver_id'] != userId &&
            !(await JwtHelper.isAdmin(userId))) {
          return Response.forbidden(
              jsonEncode({'success': false, 'message': 'Accès non autorisé'}));
        }

        final events = await _parcelService.getParcelEvents(parcelId);
        return Response.ok(jsonEncode({'success': true, 'events': events}));
      } catch (e) {
        return Response.internalServerError(
            body: jsonEncode({'success': false, 'message': e.toString()}));
      }
    });

// lib/routes/client_routes.dart

// REMPLACEZ la route /parcels/<parcelId>/media par celle-ci :

// Mettre à jour les médias du colis (photos et vidéos) - pour CLIENTS
    router.patch('/parcels/<parcelId>/media',
        (Request request, String parcelId) async {
      final authCheck = await _authMiddleware(request);
      if (authCheck != null) return authCheck;

      final userId = JwtHelper.extractUserId(request)!;
      print('🔑 Client - Mise à jour médias pour colis: $parcelId');

      try {
        final body = await request.readAsString();
        final data = jsonDecode(body);

        final List<String> newPhotoUrls =
            (data['photoUrls'] as List?)?.cast<String>() ?? [];
        final List<String> newVideoUrls =
            (data['videoUrls'] as List?)?.cast<String>() ?? [];

        print('📸 Nouvelles photos reçues: $newPhotoUrls');
        print('🎬 Nouvelles vidéos reçues: $newVideoUrls');

        final db = await DatabaseService.getInstance();

        // 🔧 CORRECTION: Vérifier que le colis appartient au client (sender_id)
        final existingResult = await db.connection.execute('''
      SELECT photo_urls, video_urls FROM parcels WHERE id = \$1 AND sender_id = \$2
    ''', parameters: [parcelId, userId]);

        if (existingResult.isEmpty) {
          return Response.notFound(jsonEncode({
            'success': false,
            'message': 'Colis non trouvé ou non autorisé'
          }));
        }

        final existingRow = existingResult.first;

        // Fonction pour convertir PostgreSQL ARRAY en List<String>
        List<String> pgArrayToList(dynamic pgArray) {
          if (pgArray == null) return [];
          String str = pgArray.toString();
          if (str.isEmpty || str == '{}') return [];
          str = str.substring(1, str.length - 1);
          if (str.isEmpty) return [];
          return str
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
        }

        final List<String> existingPhotoUrls = pgArrayToList(existingRow[0]);
        final List<String> existingVideoUrls = pgArrayToList(existingRow[1]);

        print('📸 Photos existantes: $existingPhotoUrls');
        print('🎬 Vidéos existantes: $existingVideoUrls');

        // Fusionner sans doublons
        final Set<String> allPhotoUrlsSet = {
          ...existingPhotoUrls,
          ...newPhotoUrls
        };
        final Set<String> allVideoUrlsSet = {
          ...existingVideoUrls,
          ...newVideoUrls
        };

        final List<String> allPhotoUrls = allPhotoUrlsSet.toList();
        final List<String> allVideoUrls = allVideoUrlsSet.toList();

        print('📸 Photos finales (sans doublons): $allPhotoUrls');
        print('🎬 Vidéos finales (sans doublons): $allVideoUrls');

        // Fonction pour convertir List en PostgreSQL ARRAY
        String listToPgArray(List<String> list) {
          if (list.isEmpty) return '{}';
          return '{${list.join(',')}}';
        }

        final String pgPhotoUrls = listToPgArray(allPhotoUrls);
        final String pgVideoUrls = listToPgArray(allVideoUrls);

        // 🔧 CORRECTION: Mettre à jour avec sender_id au lieu de driver_id
        await db.connection.execute('''
      UPDATE parcels 
      SET photo_urls = \$2::TEXT[], 
          video_urls = \$3::TEXT[], 
          updated_at = NOW()
      WHERE id = \$1 AND sender_id = \$4
    ''', parameters: [parcelId, pgPhotoUrls, pgVideoUrls, userId]);

        print(
            '✅ Médias mis à jour avec succès pour le colis $parcelId par le client');

        // Récupérer le colis mis à jour
        final updatedParcel = await _parcelService.getParcelById(parcelId);

        return Response.ok(jsonEncode({
          'success': true,
          'message': 'Médias mis à jour avec succès',
          'parcel': updatedParcel
        }));
      } catch (e) {
        print('❌ Erreur mise à jour médias (client): $e');
        return Response.internalServerError(
            body: jsonEncode({'success': false, 'message': e.toString()}));
      }
    });

    // ==================== GESTION DES OFFRES (MARCHANDAGE) ====================

// Accepter une offre sur un colis
    router.post('/parcels/<parcelId>/bids/<bidId>/accept',
        (Request request, String parcelId, String bidId) async {
      final authCheck = await _authMiddleware(request);
      if (authCheck != null) return authCheck;

      final clientId = JwtHelper.extractUserId(request)!;
      print(
          '✅ Client $clientId accepte l\'offre $bidId pour le colis $parcelId');

      try {
        // Vérifier que le colis appartient au client
        final db = await DatabaseService.getInstance();
        final parcelResult = await db.connection.execute('''
      SELECT sender_id FROM parcels WHERE id = \$1
    ''', parameters: [parcelId]);

        if (parcelResult.isEmpty) {
          return Response.notFound(
              jsonEncode({'success': false, 'message': 'Colis non trouvé'}));
        }

        final senderId = parcelResult.first[0].toString();
        if (senderId != clientId) {
          return Response.forbidden(
              jsonEncode({'success': false, 'message': 'Non autorisé'}));
        }

        final result = await _parcelService.acceptBid(bidId, clientId);

        if (result['success'] == true) {
          return Response.ok(jsonEncode(result));
        } else {
          return Response.badRequest(
              body:
                  jsonEncode({'success': false, 'message': result['message']}));
        }
      } catch (e) {
        print('❌ Erreur acceptBid: $e');
        return Response.internalServerError(
            body: jsonEncode({'success': false, 'message': e.toString()}));
      }
    });

// Refuser une offre sur un colis
    router.post('/parcels/<parcelId>/bids/<bidId>/reject',
        (Request request, String parcelId, String bidId) async {
      final authCheck = await _authMiddleware(request);
      if (authCheck != null) return authCheck;

      final clientId = JwtHelper.extractUserId(request)!;
      print(
          '❌ Client $clientId refuse l\'offre $bidId pour le colis $parcelId');

      try {
        // Vérifier que le colis appartient au client
        final db = await DatabaseService.getInstance();
        final parcelResult = await db.connection.execute('''
      SELECT sender_id FROM parcels WHERE id = \$1
    ''', parameters: [parcelId]);

        if (parcelResult.isEmpty) {
          return Response.notFound(
              jsonEncode({'success': false, 'message': 'Colis non trouvé'}));
        }

        final senderId = parcelResult.first[0].toString();
        if (senderId != clientId) {
          return Response.forbidden(
              jsonEncode({'success': false, 'message': 'Non autorisé'}));
        }

        final body = await request.readAsString();
        final data = body.isNotEmpty ? jsonDecode(body) : {};
        final responseMessage = data['responseMessage']?.toString();

        final result = await _parcelService.rejectBid(bidId, clientId,
            responseMessage: responseMessage);

        if (result['success'] == true) {
          return Response.ok(jsonEncode(result));
        } else {
          return Response.badRequest(
              body:
                  jsonEncode({'success': false, 'message': result['message']}));
        }
      } catch (e) {
        print('❌ Erreur rejectBid: $e');
        return Response.internalServerError(
            body: jsonEncode({'success': false, 'message': e.toString()}));
      }
    });

// Récupérer les offres reçues par le client
    router.get('/parcels/bids/received', (Request request) async {
      final authCheck = await _authMiddleware(request);
      if (authCheck != null) return authCheck;

      final clientId = JwtHelper.extractUserId(request)!;

      try {
        final db = await DatabaseService.getInstance();

        // Récupérer tous les colis du client avec leurs offres
        final result = await db.connection.execute('''
      SELECT 
        p.id, p.tracking_number, p.description,
        p.departure_garage_name, p.arrival_garage_name,
        COALESCE(
          (SELECT json_agg(json_build_object(
            'id', b.id,
            'driver_id', b.driver_id,
            'driver_name', b.driver_name,
            'driver_phone', b.driver_phone,
            'price', b.price,
            'message', b.message,
            'status', b.status,
            'created_at', b.created_at
          )) FROM bids b WHERE b.parcel_id = p.id),
          '[]'::json
        ) as bids
      FROM parcels p
      WHERE p.sender_id = \$1
      ORDER BY p.created_at DESC
    ''', parameters: [clientId]);

        final parcels = result
            .map((row) => {
                  'id': row[0],
                  'trackingNumber': row[1],
                  'description': row[2],
                  'departureGarageName': row[3],
                  'arrivalGarageName': row[4],
                  'bids': jsonDecode(row[5].toString()),
                })
            .toList();

        return Response.ok(jsonEncode({
          'success': true,
          'parcels': parcels,
        }));
      } catch (e) {
        print('❌ Erreur getReceivedBids: $e');
        return Response.internalServerError(
            body: jsonEncode({'success': false, 'message': e.toString()}));
      }
    });

// Négocier une offre (faire une contre-offre)
    router.post('/parcels/bids/<bidId>/negotiate',
        (Request request, String bidId) async {
      final authCheck = await _authMiddleware(request);
      if (authCheck != null) return authCheck;

      final clientId = JwtHelper.extractUserId(request)!;
      print('🤝 Client $clientId négocie l\'offre $bidId');

      try {
        final body = await request.readAsString();
        final data = jsonDecode(body);
        final counterPrice = data['counterPrice'] is num
            ? (data['counterPrice'] as num).toDouble()
            : double.tryParse(data['counterPrice'].toString());
        final message = data['message']?.toString();

        if (counterPrice == null || counterPrice <= 0) {
          return Response.badRequest(
              body: jsonEncode(
                  {'success': false, 'message': 'Prix valide requis'}));
        }

        final db = await DatabaseService.getInstance();

        // Récupérer l'offre
        final bidResult = await db.connection.execute('''
      SELECT b.*, p.sender_id
      FROM bids b
      JOIN parcels p ON p.id = b.parcel_id
      WHERE b.id = \$1
    ''', parameters: [bidId]);

        if (bidResult.isEmpty) {
          return Response.notFound(
              jsonEncode({'success': false, 'message': 'Offre non trouvée'}));
        }

        final row = bidResult.first;
        final senderId = row[12].toString();

        if (senderId != clientId) {
          return Response.forbidden(
              jsonEncode({'success': false, 'message': 'Non autorisé'}));
        }

        // Créer une contre-offre (nouvelle offre avec le nouveau prix)
        final newBidId = const Uuid().v4();
        final driverId = row[2].toString();
        final driverName = row[3].toString();
        final driverPhone = row[4].toString();
        final originalPrice = double.tryParse(row[5].toString()) ?? 0;

        await db.connection.execute('''
      INSERT INTO bids (
        id, parcel_id, driver_id, driver_name, driver_phone,
        price, message, status, created_at, parent_bid_id
      ) VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, 'pending', \$8, \$9)
    ''', parameters: [
          newBidId,
          row[1],
          driverId,
          driverName,
          driverPhone,
          counterPrice,
          message,
          DateTime.now(),
          bidId
        ]);

        // Marquer l'offre originale comme "negotiating"
        await db.connection.execute('''
      UPDATE bids SET status = 'negotiating', updated_at = NOW() WHERE id = \$1
    ''', parameters: [bidId]);

        // Créer un événement
        await _parcelService.createParcelEvent(
          row[1].toString(),
          'free',
          'Contre-offre proposée: ${counterPrice.toStringAsFixed(0)} FCFA',
          userId: clientId,
          userName: 'Client',
          metadata: {
            'type': 'counter_offer',
            'originalBidId': bidId,
            'originalPrice': originalPrice,
            'counterPrice': counterPrice,
            'newBidId': newBidId,
          },
        );

        return Response.ok(jsonEncode({
          'success': true,
          'message': 'Contre-offre envoyée avec succès',
          'bidId': newBidId,
          'counterPrice': counterPrice,
        }));
      } catch (e) {
        print('❌ Erreur negotiateBid: $e');
        return Response.internalServerError(
            body: jsonEncode({'success': false, 'message': e.toString()}));
      }
    });

    return router;
  }
}
