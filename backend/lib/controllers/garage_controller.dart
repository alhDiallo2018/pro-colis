import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

class GarageController {
  final _uuid = const Uuid();
  final List<Map<String, dynamic>> _garages = [];

  GarageController() {
    // Ajouter quelques garages par défaut
    _garages.addAll([
      {
        'id': _uuid.v4(),
        'name': 'Garage Dakar Centre',
        'city': 'Dakar',
        'region': 'Dakar',
        'address': '123 Avenue Cheikh Anta Diop',
        'phone': '+221 33 123 45 67',
        'latitude': 14.6937,
        'longitude': -17.4441,
        'activeDrivers': 12,
        'parcelsToday': 45,
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'id': _uuid.v4(),
        'name': 'Garage Thiès',
        'city': 'Thiès',
        'region': 'Thiès',
        'address': 'Route Nationale 1',
        'phone': '+221 33 987 65 43',
        'latitude': 14.7915,
        'longitude': -16.9359,
        'activeDrivers': 8,
        'parcelsToday': 28,
        'createdAt': DateTime.now().toIso8601String(),
      },
      {
        'id': _uuid.v4(),
        'name': 'Garage Saint-Louis',
        'city': 'Saint-Louis',
        'region': 'Saint-Louis',
        'address': 'Boulevard de la Libération',
        'phone': '+221 33 456 78 90',
        'latitude': 16.0167,
        'longitude': -16.5,
        'activeDrivers': 5,
        'parcelsToday': 15,
        'createdAt': DateTime.now().toIso8601String(),
      },
    ]);
  }

  Router get router {
    final router = Router();
    
    router.get('/', _getAllGarages);
    router.get('/<id>', _getGarage);
    router.post('/', _createGarage);
    router.put('/<id>', _updateGarage);
    router.delete('/<id>', _deleteGarage);
    router.get('/<id>/drivers', _getGarageDrivers);
    
    return router;
  }

  Future<Response> _getAllGarages(Request request) async {
    return Response.ok(jsonEncode({
      'success': true,
      'garages': _garages,
    }));
  }

  Future<Response> _getGarage(Request request, String id) async {
    final garage = _garages.firstWhere(
      (g) => g['id'] == id,
      orElse: () => {},
    );
    
    if (garage.isEmpty) {
      return Response.notFound(jsonEncode({
        'success': false,
        'message': 'Garage non trouvé',
      }));
    }
    
    return Response.ok(jsonEncode({
      'success': true,
      'garage': garage,
    }));
  }

  Future<Response> _createGarage(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      
      final garage = {
        'id': _uuid.v4(),
        'name': data['name'],
        'city': data['city'],
        'region': data['region'],
        'address': data['address'],
        'phone': data['phone'],
        'latitude': data['latitude'],
        'longitude': data['longitude'],
        'activeDrivers': 0,
        'parcelsToday': 0,
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      _garages.add(garage);
      
      return Response.ok(jsonEncode({
        'success': true,
        'garage': garage,
      }));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de la création: $e',
      }));
    }
  }

  Future<Response> _updateGarage(Request request, String id) async {
    try {
      final index = _garages.indexWhere((g) => g['id'] == id);
      if (index == -1) {
        return Response.notFound(jsonEncode({
          'success': false,
          'message': 'Garage non trouvé',
        }));
      }
      
      final body = await request.readAsString();
      final data = jsonDecode(body);
      
      _garages[index] = {
        ..._garages[index],
        ...data,
        'id': id,
      };
      
      return Response.ok(jsonEncode({
        'success': true,
        'garage': _garages[index],
      }));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de la mise à jour: $e',
      }));
    }
  }

  Future<Response> _deleteGarage(Request request, String id) async {
    final index = _garages.indexWhere((g) => g['id'] == id);
    if (index == -1) {
      return Response.notFound(jsonEncode({
        'success': false,
        'message': 'Garage non trouvé',
      }));
    }
    
    _garages.removeAt(index);
    
    return Response.ok(jsonEncode({
      'success': true,
      'message': 'Garage supprimé',
    }));
  }

  Future<Response> _getGarageDrivers(Request request, String id) async {
    // Simuler une liste de chauffeurs
    final drivers = [
      {
        'id': _uuid.v4(),
        'name': 'Amadou Diop',
        'phone': '+221 77 123 45 67',
        'vehiclePlate': 'DK-123-AB',
        'status': 'active',
      },
      {
        'id': _uuid.v4(),
        'name': 'Moussa Sow',
        'phone': '+221 78 234 56 78',
        'vehiclePlate': 'DK-456-CD',
        'status': 'active',
      },
    ];
    
    return Response.ok(jsonEncode({
      'success': true,
      'drivers': drivers,
    }));
  }
}
