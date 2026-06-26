// lib/routes/track_routes.dart
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../controllers/track_controller.dart';

class TrackRoutes {
  static Handler get handler {
    final router = Router();

    // Route publique pour afficher la page de tracking HTML
    router.get('/track/<trackingNumber>', (Request request, String trackingNumber) {
      return TrackController.renderTrackPage(trackingNumber);
    });

    // Route API pour le tracking JSON
    router.get('/api/track/<trackingNumber>', (Request request, String trackingNumber) {
      return TrackController.apiTrack(trackingNumber);
    });

    // Route racine du tracking (redirige vers l'accueil)
    router.get('/track', (Request request) {
      return Response.seeOther('/');
    });

    return router;
  }
}