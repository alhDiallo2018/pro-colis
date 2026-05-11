import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class AdminController {
  final Map<String, Map<String, dynamic>> _users;

  AdminController({required Map<String, Map<String, dynamic>> users}) : _users = users;

  Router get router {
    final router = Router();
    
    router.get('/stats/overview', _getOverviewStats);
    router.get('/users', _getAllUsers);
    router.put('/users/<id>/role', _updateUserRole);
    
    return router;
  }

  Future<Response> _getOverviewStats(Request request) async {
    final totalUsers = _users.length;
    final totalClients = _users.values.where((u) => u['role'] == 'client').length;
    final totalDrivers = _users.values.where((u) => u['role'] == 'driver').length;
    final totalAdmins = _users.values.where((u) => u['role'] == 'admin').length;
    
    return Response.ok(jsonEncode({
      'success': true,
      'stats': {
        'totalUsers': totalUsers,
        'totalClients': totalClients,
        'totalDrivers': totalDrivers,
        'totalAdmins': totalAdmins,
        'totalGarages': 3,
        'totalParcels': 0,
        'parcelsInTransit': 0,
        'parcelsDeliveredToday': 0,
        'totalRevenue': 0,
      },
    }));
  }

  Future<Response> _getAllUsers(Request request) async {
    final usersList = _users.values.map((user) {
      return {
        'id': user['id'],
        'email': user['email'],
        'phone': user['phone'],
        'fullName': user['fullName'],
        'role': user['role'],
        'createdAt': user['createdAt'],
      };
    }).toList();
    
    return Response.ok(jsonEncode({
      'success': true,
      'users': usersList,
    }));
  }

  Future<Response> _updateUserRole(Request request, String id) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      
      if (!_users.containsKey(id)) {
        return Response.notFound(jsonEncode({
          'success': false,
          'message': 'Utilisateur non trouvé',
        }));
      }
      
      _users[id]?['role'] = data['role'];
      
      return Response.ok(jsonEncode({
        'success': true,
        'user': _users[id],
      }));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de la mise à jour: $e',
      }));
    }
  }
}
