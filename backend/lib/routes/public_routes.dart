// lib/routes/public_routes.dart
import 'dart:convert';

import 'package:procolis_backend/services/database_service.dart';
import 'package:procolis_backend/services/email_service.dart';
import 'package:procolis_backend/services/parcel_service.dart';
import 'package:procolis_backend/services/user_service.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../services/driver_service.dart';

class PublicRoutes {
  final DriverService _driverService = DriverService();
  late ParcelService _parcelService;
  late final UserService _userService = UserService();

  PublicRoutes({required EmailService emailService}) {
    _parcelService = ParcelService(emailService: emailService);
  }

  Router get router {
    final router = Router();

    // Health check
    router.get('/health', (Request request) async {
      return Response.ok(jsonEncode({
        'status': 'ok',
        'timestamp': DateTime.now().toIso8601String(),
      }));
    });

    // Liste des garages (publique)
    router.get('/garages', (Request request) async {
      final db = await DatabaseService.getInstance();
      try {
        final result = await db.connection.execute(
            'SELECT id, name, city, region, address, phone FROM garages ORDER BY name');

        final garages = result
            .map((row) => ({
                  'id': row[0],
                  'name': row[1],
                  'city': row[2],
                  'region': row[3],
                  'address': row[4],
                  'phone': row[5],
                }))
            .toList();

        return Response.ok(jsonEncode({'success': true, 'garages': garages}));
      } catch (e) {
        return Response.internalServerError(
            body: jsonEncode({'success': false, 'message': e.toString()}));
      }
    });

    // ==================== 🆕 ROUTES LIBRE SERVICE (PUBLIQUES) ====================

    // Récupérer tous les colis en libre service
    router.get('/parcels/free', (Request request) async {
      try {
        final parcels = await _parcelService.getFreeParcels();

        // Charge les offres pour chaque colis
        final parcelsWithBids = [];
        for (var parcel in parcels) {
          final bids = await _parcelService.getParcelBids(parcel['id']);
          parcelsWithBids.add({
            ...parcel,
            'bids': bids,
          });
        }

        return Response.ok(jsonEncode({
          'success': true,
          'parcels': parcelsWithBids,
        }));
      } catch (e) {
        return Response.internalServerError(
            body: jsonEncode({'success': false, 'message': e.toString()}));
      }
    });

    // Récupérer les offres d'un colis (publique)
    router.get('/parcels/<parcelId>/bids',
        (Request request, String parcelId) async {
      print('📍 Route /parcels/$parcelId/bids appelée');
      try {
        final bids = await _parcelService.getParcelBids(parcelId);
        
        // ✅ AJOUT: Log pour vérifier les audioUrl
        for (var bid in bids) {
          if (bid['audioUrl'] != null && bid['audioUrl'].toString().isNotEmpty) {
            print('🎤 Offre ${bid['id']} contient un audio: ${bid['audioUrl']}');
          }
        }
        
        print('📍 ${bids.length} offres trouvées pour le colis $parcelId');
        return Response.ok(jsonEncode({
          'success': true,
          'bids': bids,
        }));
      } catch (e) {
        print('❌ Erreur route /parcels/$parcelId/bids: $e');
        return Response.internalServerError(
            body: jsonEncode({
          'success': false,
          'message': 'Erreur lors de la récupération: $e',
        }));
      }
    });

    // Suivre un colis par numéro de tracking (publique)
    router.get('/parcels/track/<trackingNumber>',
        (Request request, String trackingNumber) async {
      print('📍 Route /parcels/track/$trackingNumber appelée');
      try {
        final parcel =
            await _parcelService.getParcelByTrackingNumber(trackingNumber);
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
        print('❌ Erreur route /parcels/track/$trackingNumber: $e');
        return Response.internalServerError(
            body: jsonEncode({
          'success': false,
          'message': 'Erreur lors du suivi: $e',
        }));
      }
    });

    // Récupérer les événements d'un colis (publique)
    router.get('/parcels/<parcelId>/events',
        (Request request, String parcelId) async {
      print('📍 Route /parcels/$parcelId/events appelée');
      try {
        final events = await _parcelService.getParcelEvents(parcelId);
        return Response.ok(jsonEncode({'success': true, 'events': events}));
      } catch (e) {
        print('❌ Erreur route /parcels/$parcelId/events: $e');
        return Response.internalServerError(
            body: jsonEncode({'success': false, 'message': e.toString()}));
      }
    });

    // Récupérer les détails d'un colis par ID (publique)
    router.get('/parcels/<parcelId>', (Request request, String parcelId) async {
      print('📍 Route /parcels/$parcelId appelée');
      try {
        final parcel = await _parcelService.getParcelById(parcelId);
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
        print('❌ Erreur route /parcels/$parcelId: $e');
        return Response.internalServerError(
            body: jsonEncode({
          'success': false,
          'message': 'Erreur lors de la récupération: $e',
        }));
      }
    });

    // ==================== ROUTES CHAUFFEURS (PUBLIQUES) ====================

    // Recherche de chauffeurs (publique)
    router.get('/drivers/search', (Request request) async {
      final query = request.url.queryParameters['query'];
      final limit =
          int.tryParse(request.url.queryParameters['limit'] ?? '20') ?? 20;

      try {
        final drivers =
            await _driverService.searchDrivers(query: query, limit: limit);
        return Response.ok(jsonEncode(
            {'success': true, 'drivers': drivers, 'count': drivers.length}));
      } catch (e) {
        return Response.internalServerError(
            body: jsonEncode({'success': false, 'message': e.toString()}));
      }
    });

    // Récupérer un chauffeur par ID (publique)
    router.get('/drivers/<driverId>', (Request request, String driverId) async {
      try {
        final driver = await _driverService.getDriverById(driverId);
        if (driver == null) {
          return Response.notFound(jsonEncode(
              {'success': false, 'message': 'Chauffeur non trouvé'}));
        }
        return Response.ok(jsonEncode({'success': true, 'driver': driver}));
      } catch (e) {
        return Response.internalServerError(
            body: jsonEncode({'success': false, 'message': e.toString()}));
      }
    });

    // Récupérer les chauffeurs par garage (publique)
    router.get('/drivers/garage/<garageId>',
        (Request request, String garageId) async {
      try {
        final drivers = await _driverService.getDriversByGarage(garageId);
        return Response.ok(jsonEncode(
            {'success': true, 'drivers': drivers, 'count': drivers.length}));
      } catch (e) {
        return Response.internalServerError(
            body: jsonEncode({'success': false, 'message': e.toString()}));
      }
    });

    router.get('/clients', (Request request) async {
      try {
        final users = await _userService.getAllClients();
        return Response.ok(jsonEncode({'success': true, 'users': users}));
      } catch (e) {
        return Response.internalServerError(
            body: jsonEncode({'success': false, 'message': e.toString()}));
      }
    });

    return router;
  }
}