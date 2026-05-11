import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

class ParcelController {
  final _uuid = const Uuid();
  final List<Map<String, dynamic>> _parcels = [];
  
  // Stockage temporaire des utilisateurs (à lier avec auth)
  final Map<String, Map<String, dynamic>> _users;

  ParcelController({required Map<String, Map<String, dynamic>> users}) : _users = users;

  Router get router {
    final router = Router();
    
    router.post('/create', _createParcel);
    router.get('/my-parcels', _getMyParcels);
    router.get('/track/<tracking>', _trackParcel);
    router.get('/<id>', _getParcel);
    router.put('/<id>/status', _updateStatus);
    router.get('/<id>/events', _getEvents);
    
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
      
      // Récupérer l'utilisateur depuis le token (simplifié)
      final senderId = data['senderId'] ?? 'unknown';
      final sender = _users[senderId];
      
      final trackingNumber = _generateTrackingNumber();
      
      final parcel = {
        'id': _uuid.v4(),
        'trackingNumber': trackingNumber,
        'senderId': senderId,
        'senderName': sender?['fullName'] ?? 'Expéditeur',
        'receiverName': data['receiverName'],
        'receiverPhone': data['receiverPhone'],
        'receiverEmail': data['receiverEmail'],
        'description': data['description'],
        'weight': data['weight'],
        'type': data['type'] ?? 'package',
        'status': 'pending',
        'departureGarageId': data['departureGarageId'],
        'departureGarageName': data['departureGarageName'] ?? 'Garage Départ',
        'arrivalGarageId': data['arrivalGarageId'],
        'arrivalGarageName': data['arrivalGarageName'] ?? 'Garage Arrivée',
        'price': data['price'],
        'paymentStatus': 'pending',
        'photoUrls': data['photoUrls'] ?? [],
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      _parcels.add(parcel);
      
      return Response.ok(jsonEncode({
        'success': true,
        'message': 'Colis créé avec succès',
        'parcel': parcel,
      }));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de la création: $e',
      }));
    }
  }

  Future<Response> _getMyParcels(Request request) async {
    try {
      final userId = request.url.queryParameters['userId'] ?? '';
      final userParcels = _parcels.where((p) => p['senderId'] == userId).toList();
      
      return Response.ok(jsonEncode({
        'success': true,
        'parcels': userParcels,
      }));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de la récupération: $e',
      }));
    }
  }

  Future<Response> _trackParcel(Request request, String tracking) async {
    try {
      final parcel = _parcels.firstWhere(
        (p) => p['trackingNumber'] == tracking,
        orElse: () => {},
      );
      
      if (parcel.isEmpty) {
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
      return Response.internalServerError(body: jsonEncode({
        'success': false,
        'message': 'Erreur lors du suivi: $e',
      }));
    }
  }

  Future<Response> _getParcel(Request request, String id) async {
    try {
      final parcel = _parcels.firstWhere(
        (p) => p['id'] == id,
        orElse: () => {},
      );
      
      if (parcel.isEmpty) {
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
      return Response.internalServerError(body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de la récupération: $e',
      }));
    }
  }

  Future<Response> _updateStatus(Request request, String id) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      
      final index = _parcels.indexWhere((p) => p['id'] == id);
      if (index == -1) {
        return Response.notFound(jsonEncode({
          'success': false,
          'message': 'Colis non trouvé',
        }));
      }
      
      _parcels[index]['status'] = data['status'];
      if (data['status'] == 'delivered') {
        _parcels[index]['deliveredAt'] = DateTime.now().toIso8601String();
      }
      
      return Response.ok(jsonEncode({
        'success': true,
        'parcel': _parcels[index],
      }));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de la mise à jour: $e',
      }));
    }
  }

  Future<Response> _getEvents(Request request, String id) async {
    try {
      // Simuler des événements
      final events = [
        {
          'id': _uuid.v4(),
          'parcelId': id,
          'status': 'pending',
          'description': 'Colis créé',
          'timestamp': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        },
        {
          'id': _uuid.v4(),
          'parcelId': id,
          'status': 'pickedUp',
          'description': 'Colis ramassé',
          'location': 'Garage Départ',
          'timestamp': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        },
      ];
      
      return Response.ok(jsonEncode({
        'success': true,
        'events': events,
      }));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de la récupération des événements: $e',
      }));
    }
  }
}
