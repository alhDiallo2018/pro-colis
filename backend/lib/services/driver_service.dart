// lib/services/driver_service.dart
import '../utils/db_helper.dart';

class DriverService {
  Future<List<Map<String, dynamic>>> searchDrivers({
    String? query,
    int limit = 20,
  }) async {
    final db = await DbHelper.getInstance();
    
    try {
      String sql = '''
        SELECT id, full_name, email, phone, vehicle_plate, vehicle_model, driver_status
        FROM users WHERE role = 'driver' AND status = 'active'
      ''';
      
      final List<dynamic> params = [];
      
      if (query != null && query.isNotEmpty) {
        sql += ' AND (full_name ILIKE \$1 OR email ILIKE \$1 OR phone ILIKE \$1 OR id ILIKE \$1)';
        params.add('%$query%');
      }
      
      sql += ' LIMIT \$2';
      params.add(limit);
      
      final result = await db.connection.execute(sql, parameters: params);
      
      return result.map((row) => ({
        'id': row[0], 'fullName': row[1], 'email': row[2], 'phone': row[3],
        'vehiclePlate': row[4], 'vehicleModel': row[5], 'driverStatus': row[6],
      })).toList();
    } catch (e) {
      return [];
    }
  }
  
  Future<Map<String, dynamic>?> getDriverById(String driverId) async {
    final db = await DbHelper.getInstance();
    
    try {
      final result = await db.connection.execute('''
        SELECT id, full_name, email, phone, vehicle_plate, vehicle_model, driver_status
        FROM users WHERE id = \$1 AND role = 'driver'
      ''', parameters: [driverId]);
      
      if (result.isEmpty) return null;
      
      final row = result.first;
      return {
        'id': row[0], 'fullName': row[1], 'email': row[2], 'phone': row[3],
        'vehiclePlate': row[4], 'vehicleModel': row[5], 'driverStatus': row[6],
      };
    } catch (e) {
      return null;
    }
  }
  
  Future<List<Map<String, dynamic>>> getDriversByGarage(String garageId) async {
    final db = await DbHelper.getInstance();
    
    try {
      final result = await db.connection.execute('''
        SELECT id, full_name, email, phone, vehicle_plate, vehicle_model, driver_status
        FROM users WHERE role = 'driver' AND garage_id = \$1 AND status = 'active'
      ''', parameters: [garageId]);
      
      return result.map((row) => ({
        'id': row[0], 'fullName': row[1], 'email': row[2], 'phone': row[3],
        'vehiclePlate': row[4], 'vehicleModel': row[5], 'driverStatus': row[6],
      })).toList();
    } catch (e) {
      return [];
    }
  }
  
  Future<void> updateDriverStatus(String driverId, String status) async {
    final db = await DbHelper.getInstance();
    
    await db.connection.execute(
      'UPDATE users SET driver_status = \$2, updated_at = NOW() WHERE id = \$1',
      parameters: [driverId, status],
    );
  }
}