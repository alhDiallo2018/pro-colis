import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/admin_service.dart';
import '../services/user_service.dart';
import '../services/garage_service.dart';

class AdminController {
  final AdminService _adminService;
  final UserService _userService;
  final GarageService _garageService;

  AdminController({
    required AdminService adminService,
    required UserService userService,
    required GarageService garageService,
  }) : _adminService = adminService,
       _userService = userService,
       _garageService = garageService;

  Router get router {
    final router = Router();
    
    router.get('/stats/overview', _getOverviewStats);
    router.get('/stats/revenue', _getRevenueStats);
    router.get('/users', _getAllUsers);
    router.get('/users/<id>', _getUserById);
    router.put('/users/<id>/role', _updateUserRole);
    router.delete('/users/<id>', _deleteUser);
    router.get('/garages', _getAllGarages);
    router.post('/garages', _createGarage);
    router.put('/garages/<id>', _updateGarage);
    router.delete('/garages/<id>', _deleteGarage);
    router.post('/garages/<id>/assign-admin', _assignGarageAdmin);
    
    return router;
  }

  Future<Response> _getOverviewStats(Request request) async {
    final stats = await _adminService.getOverviewStats();
    return Response.ok(jsonEncode({'success': true, 'stats': stats.toJson()}));
  }

  Future<Response> _getRevenueStats(Request request) async {
    final period = request.url.queryParameters['period'] ?? 'month';
    final stats = await _adminService.getRevenueStats(period);
    return Response.ok(jsonEncode({'success': true, 'stats': stats}));
  }

  Future<Response> _getAllUsers(Request request) async {
    final page = int.tryParse(request.url.queryParameters['page'] ?? '1') ?? 1;
    final limit = int.tryParse(request.url.queryParameters['limit'] ?? '20') ?? 20;
    final role = request.url.queryParameters['role'];
    final status = request.url.queryParameters['status'];
    final search = request.url.queryParameters['search'];
    
    final result = await _userService.getAllUsers(
      page: page,
      limit: limit,
      role: role,
      status: status,
      search: search,
    );
    
    return Response.ok(jsonEncode({'success': true, ...result}));
  }

  Future<Response> _getUserById(Request request, String id) async {
    final user = await _userService.getUser(id);
    if (user == null) {
      return Response.notFound(jsonEncode({'success': false, 'message': 'Utilisateur non trouvé'}));
    }
    return Response.ok(jsonEncode({'success': true, 'user': user.toJson()}));
  }

  Future<Response> _updateUserRole(Request request, String id) async {
    final body = await request.readAsString();
    final data = jsonDecode(body);
    final newRole = data['role'];
    
    final user = await _userService.updateUserRole(id, newRole);
    if (user == null) {
      return Response.notFound(jsonEncode({'success': false, 'message': 'Utilisateur non trouvé'}));
    }
    
    return Response.ok(jsonEncode({'success': true, 'user': user.toJson()}));
  }

  Future<Response> _deleteUser(Request request, String id) async {
    final deleted = await _userService.deleteUser(id);
    if (!deleted) {
      return Response.notFound(jsonEncode({'success': false, 'message': 'Utilisateur non trouvé'}));
    }
    return Response.ok(jsonEncode({'success': true}));
  }

  Future<Response> _getAllGarages(Request request) async {
    final garages = await _garageService.getAllGarages();
    return Response.ok(jsonEncode({'success': true, 'garages': garages.map((g) => g.toJson()).toList()}));
  }

  Future<Response> _createGarage(Request request) async {
    final body = await request.readAsString();
    final data = jsonDecode(body);
    
    final garage = await _garageService.createGarage(
      name: data['name'],
      city: data['city'],
      region: data['region'],
      address: data['address'],
      phone: data['phone'],
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
    );
    
    return Response.ok(jsonEncode({'success': true, 'garage': garage.toJson()}));
  }

  Future<Response> _updateGarage(Request request, String id) async {
    final body = await request.readAsString();
    final data = jsonDecode(body);
    
    final garage = await _garageService.updateGarage(id, data);
    if (garage == null) {
      return Response.notFound(jsonEncode({'success': false, 'message': 'Garage non trouvé'}));
    }
    
    return Response.ok(jsonEncode({'success': true, 'garage': garage.toJson()}));
  }

  Future<Response> _deleteGarage(Request request, String id) async {
    final deleted = await _garageService.deleteGarage(id);
    if (!deleted) {
      return Response.notFound(jsonEncode({'success': false, 'message': 'Garage non trouvé'}));
    }
    return Response.ok(jsonEncode({'success': true}));
  }

  Future<Response> _assignGarageAdmin(Request request, String id) async {
    final body = await request.readAsString();
    final data = jsonDecode(body);
    final adminId = data['adminId'];
    
    final garage = await _garageService.assignAdmin(id, adminId);
    if (garage == null) {
      return Response.notFound(jsonEncode({'success': false, 'message': 'Garage non trouvé'}));
    }
    
    return Response.ok(jsonEncode({'success': true, 'garage': garage.toJson()}));
  }
}
