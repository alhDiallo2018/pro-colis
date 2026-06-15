// ignore_for_file: unused_local_variable

import 'dart:convert';

import 'package:procolis_backend/services/database_service.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../services/parcel_service.dart';

class ParcelController {
  final ParcelService _parcelService;

  ParcelController({required ParcelService parcelService})
      : _parcelService = parcelService;

  Router get router {
    final router = Router();

    // Routes clients
    router.post('/create', _createParcel);
    router.get('/my-parcels', _getMyParcels);
    router.get('/track/<tracking>', _trackParcel);
    router.get('/<id>', _getParcel);
    router.put('/<id>/cancel', _cancelParcel);
    router.put('/<id>/update-info', _updateParcelInfo);
    router.get('/<id>/events', _getEvents);
    router.get('/<id>/timeline', _getTimeline);
    
    // 🆕 Routes libre service (client)
    router.patch('/<id>/free-bidding', _setParcelFreeForBidding);
    router.post('/<id>/bids/<bidId>/accept', _acceptBid);
    router.post('/<id>/bids/<bidId>/reject', _rejectBid);
    router.get('/client/bids/received', _getClientReceivedBids);

    // Routes chauffeurs
    router.get('/driver/assigned', _getDriverParcels);
    router.put('/driver/<id>/status', _updateStatusByDriver);
    router.put('/driver/<id>/pickup', _confirmPickup);
    router.put('/driver/<id>/transit', _markAsInTransit);
    router.put('/driver/<id>/arrived', _markAsArrived);
    router.put('/driver/<id>/out-for-delivery', _markAsOutForDelivery);
    router.put('/driver/<id>/deliver', _confirmDelivery);
    router.get('/driver/stats', _getDriverStats);
    router.get('/driver/history', _getDriverHistory);
    
    // 🆕 Routes libre service (chauffeur)
    router.post('/driver/bids', _createBid);
    router.get('/driver/bids/sent', _getDriverSentBids);

    // Routes publiques
    router.get('/public/free', _getFreeParcels);
    router.get('/public/<id>/bids', _getParcelBids);

    // Routes garage admin
    router.get('/garage/parcels', _getGarageParcels);
    router.get('/garage/parcels/status/<status>', _getGarageParcelsByStatus);
    router.put('/garage/<id>/assign-driver', _assignDriverToParcel);
    router.put('/garage/<id>/status', _updateStatusByGarage);
    router.get('/garage/stats', _getGarageStats);
    router.get('/garage/drivers', _getGarageDrivers);

    // Routes super admin
    router.get('/admin/all', _getAllParcels);
    router.get('/admin/status/<status>', _getParcelsByStatus);
    router.get('/admin/search', _searchParcels);
    router.put('/admin/<id>/update', _updateParcel);
    router.put('/admin/<id>/cancel-reason', _cancelParcelWithReason);
    router.delete('/admin/<id>', _deleteParcel);
    router.get('/admin/stats/global', _getGlobalStats);
    router.get('/admin/reports/daily', _getDailyReport);
    router.get('/admin/reports/monthly', _getMonthlyReport);

    return router;
  }

  // ==================== METHODES UTILITAIRES ====================

  String _extractUserId(Request request) {
    final token = request.headers['Authorization']?.replaceFirst('Bearer ', '');
    if (token == null) return '';
    final parts = token.split('_');
    if (parts.length < 2) return '';
    return parts[1];
  }

  String _extractUserRole(Request request) {
    final token = request.headers['Authorization']?.replaceFirst('Bearer ', '');
    if (token == null) return '';
    final parts = token.split('_');
    if (parts.length < 3) return '';
    return parts[2];
  }

  String _extractUserName(Request request) {
    final token = request.headers['Authorization']?.replaceFirst('Bearer ', '');
    if (token == null) return '';
    final parts = token.split('_');
    if (parts.length < 4) return '';
    return Uri.decodeComponent(parts[3]);
  }

  // ==================== ROUTES CLIENTS ====================

