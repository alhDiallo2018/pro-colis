// backend/lib/services/map_service.dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

class MapService {
  final _log = Logger('MapService');
  final String? googleMapsApiKey;
  final String? openRouteServiceKey;

  MapService({this.googleMapsApiKey, this.openRouteServiceKey});

  /// Calcul de la distance et durée entre deux points
  Future<Map<String, dynamic>> calculateDistance({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/distancematrix/json'
        '?origins=$originLat,$originLng'
        '&destinations=$destLat,$destLng'
        '&key=$googleMapsApiKey'
        '&language=fr'
        '&units=metric',
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['rows'][0]['elements'][0]['status'] == 'OK') {
          return {
            'distance': data['rows'][0]['elements'][0]['distance']['value'] / 1000, // km
            'distanceText': data['rows'][0]['elements'][0]['distance']['text'],
            'duration': data['rows'][0]['elements'][0]['duration']['value'] / 60, // minutes
            'durationText': data['rows'][0]['elements'][0]['duration']['text'],
          };
        }
      }
      
      return {'distance': 0, 'duration': 0};
    } catch (e) {
      _log.severe('Distance calculation error: $e');
      return {'distance': 0, 'duration': 0};
    }
  }

  /// Géocodage inversé (coordonnées -> adresse)
  Future<Map<String, String>> reverseGeocode(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=$lat,$lng'
        '&key=$googleMapsApiKey'
        '&language=fr',
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['results'].isNotEmpty) {
          final address = data['results'][0]['formatted_address'];
          return {'address': address};
        }
      }
      
      return {'address': 'Adresse non trouvée'};
    } catch (e) {
      return {'address': 'Erreur de géocodage'};
    }
  }

  /// Suggestions d'adresses
  Future<List<Map<String, dynamic>>> autocompleteAddress(String input) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=$input'
        '&types=geocode'
        '&key=$googleMapsApiKey'
        '&language=fr'
        '&components=country:sn',
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final predictions = data['predictions'] as List;
        
        return predictions.map((p) => {
          'description': p['description'],
          'placeId': p['place_id'],
        }).toList();
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Récupérer les détails d'un lieu
  Future<Map<String, dynamic>> getPlaceDetails(String placeId) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId'
        '&key=$googleMapsApiKey'
        '&fields=geometry,formatted_address,name',
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = data['result'];
        
        return {
          'latitude': result['geometry']['location']['lat'],
          'longitude': result['geometry']['location']['lng'],
          'address': result['formatted_address'],
          'name': result['name'],
        };
      }
      
      return {};
    } catch (e) {
      return {};
    }
  }

  /// Itinéraire optimisé
  Future<Map<String, dynamic>> getDirections({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    List<Map<String, double>>? waypoints,
  }) async {
    try {
      var waypointsStr = '';
      if (waypoints != null && waypoints.isNotEmpty) {
        waypointsStr = '&waypoints=optimize:true${waypoints.map((w) 
          => '|${w['lat']},${w['lng']}').join()}';
      }
      
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=$originLat,$originLng'
        '&destination=$destLat,$destLng'
        '$waypointsStr'
        '&key=$googleMapsApiKey'
        '&language=fr'
        '&mode=driving',
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          
          return {
            'distance': leg['distance']['text'],
            'duration': leg['duration']['text'],
            'polyline': route['overview_polyline']['points'],
            'steps': leg['steps'].map((step) => {
              'instruction': step['html_instructions'],
              'distance': step['distance']['text'],
              'duration': step['duration']['text'],
              'startLocation': step['start_location'],
              'endLocation': step['end_location'],
            }).toList(),
          };
        }
      }
      
      return {};
    } catch (e) {
      return {};
    }
  }

  /// Estimer le prix du transport
  double estimatePrice(double distanceKm) {
    // Tarif de base: 500 FCFA + 100 FCFA/km
    const basePrice = 500;
    const pricePerKm = 100;
    
    return basePrice + (distanceKm * pricePerKm);
  }
}