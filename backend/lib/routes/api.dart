import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../controllers/auth_controller.dart';
import '../controllers/parcel_controller.dart';
import '../controllers/admin_controller.dart';
import '../services/user_service.dart';
import '../services/otp_service.dart';
import '../services/parcel_service.dart';
import '../services/notification_service.dart';
import '../services/admin_service.dart';
import '../services/garage_service.dart';

class ApiRouter {
  static Router get router {
    final router = Router();
    
    // Services
    final userService = UserService();
    final otpService = OtpService();
    final parcelService = ParcelService();
    final notificationService = NotificationService();
    final garageService = GarageService();
    final adminService = AdminService();
    
    // Controllers
    final authController = AuthController(
      userService: userService,
      otpService: otpService,
    );
    
    final parcelController = ParcelController(
      parcelService: parcelService,
      notificationService: notificationService,
    );
    
    final adminController = AdminController(
      adminService: adminService,
      userService: userService,
      garageService: garageService,
    );
    
    // Routes d'authentification
    router.mount('/auth', authController.router);
    router.mount('/parcels', parcelController.router);
    router.mount('/admin', adminController.router);
    
    // Routes de base
    router.get('/health', (Request req) {
      return Response.ok('{"status": "ok", "timestamp": "${DateTime.now()}"}');
    });
    
    router.get('/', (Request req) {
      return Response.ok('{"message": "PRO COLIS API is running", "version": "1.0.0"}');
    });
    
    return router;
  }
}
