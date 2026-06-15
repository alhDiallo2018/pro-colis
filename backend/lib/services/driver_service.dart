// lib/services/driver_service.dart
import 'package:procolis_backend/services/database_service.dart';

class DriverService {
  Future<List<Map<String, dynamic>>> searchDrivers({
    String? query,
    int limit = 20,
  }) async {
    final db = await DatabaseService.getInstance();
    
    try {
      String sql = '''
        SELECT id, full_name, email, phone, vehicle_plate, vehicle_model, driver_status
        FROM users WHERE role = 'driver' AND status = 'active'
      ''';
      
      final List<dynamic> params = [];
      int paramCounter = 1;
      
      if (query != null && query.isNotEmpty) {
        sql += ' AND (full_name ILIKE \$$paramCounter OR email ILIKE \$$paramCounter OR phone ILIKE \$$paramCounter OR id::text ILIKE \$$paramCounter)';
        params.add('%$query%');
        paramCounter++;
      }
      
      sql += ' ORDER BY full_name ASC LIMIT \$$paramCounter';
      params.add(limit);
      
      print('🔍 SQL: $sql');
      print('🔍 Params: $params');
      
      // Correction: Passer les paramètres comme un seul argument
      final result = await db.connection.execute(sql, parameters: params);
      
      print('✅ ${result.length} chauffeurs trouvés');
      
      return result.map((row) => ({
        'id': row[0].toString(),
        'fullName': row[1].toString(),
        'email': row[2].toString(),
        'phone': row[3].toString(),
        'vehiclePlate': row[4]?.toString(),
        'vehicleModel': row[5]?.toString(),
        'driverStatus': row[6]?.toString() ?? 'offline',
      })).toList();
    } catch (e) {
      print('❌ Erreur searchDrivers: $e');
      return [];
    }
  }
  
  Future<Map<String, dynamic>?> getDriverById(String driverId) async {
    final db = await DatabaseService.getInstance();
    
    try {
      // Correction: Passer les paramètres comme une liste
      final result = await db.connection.execute(
        'SELECT id, full_name, email, phone, vehicle_plate, vehicle_model, driver_status '
        'FROM users WHERE id = \$1 AND role = \'driver\' AND status = \'active\'',
        parameters: [driverId]
      );
      
      if (result.isEmpty) return null;
      
      final row = result.first;
      return {
        'id': row[0].toString(),
        'fullName': row[1].toString(),
        'email': row[2].toString(),
        'phone': row[3].toString(),
        'vehiclePlate': row[4]?.toString(),
        'vehicleModel': row[5]?.toString(),
        'driverStatus': row[6]?.toString() ?? 'offline',
      };
    } catch (e) {
      print('❌ Erreur getDriverById: $e');
      return null;
    }
  }
  
  Future<List<Map<String, dynamic>>> getDriversByGarage(String garageId) async {
    final db = await DatabaseService.getInstance();
    
    try {
      // Correction: Passer les paramètres comme une liste
      final result = await db.connection.execute(
        'SELECT id, full_name, email, phone, vehicle_plate, vehicle_model, driver_status '
        'FROM users WHERE role = \'driver\' AND garage_id = \$1 AND status = \'active\' '
        'ORDER BY full_name ASC',
        parameters: [garageId]
      );
      
      return result.map((row) => ({
        'id': row[0].toString(),
        'fullName': row[1].toString(),
        'email': row[2].toString(),
        'phone': row[3].toString(),
        'vehiclePlate': row[4]?.toString(),
        'vehicleModel': row[5]?.toString(),
        'driverStatus': row[6]?.toString() ?? 'offline',
      })).toList();
    } catch (e) {
      print('❌ Erreur getDriversByGarage: $e');
      return [];
    }
  }
  
  Future<void> updateDriverStatus(String driverId, String status) async {
    final db = await DatabaseService.getInstance();
    
    try {
      // Correction: Passer les paramètres comme une liste
      await db.connection.execute(
        'UPDATE users SET driver_status = \$2, updated_at = NOW() WHERE id = \$1',
        parameters: [driverId, status]
      );
      print('✅ Statut du chauffeur $driverId mis à jour: $status');
    } catch (e) {
      print('❌ Erreur updateDriverStatus: $e');
    }
  }
  
  // Nouvelle méthode pour obtenir tous les chauffeurs avec plus de détails
  Future<List<Map<String, dynamic>>> getAllDrivers({int limit = 100}) async {
    final db = await DatabaseService.getInstance();
    
    try {
      // Correction: Passer les paramètres comme une liste
      final result = await db.connection.execute(
        'SELECT '
          'id, '
          'full_name, '
          'email, '
          'phone, '
          'vehicle_plate, '
          'vehicle_model, '
          'vehicle_color, '
          'driver_status, '
          'rating, '
          'total_deliveries, '
          'profile_photo, '
          'garage_id, '
          'garage_name '
        'FROM users '
        'WHERE role = \'driver\' AND status = \'active\' '
        'ORDER BY full_name ASC '
        'LIMIT \$1',
        parameters: [limit]
      );
      
      print('✅ ${result.length} chauffeurs chargés (getAllDrivers)');
      
      return result.map((row) => ({
        'id': row[0].toString(),
        'fullName': row[1].toString(),
        'email': row[2].toString(),
        'phone': row[3].toString(),
        'vehiclePlate': row[4]?.toString(),
        'vehicleModel': row[5]?.toString(),
        'vehicleColor': row[6]?.toString(),
        'driverStatus': row[7]?.toString() ?? 'offline',
        'rating': row[8] != null ? (row[8] is double ? row[8] : double.tryParse(row[8].toString()) ?? 0.0) : null,
        'totalDeliveries': row[9] != null ? (row[9] is int ? row[9] : int.tryParse(row[9].toString()) ?? 0) : null,
        'profilePhoto': row[10]?.toString(),
        'garageId': row[11]?.toString(),
        'garageName': row[12]?.toString(),
      })).toList();
    } catch (e) {
      print('❌ Erreur getAllDrivers: $e');
      return [];
    }
  }
}