  Future<Response> _createParcel(Request request) async {
    try {
      final userId = _extractUserId(request);
      if (userId.isEmpty) {
        return Response.forbidden(jsonEncode({
          'success': false,
          'message': 'Token manquant ou invalide',
        }));
      }

      final body = await request.readAsString();
      final data = jsonDecode(body);

      final requiredFields = [
        'receiverName',
        'receiverPhone',
        'description',
        'weight',
        'departureGarageId'
      ];
      for (var field in requiredFields) {
        if (data[field] == null) {
          return Response.badRequest(
              body: jsonEncode({
            'success': false,
            'message': 'Le champ $field est requis',
          }));
        }
      }

      final result = await _parcelService.createParcel(userId, data);
      return Response.ok(jsonEncode({
        'success': true,
        'message': 'Colis créé avec succès',
        'parcel': result,
      }));
    } catch (e) {
      print('❌ Erreur création: $e');
      return Response.internalServerError(
          body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de la création: $e',
      }));
    }
  }

  Future<Response> _getMyParcels(Request request) async {
    try {
      final userId = _extractUserId(request);
      if (userId.isEmpty) {
        return Response.forbidden(jsonEncode({
          'success': false,
          'message': 'Token manquant ou invalide',
        }));
      }
      final status = request.url.queryParameters['status'];
      final parcels =
          await _parcelService.getUserParcels(userId, status: status);
      return Response.ok(jsonEncode({
        'success': true,
        'parcels': parcels,
      }));
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de la récupération: $e',
      }));
    }
  }

  Future<Response> _trackParcel(Request request, String tracking) async {
    try {
      final parcel = await _parcelService.getParcelByTrackingNumber(tracking);
      if (parcel == null) {
        return Response.notFound(jsonEncode({
          'success': false,
          'message': 'Colis non trouvé',
        }));
      }
      return Response.ok(jsonEncode({
        'success': true,
        'parcel': parcel,
      }));
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({
        'success': false,
        'message': 'Erreur lors du suivi: $e',
      }));
    }
  }

  Future<Response> _getParcel(Request request, String id) async {
    try {
      final parcel = await _parcelService.getParcelById(id);
      if (parcel == null) {
        return Response.notFound(jsonEncode({
          'success': false,
          'message': 'Colis non trouvé',
        }));
      }
      return Response.ok(jsonEncode({
        'success': true,
        'parcel': parcel,
      }));
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de la récupération: $e',
      }));
    }
  }

  Future<Response> _cancelParcel(Request request, String id) async {
    try {
      final userId = _extractUserId(request);
      final userName = _extractUserName(request);
      final body = await request.readAsString();
      final data = body.isEmpty ? {} : jsonDecode(body);

      final parcel = await _parcelService.cancelParcel(
        id,
        userId,
        reason: data['reason'],
        userName: userName,
      );
      if (parcel == null) {
        return Response.notFound(jsonEncode({
          'success': false,
          'message': 'Colis non trouvé',
        }));
      }
      return Response.ok(jsonEncode({
        'success': true,
        'message': 'Colis annulé avec succès',
        'parcel': parcel,
      }));
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de l\'annulation: $e',
      }));
    }
  }

  Future<Response> _updateParcelInfo(Request request, String id) async {
    try {
      final userId = _extractUserId(request);
      final userName = _extractUserName(request);
      final body = await request.readAsString();
      final data = jsonDecode(body);

      final parcel = await _parcelService.updateParcelInfo(
        id,
        data,
        updatedBy: userId,
        updatedByName: userName,
      );
      if (parcel == null) {
        return Response.notFound(jsonEncode({
          'success': false,
          'message': 'Colis non trouvé',
        }));
      }
      return Response.ok(jsonEncode({
        'success': true,
        'message': 'Colis modifié avec succès',
        'parcel': parcel,
      }));
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de la modification: $e',
      }));
    }
  }

  Future<Response> _getEvents(Request request, String id) async {
    try {
      final events = await _parcelService.getParcelEvents(id);
      return Response.ok(jsonEncode({
        'success': true,
        'events': events,
      }));
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de la récupération: $e',
      }));
    }
  }

  Future<Response> _getTimeline(Request request, String id) async {
    try {
      final parcel = await _parcelService.getParcelById(id);
      if (parcel == null) {
        return Response.notFound(jsonEncode({
          'success': false,
          'message': 'Colis non trouvé',
        }));
      }
      return Response.ok(jsonEncode({
        'success': true,
        'timeline': parcel['events'],
      }));
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de la récupération: $e',
      }));
    }
  }

  // ==================== 🆕 ROUTES LIBRE SERVICE (CLIENT) ====================

  Future<Response> _setParcelFreeForBidding(Request request, String id) async {
    try {
      final clientId = _extractUserId(request);
      if (clientId.isEmpty) {
        return Response.forbidden(jsonEncode({
          'success': false,
          'message': 'Token manquant ou invalide',
        }));
      }

      final body = await request.readAsString();
      final data = body.isEmpty ? {} : jsonDecode(body);
      final proposedPrice = data['proposedPrice'] != null 
          ? (data['proposedPrice'] as num).toDouble() 
          : null;

      final result = await _parcelService.setParcelFreeForBidding(
        id,
        clientId,
        proposedPrice: proposedPrice,
      );

      if (!result['success']) {
        return Response.badRequest(body: jsonEncode(result));
      }

      return Response.ok(jsonEncode({
        'success': true,
        'message': 'Colis mis en libre service avec succès',
      }));
    } catch (e) {
      print('❌ Erreur setParcelFreeForBidding: $e');
      return Response.internalServerError(
          body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de la mise en libre service: $e',
      }));
    }
  }

  Future<Response> _acceptBid(Request request, String id, String bidId) async {
    try {
      final clientId = _extractUserId(request);
      if (clientId.isEmpty) {
        return Response.forbidden(jsonEncode({
          'success': false,
          'message': 'Token manquant ou invalide',
        }));
      }

      final result = await _parcelService.acceptBid(bidId, clientId);

      if (!result['success']) {
        return Response.badRequest(body: jsonEncode(result));
      }

      return Response.ok(jsonEncode({
        'success': true,
        'message': 'Offre acceptée avec succès',
        'parcelId': result['parcelId'],
        'driverId': result['driverId'],
        'driverName': result['driverName'],
      }));
    } catch (e) {
      print('❌ Erreur acceptBid: $e');
      return Response.internalServerError(
          body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de l\'acceptation: $e',
      }));
    }
  }

  Future<Response> _rejectBid(Request request, String id, String bidId) async {
    try {
      final clientId = _extractUserId(request);
      if (clientId.isEmpty) {
        return Response.forbidden(jsonEncode({
          'success': false,
          'message': 'Token manquant ou invalide',
        }));
      }

      final body = await request.readAsString();
      final data = body.isEmpty ? {} : jsonDecode(body);
      final responseMessage = data['responseMessage']?.toString();

      final result = await _parcelService.rejectBid(
        bidId,
        clientId,
        responseMessage: responseMessage,
      );

      if (!result['success']) {
        return Response.badRequest(body: jsonEncode(result));
      }

      return Response.ok(jsonEncode({
        'success': true,
        'message': 'Offre refusée',
      }));
    } catch (e) {
      print('❌ Erreur rejectBid: $e');
      return Response.internalServerError(
          body: jsonEncode({
        'success': false,
        'message': 'Erreur lors du refus: $e',
      }));
    }
  }

  Future<Response> _getClientReceivedBids(Request request) async {
    try {
      final clientId = _extractUserId(request);
      if (clientId.isEmpty) {
        return Response.forbidden(jsonEncode({
          'success': false,
          'message': 'Token manquant ou invalide',
        }));
      }

      // Récupérer tous les colis du client qui ont des offres
      final parcels = await _parcelService.getUserParcels(clientId);
      final parcelsWithBids = [];

      for (final parcel in parcels) {
        final bids = await _parcelService.getParcelBids(parcel['id']);
        if (bids.isNotEmpty) {
          parcelsWithBids.add({
            'parcel': parcel,
            'bids': bids,
          });
        }
      }

      return Response.ok(jsonEncode({
        'success': true,
        'bids': parcelsWithBids,
      }));
    } catch (e) {
      print('❌ Erreur getClientReceivedBids: $e');
      return Response.internalServerError(
          body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de la récupération: $e',
      }));
    }
  }

  // ==================== ROUTES CHAUFFEURS ====================

  Future<Response> _getDriverParcels(Request request) async {
    try {
      final driverId = _extractUserId(request);
      if (driverId.isEmpty) {
        return Response.forbidden(jsonEncode({
          'success': false,
          'message': 'Token manquant ou invalide',
        }));
      }
      final parcels = await _parcelService.getDriverParcels(driverId);
      return Response.ok(jsonEncode({
        'success': true,
        'parcels': parcels,
      }));
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de la récupération: $e',
      }));
    }
  }

  Future<Response> _confirmPickup(Request request, String id) async {
    try {
      final driverId = _extractUserId(request);
      if (driverId.isEmpty) {
        return Response.forbidden(jsonEncode({
          'success': false,
          'message': 'Token manquant ou invalide',
        }));
      }
      final parcel = await _parcelService.confirmPickup(id, driverId);
      if (parcel == null) {
        return Response.notFound(jsonEncode({
          'success': false,
          'message': 'Colis non trouvé',
        }));
      }
      return Response.ok(jsonEncode({
        'success': true,
        'message': 'Ramassage confirmé avec succès',
        'parcel': parcel,
      }));
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de la confirmation: $e',
      }));
    }
  }

  Future<Response> _markAsInTransit(Request request, String id) async {
    try {
      final driverId = _extractUserId(request);
      if (driverId.isEmpty) {
        return Response.forbidden(jsonEncode({
          'success': false,
          'message': 'Token manquant ou invalide',
        }));
      }
      final body = await request.readAsString();
      final data = body.isEmpty ? {} : jsonDecode(body);
      final parcel = await _parcelService.markAsInTransit(id, driverId,
          location: data['location']);
      if (parcel == null) {
        return Response.notFound(jsonEncode({
          'success': false,
          'message': 'Colis non trouvé',
        }));
      }
      return Response.ok(jsonEncode({
        'success': true,
        'message': 'Colis marqué comme en transit',
        'parcel': parcel,
      }));
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({
        'success': false,
        'message': 'Erreur: $e',
      }));
    }
  }

  Future<Response> _markAsArrived(Request request, String id) async {
    try {
      final driverId = _extractUserId(request);
      if (driverId.isEmpty) {
        return Response.forbidden(jsonEncode({
          'success': false,
          'message': 'Token manquant ou invalide',
        }));
      }
      final body = await request.readAsString();
      final data = body.isEmpty ? {} : jsonDecode(body);
      final parcel = await _parcelService.markAsArrived(id, driverId,
          location: data['location']);
      if (parcel == null) {
        return Response.notFound(jsonEncode({
          'success': false,
          'message': 'Colis non trouvé',
        }));
      }
      return Response.ok(jsonEncode({
        'success': true,
        'message': 'Colis marqué comme arrivé',
        'parcel': parcel,
      }));
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({
        'success': false,
        'message': 'Erreur: $e',
      }));
    }
  }

  Future<Response> _updateStatusByDriver(Request request, String id) async {
    try {
      print('🚚🚚🚚 _updateStatusByDriver APPELEE 🚚🚚🚚');
      print('   id: $id');
      
      final driverId = _extractUserId(request);
      print('   driverId: $driverId');
      
      if (driverId.isEmpty) {
        return Response.forbidden(jsonEncode({
          'success': false,
          'message': 'Token manquant ou invalide',
        }));
      }

      final body = await request.readAsString();
      final data = jsonDecode(body);
      final newStatus = data['status'];
      final location = data['location'];

      print('📝 updateStatusByDriver: colis $id -> $newStatus');

      final parcel = await _parcelService.updateParcelStatus(
        id,
        newStatus,
        userId: driverId,
        location: location,
      );
      
      print('📦 Résultat updateParcelStatus: ${parcel != null ? "succès" : "échec"}');

      if (parcel == null) {
        return Response.notFound(jsonEncode({
          'success': false,
          'message': 'Colis non trouvé',
        }));
      }

      return Response.ok(jsonEncode({
        'success': true,
        'message': 'Statut mis à jour avec succès',
        'parcel': parcel,
      }));
    } catch (e) {
      print('❌ Erreur updateStatusByDriver: $e');
      print('StackTrace: ${StackTrace.current}');
      return Response.internalServerError(body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de la mise à jour: $e',
      }));
    }
  }

  Future<Response> _markAsOutForDelivery(Request request, String id) async {
    try {
      final driverId = _extractUserId(request);
      if (driverId.isEmpty) {
        return Response.forbidden(jsonEncode({
          'success': false,
          'message': 'Token manquant ou invalide',
        }));
      }
      final body = await request.readAsString();
      final data = body.isEmpty ? {} : jsonDecode(body);
      final parcel = await _parcelService.markAsOutForDelivery(id, driverId,
          location: data['location']);
      if (parcel == null) {
        return Response.notFound(jsonEncode({
          'success': false,
          'message': 'Colis non trouvé',
        }));
      }
      return Response.ok(jsonEncode({
        'success': true,
        'message': 'Colis marqué comme en livraison',
        'parcel': parcel,
      }));
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({
        'success': false,
        'message': 'Erreur: $e',
      }));
    }
  }

  Future<Response> _confirmDelivery(Request request, String id) async {
    try {
      final driverId = _extractUserId(request);
      if (driverId.isEmpty) {
        return Response.forbidden(jsonEncode({
          'success': false,
          'message': 'Token manquant ou invalide',
        }));
      }
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final parcel = await _parcelService.confirmDelivery(id, driverId, data);
      if (parcel == null) {
        return Response.notFound(jsonEncode({
          'success': false,
          'message': 'Colis non trouvé',
        }));
      }
      return Response.ok(jsonEncode({
        'success': true,
        'message': 'Livraison confirmée avec succès',
        'parcel': parcel,
      }));
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de la confirmation: $e',
      }));
    }
  }

  Future<Response> _getDriverStats(Request request) async {
    try {
      final driverId = _extractUserId(request);
      if (driverId.isEmpty) {
        return Response.forbidden(jsonEncode({
          'success': false,
          'message': 'Token manquant ou invalide',
        }));
      }
      final parcels = await _parcelService.getDriverParcels(driverId);
      final stats = {
        'total': parcels.length,
        'pending': parcels.where((p) => p['status'] == 'pending').length,
        'free': parcels.where((p) => p['status'] == 'free').length,
        'confirmed': parcels.where((p) => p['status'] == 'confirmed').length,
        'pickedUp': parcels.where((p) => p['status'] == 'picked_up').length,
        'inTransit': parcels.where((p) => p['status'] == 'in_transit').length,
        'arrived': parcels.where((p) => p['status'] == 'arrived').length,
        'outForDelivery':
            parcels.where((p) => p['status'] == 'out_for_delivery').length,
        'delivered': parcels.where((p) => p['status'] == 'delivered').length,
        'cancelled': parcels.where((p) => p['status'] == 'cancelled').length,
      };
      return Response.ok(jsonEncode({
        'success': true,
        'stats': stats,
      }));
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de la récupération: $e',
      }));
    }
  }

  Future<Response> _getDriverHistory(Request request) async {
    try {
      final driverId = _extractUserId(request);
      if (driverId.isEmpty) {
        return Response.forbidden(jsonEncode({
          'success': false,
          'message': 'Token manquant ou invalide',
        }));
      }
      final parcels = await _parcelService.getDriverParcels(driverId);
      return Response.ok(jsonEncode({
        'success': true,
        'history': parcels,
      }));
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de la récupération: $e',
      }));
    }
  }

  // ==================== 🆕 ROUTES LIBRE SERVICE (CHAUFFEUR) ====================

  Future<Response> _createBid(Request request) async {
    try {
      final driverId = _extractUserId(request);
      final driverName = _extractUserName(request);
      
      if (driverId.isEmpty) {
        return Response.forbidden(jsonEncode({
          'success': false,
          'message': 'Token manquant ou invalide',
        }));
      }

      final body = await request.readAsString();
      final data = jsonDecode(body);
      
      final parcelId = data['parcelId'];
      final price = (data['price'] as num).toDouble();
      final message = data['message']?.toString();

      if (parcelId == null) {
        return Response.badRequest(body: jsonEncode({
          'success': false,
          'message': 'parcelId et price sont requis',
        }));
      }

      final result = await _parcelService.createBid(
        parcelId,
        driverId,
        price,
        message: message,
      );

      if (!result['success']) {
        return Response.badRequest(body: jsonEncode(result));
      }

      return Response.ok(jsonEncode({
        'success': true,
        'message': 'Offre envoyée avec succès',
        'bidId': result['bidId'],
      }));
    } catch (e) {
      print('❌ Erreur createBid: $e');
      return Response.internalServerError(
          body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de l\'envoi de l\'offre: $e',
      }));
    }
  }

  Future<Response> _getDriverSentBids(Request request) async {
    try {
      final driverId = _extractUserId(request);
      if (driverId.isEmpty) {
        return Response.forbidden(jsonEncode({
          'success': false,
          'message': 'Token manquant ou invalide',
        }));
      }

      // Récupérer tous les colis où le chauffeur a fait une offre
      final db = await DatabaseService.getInstance();
      final result = await db.connection.execute('''
        SELECT b.*, p.tracking_number, p.sender_name, p.receiver_name,
               p.departure_garage_name, p.arrival_garage_name
        FROM bids b
        JOIN parcels p ON p.id = b.parcel_id
        WHERE b.driver_id = \$1
        ORDER BY b.created_at DESC
      ''', parameters: [driverId]);

      final bids = result.map((row) => {
        'id': row[0],
        'parcelId': row[1],
        'price': double.tryParse(row[5].toString()) ?? 0,
        'message': row[6],
        'status': row[7],
        'createdAt': (row[8] as DateTime).toIso8601String(),
        'respondedAt': row[9] != null ? (row[9] as DateTime).toIso8601String() : null,
        'responseMessage': row[10],
        'parcel': {
          'trackingNumber': row[11],
          'senderName': row[12],
          'receiverName': row[13],
          'departureGarageName': row[14],
          'arrivalGarageName': row[15],
        }
      }).toList();

      return Response.ok(jsonEncode({
        'success': true,
        'bids': bids,
      }));
    } catch (e) {
      print('❌ Erreur getDriverSentBids: $e');
      return Response.internalServerError(
          body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de la récupération: $e',
      }));
    }
  }

  // ==================== 🆕 ROUTES PUBLIQUES ====================

  Future<Response> _getFreeParcels(Request request) async {
    try {
      final parcels = await _parcelService.getFreeParcels();
      return Response.ok(jsonEncode({
        'success': true,
        'parcels': parcels,
      }));
    } catch (e) {
      print('❌ Erreur getFreeParcels: $e');
      return Response.internalServerError(
          body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de la récupération: $e',
      }));
    }
  }

  Future<Response> _getParcelBids(Request request, String id) async {
    try {
      final bids = await _parcelService.getParcelBids(id);
      return Response.ok(jsonEncode({
        'success': true,
        'bids': bids,
      }));
    } catch (e) {
      print('❌ Erreur getParcelBids: $e');
      return Response.internalServerError(
          body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de la récupération: $e',
      }));
    }
  }

  // ==================== ROUTES GARAGE ADMIN ====================

  Future<Response> _getGarageParcels(Request request) async {
    try {
      final userId = _extractUserId(request);
      final userRole = _extractUserRole(request);
      if (userId.isEmpty || userRole != 'garage') {
        return Response.forbidden(jsonEncode({
          'success': false,
          'message': 'Accès non autorisé',
        }));
      }
      final garageId = request.url.queryParameters['garageId'];
      if (garageId == null || garageId.isEmpty) {
        return Response.badRequest(
            body: jsonEncode({
          'success': false,
          'message': 'garageId requis',
        }));
      }
      final parcels = await _parcelService.getGarageParcels(garageId);
      return Response.ok(jsonEncode({
        'success': true,
        'parcels': parcels,
      }));
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de la récupération: $e',
      }));
    }
  }

  Future<Response> _getGarageParcelsByStatus(
      Request request, String status) async {
    try {
      final userId = _extractUserId(request);
      final userRole = _extractUserRole(request);
      if (userId.isEmpty || userRole != 'garage') {
        return Response.forbidden(jsonEncode({
          'success': false,
          'message': 'Accès non autorisé',
        }));
      }
      final garageId = request.url.queryParameters['garageId'];
      if (garageId == null || garageId.isEmpty) {
        return Response.badRequest(
            body: jsonEncode({
          'success': false,
          'message': 'garageId requis',
        }));
      }
      final parcels = await _parcelService.getGarageParcels(garageId);
      final filtered = parcels.where((p) => p['status'] == status).toList();
      return Response.ok(jsonEncode({
        'success': true,
        'parcels': filtered,
      }));
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de la récupération: $e',
      }));
    }
  }

  Future<Response> _assignDriverToParcel(Request request, String id) async {
    try {
      final adminId = _extractUserId(request);
      final adminName = _extractUserName(request);
      final body = await request.readAsString();
      final data = jsonDecode(body);

      final parcel = await _parcelService.assignDriverToParcel(
        id,
        data['driverId'],
        assignedBy: adminId,
        assignedByName: adminName,
      );
      if (parcel == null) {
        return Response.notFound(jsonEncode({
          'success': false,
          'message': 'Colis non trouvé',
        }));
      }
      return Response.ok(jsonEncode({
        'success': true,
        'message': 'Chauffeur assigné avec succès',
        'parcel': parcel,
      }));
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de l\'assignation: $e',
      }));
    }
  }

  Future<Response> _updateStatusByGarage(Request request, String id) async {
    try {
      final userId = _extractUserId(request);
      final userName = _extractUserName(request);
      final body = await request.readAsString();
      final data = jsonDecode(body);

      final parcel = await _parcelService.updateParcelStatus(
        id,
        data['status'],
        userId: userId,
        userName: userName,
        location: data['location'],
        description: data['description'],
      );
      if (parcel == null) {
        return Response.notFound(jsonEncode({
          'success': false,
          'message': 'Colis non trouvé',
        }));
      }
      return Response.ok(jsonEncode({
        'success': true,
        'message': 'Statut mis à jour avec succès',
        'parcel': parcel,
      }));
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de la mise à jour: $e',
      }));
    }
  }

  Future<Response> _getGarageStats(Request request) async {
    try {
      final userId = _extractUserId(request);
      final userRole = _extractUserRole(request);
      if (userId.isEmpty || userRole != 'garage') {
        return Response.forbidden(jsonEncode({
          'success': false,
          'message': 'Accès non autorisé',
        }));
      }
      final garageId = request.url.queryParameters['garageId'];
      if (garageId == null || garageId.isEmpty) {
        return Response.badRequest(
            body: jsonEncode({
          'success': false,
          'message': 'garageId requis',
        }));
      }
      final parcels = await _parcelService.getGarageParcels(garageId);
      final stats = {
        'total': parcels.length,
        'free': parcels.where((p) => p['status'] == 'free').length,
        'pending': parcels.where((p) => p['status'] == 'pending').length,
        'confirmed': parcels.where((p) => p['status'] == 'confirmed').length,
        'inTransit': parcels.where((p) => p['status'] == 'in_transit').length,
        'delivered': parcels.where((p) => p['status'] == 'delivered').length,
        'cancelled': parcels.where((p) => p['status'] == 'cancelled').length,
      };
      return Response.ok(jsonEncode({
        'success': true,
        'stats': stats,
      }));
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de la récupération: $e',
      }));
    }
  }

  Future<Response> _getGarageDrivers(Request request) async {
    try {
      final userId = _extractUserId(request);
      final userRole = _extractUserRole(request);
      if (userId.isEmpty || userRole != 'garage') {
        return Response.forbidden(jsonEncode({
          'success': false,
          'message': 'Accès non autorisé',
        }));
      }
      final garageId = request.url.queryParameters['garageId'];
      if (garageId == null || garageId.isEmpty) {
        return Response.badRequest(
            body: jsonEncode({
          'success': false,
          'message': 'garageId requis',
        }));
      }
      final db = await DatabaseService.getInstance();
      final result = await db.connection.execute(
        'SELECT id, full_name, phone, email, driver_status FROM users WHERE garage_id = \$1 AND role = \'driver\'',
        parameters: [garageId],
      );
      final drivers = result
          .map((row) => ({
                'id': row[0],
                'fullName': row[1],
                'phone': row[2],
                'email': row[3],
                'status': row[4],
              }))
          .toList();
      return Response.ok(jsonEncode({
        'success': true,
        'drivers': drivers,
      }));
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de la récupération: $e',
      }));
    }
  }

  // ==================== ROUTES SUPER ADMIN ====================

  Future<Response> _getAllParcels(Request request) async {
    try {
      final parcels = await _parcelService.getAllParcels();
      return Response.ok(jsonEncode({
        'success': true,
        'parcels': parcels,
        'total': parcels.length,
      }));
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de la récupération: $e',
      }));
    }
  }

  Future<Response> _getParcelsByStatus(Request request, String status) async {
    try {
      final allParcels = await _parcelService.getAllParcels();
      final filtered = allParcels.where((p) => p['status'] == status).toList();
      return Response.ok(jsonEncode({
        'success': true,
        'parcels': filtered,
        'total': filtered.length,
      }));
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de la récupération: $e',
      }));
    }
  }

  Future<Response> _searchParcels(Request request) async {
    try {
      final query = request.url.queryParameters['q'] ?? '';
      final allParcels = await _parcelService.getAllParcels();
      final filtered = allParcels
          .where((p) =>
              p['trackingNumber']
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              p['senderName']
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              p['receiverName']
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase()))
          .toList();
      return Response.ok(jsonEncode({
        'success': true,
        'parcels': filtered,
      }));
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de la recherche: $e',
      }));
    }
  }

  Future<Response> _updateParcel(Request request, String id) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      await _parcelService.updateParcelInfo(id, data);
      final parcel = await _parcelService.getParcelById(id);
      return Response.ok(jsonEncode({
        'success': true,
        'message': 'Colis mis à jour avec succès',
        'parcel': parcel,
      }));
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de la mise à jour: $e',
      }));
    }
  }

  Future<Response> _cancelParcelWithReason(Request request, String id) async {
    try {
      final userId = _extractUserId(request);
      final userName = _extractUserName(request);
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final parcel = await _parcelService.cancelParcel(
        id,
        userId,
        reason: data['reason'],
        userName: userName,
      );
      if (parcel == null) {
        return Response.notFound(jsonEncode({
          'success': false,
          'message': 'Colis non trouvé',
        }));
      }
      return Response.ok(jsonEncode({
        'success': true,
        'message': 'Colis annulé avec succès',
        'parcel': parcel,
      }));
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de l\'annulation: $e',
      }));
    }
  }

  Future<Response> _deleteParcel(Request request, String id) async {
    try {
      final userId = _extractUserId(request);
      final userName = _extractUserName(request);
      final success = await _parcelService.deleteParcel(
        id,
        deletedBy: userId,
        deletedByName: userName,
      );
      if (!success) {
        return Response.notFound(jsonEncode({
          'success': false,
          'message': 'Colis non trouvé',
        }));
      }
      return Response.ok(jsonEncode({
        'success': true,
        'message': 'Colis supprimé avec succès',
      }));
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de la suppression: $e',
      }));
    }
  }

  Future<Response> _getGlobalStats(Request request) async {
    try {
      final parcels = await _parcelService.getAllParcels();
      final stats = {
        'total': parcels.length,
        'free': parcels.where((p) => p['status'] == 'free').length,
        'pending': parcels.where((p) => p['status'] == 'pending').length,
        'confirmed': parcels.where((p) => p['status'] == 'confirmed').length,
        'inTransit': parcels.where((p) => p['status'] == 'in_transit').length,
        'delivered': parcels.where((p) => p['status'] == 'delivered').length,
        'cancelled': parcels.where((p) => p['status'] == 'cancelled').length,
        'totalRevenue': parcels
            .where((p) => p['status'] == 'delivered')
            .fold<double>(0, (sum, p) {
          final price = p['price'];
          if (price is double) return sum + price;
          if (price is int) return sum + price.toDouble();
          if (price is num) return sum + price.toDouble();
          return sum;
        }),
      };
      return Response.ok(jsonEncode({
        'success': true,
        'stats': stats,
      }));
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de la récupération: $e',
      }));
    }
  }

  Future<Response> _getDailyReport(Request request) async {
    try {
      final date = request.url.queryParameters['date'];
      final parcels = await _parcelService.getAllParcels();
      final filtered = parcels
          .where((p) => p['createdAt'].toString().startsWith(
              date ?? DateTime.now().toIso8601String().substring(0, 10)))
          .toList();

      return Response.ok(jsonEncode({
        'success': true,
        'report': {
          'date': date ?? DateTime.now().toIso8601String().substring(0, 10),
          'totalParcels': filtered.length,
          'free': filtered.where((p) => p['status'] == 'free').length,
          'delivered': filtered.where((p) => p['status'] == 'delivered').length,
          'cancelled': filtered.where((p) => p['status'] == 'cancelled').length,
          'revenue': filtered
              .where((p) => p['status'] == 'delivered')
              .fold<double>(0, (sum, p) {
            final price = p['price'];
            if (price is double) return sum + price;
            if (price is int) return sum + price.toDouble();
            if (price is num) return sum + price.toDouble();
            return sum;
          }),
          'parcels': filtered,
        },
      }));
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de la génération: $e',
      }));
    }
  }

  Future<Response> _getMonthlyReport(Request request) async {
    try {
      final year = int.parse(request.url.queryParameters['year'] ??
          DateTime.now().year.toString());
      final month = int.parse(request.url.queryParameters['month'] ??
          DateTime.now().month.toString());
      final parcels = await _parcelService.getAllParcels();
      final filtered = parcels.where((p) {
        final date = DateTime.tryParse(p['createdAt'].toString());
        return date != null && date.year == year && date.month == month;
      }).toList();

      return Response.ok(jsonEncode({
        'success': true,
        'report': {
          'year': year,
          'month': month,
          'totalParcels': filtered.length,
          'free': filtered.where((p) => p['status'] == 'free').length,
          'delivered': filtered.where((p) => p['status'] == 'delivered').length,
          'cancelled': filtered.where((p) => p['status'] == 'cancelled').length,
          'revenue': filtered
              .where((p) => p['status'] == 'delivered')
              .fold<double>(0, (sum, p) {
            final price = p['price'];
            if (price is double) return sum + price;
            if (price is int) return sum + price.toDouble();
            if (price is num) return sum + price.toDouble();
            return sum;
          }),
          'parcels': filtered,
        },
      }));
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de la génération: $e',
      }));
    }
  }
}