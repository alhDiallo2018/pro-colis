import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';
import '../services/parcel_service.dart';
import '../services/notification_service.dart';

class ParcelController {
  final ParcelService _parcelService;
  final NotificationService _notificationService;
  final _uuid = const Uuid();

  ParcelController({
    required ParcelService parcelService,
    required NotificationService notificationService,
  }) : _parcelService = parcelService,
       _notificationService = notificationService;

  Router get router {
    final router = Router();
    
    router.post('/create', _createParcel);
    router.get('/my-parcels', _getMyParcels);
    router.get('/track/<tracking>', _trackParcel);
    router.put('/<id>/status', _updateStatus);
    router.post('/<id>/photos', _uploadPhotos);
    router.get('/<id>/events', _getEvents);
    router.post('/<id>/notify-receiver', _notifyReceiver);
    
    return router;
  }

  String _generateTrackingNumber() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final random = _uuid.v4().substring(0, 6).toUpperCase();
    return 'PC-$year$month$day-$random';
  }

  Future<Response> _createParcel(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      
      final trackingNumber = _generateTrackingNumber();
      
      final parcel = await _parcelService.createParcel(
        trackingNumber: trackingNumber,
        senderId: data['senderId'] ?? 'unknown',
        receiverName: data['receiverName'],
        receiverPhone: data['receiverPhone'],
        receiverEmail: data['receiverEmail'],
        description: data['description'],
        weight: (data['weight'] as num).toDouble(),
        type: data['type'],
        departureGarageId: data['departureGarageId'],
        arrivalGarageId: data['arrivalGarageId'],
        price: (data['price'] as num?)?.toDouble(),
      );
      
      await _notificationService.notifyParcelCreated(parcel.toJson());
      
      return Response.ok(jsonEncode({
        'success': true,
        'message': 'Colis créé avec succès',
        'parcel': parcel.toJson(),
      }));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de la création: $e'
      }));
    }
  }

  Future<Response> _trackParcel(Request request, String tracking) async {
    try {
      final parcel = await _parcelService.findByTrackingNumber(tracking);
      
      if (parcel == null) {
        return Response.notFound(jsonEncode({
          'success': false,
          'message': 'Colis non trouvé'
        }));
      }
      
      final events = await _parcelService.getEvents(parcel.id);
      
      return Response.ok(jsonEncode({
        'success': true,
        'parcel': parcel.toJson(),
        'events': events.map((e) => e.toJson()).toList(),
      }));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({
        'success': false,
        'message': 'Erreur lors du suivi: $e'
      }));
    }
  }

  Future<Response> _updateStatus(Request request, String id) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      
      final status = data['status'];
      final location = data['location'];
      final metadata = data['metadata'];
      
      final parcel = await _parcelService.updateStatus(
        id,
        status,
        data['userId'] ?? 'system',
        data['userRole'] ?? 'admin',
        location: location,
        metadata: metadata,
      );
      
      if (parcel == null) {
        return Response.notFound(jsonEncode({
          'success': false,
          'message': 'Colis non trouvé'
        }));
      }
      
      await _notificationService.notifyStatusUpdate(parcel.toJson());
      
      return Response.ok(jsonEncode({
        'success': true,
        'parcel': parcel.toJson(),
      }));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de la mise à jour: $e'
      }));
    }
  }

  Future<Response> _getMyParcels(Request request) async {
    try {
      final userId = request.url.queryParameters['userId'] ?? '';
      final status = request.url.queryParameters['status'];
      
      final parcels = await _parcelService.getUserParcels(userId, status: status);
      
      return Response.ok(jsonEncode({
        'success': true,
        'parcels': parcels.map((p) => p.toJson()).toList(),
      }));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de la récupération: $e'
      }));
    }
  }

  Future<Response> _uploadPhotos(Request request, String id) async {
    // Implémentation simplifiée
    return Response.ok(jsonEncode({
      'success': true,
      'message': 'Photos téléchargées',
    }));
  }

  Future<Response> _getEvents(Request request, String id) async {
    try {
      final events = await _parcelService.getEvents(id);
      
      return Response.ok(jsonEncode({
        'success': true,
        'events': events.map((e) => e.toJson()).toList(),
      }));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de la récupération des événements: $e'
      }));
    }
  }

  Future<Response> _notifyReceiver(Request request, String id) async {
    try {
      final parcel = await _parcelService.getParcel(id);
      if (parcel != null) {
        await _notificationService.notifyReceiver(parcel.toJson());
      }
      
      return Response.ok(jsonEncode({
        'success': true,
        'message': 'Notification envoyée',
      }));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de l\'envoi: $e'
      }));
    }
  }
}
