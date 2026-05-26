// lib/services/garage_service.dart
import 'package:procolis_backend/services/database_service.dart';
import 'package:uuid/uuid.dart';


class GarageService {
  final _uuid = Uuid();
  
  Future<String?> getGarageIdByAdmin(String adminId) async {
    final db = await DatabaseService.getInstance();
    
    try {
      final result = await db.connection.execute(
        'SELECT garage_id FROM users WHERE id = \$1 AND role = \'admin\'',
        parameters: [adminId],
      );
      
      if (result.isEmpty) return null;
      return result.first[0] as String?;
    } catch (e) {
      return null;
    }
  }
  
  Future<List<Map<String, dynamic>>> getAllGarages() async {
    final db = await DatabaseService.getInstance();
    
    try {
      final result = await db.connection.execute('''
        SELECT id, name, city, region, address, phone, drivers_count, parcels_count, revenue, created_at
        FROM garages ORDER BY created_at DESC
      ''');
      
      return result.map((row) => ({
        'id': row[0], 'name': row[1], 'city': row[2], 'region': row[3],
        'address': row[4], 'phone': row[5], 'driversCount': row[6],
        'parcelsCount': row[7], 'revenue': row[8],
        'createdAt': (row[9] as DateTime).toIso8601String(),
      })).toList();
    } catch (e) {
      return [];
    }
  }
  
  Future<Map<String, dynamic>?> getGarageById(String garageId) async {
    final db = await DatabaseService.getInstance();
    
    try {
      final result = await db.connection.execute(
        'SELECT * FROM garages WHERE id = \$1',
        parameters: [garageId],
      );
      
      if (result.isEmpty) return null;
      
      final row = result.first;
      return {
        'id': row[0], 'name': row[1], 'city': row[2], 'region': row[3],
        'address': row[4], 'phone': row[5], 'latitude': row[6], 'longitude': row[7],
        'driversCount': row[8], 'parcelsCount': row[9], 'revenue': row[10],
        'createdAt': (row[11] as DateTime).toIso8601String(),
        'updatedAt': (row[12] as DateTime).toIso8601String(),
      };
    } catch (e) {
      return null;
    }
  }
  
  Future<String> createGarage(Map<String, dynamic> data) async {
    final db = await DatabaseService.getInstance();
    final garageId = _uuid.v4();
    
    await db.connection.execute('''
      INSERT INTO garages (id, name, city, region, address, phone, latitude, longitude, created_at, updated_at)
      VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, NOW(), NOW())
    ''', parameters: [
      garageId, data['name'], data['city'], data['region'],
      data['address'], data['phone'], data['latitude'], data['longitude']
    ]);
    
    return garageId;
  }
  
  Future<void> updateGarage(String garageId, Map<String, dynamic> data) async {
    final db = await DatabaseService.getInstance();
    
    await db.connection.execute('''
      UPDATE garages SET name = \$2, city = \$3, region = \$4, address = \$5, phone = \$6,
             latitude = \$7, longitude = \$8, updated_at = NOW()
      WHERE id = \$1
    ''', parameters: [
      garageId, data['name'], data['city'], data['region'],
      data['address'], data['phone'], data['latitude'], data['longitude']
    ]);
  }
  
  Future<void> deleteGarage(String garageId) async {
    final db = await DatabaseService.getInstance();
    
    await db.connection.execute('DELETE FROM garages WHERE id = \$1', parameters: [garageId]);
  }
  
  Future<List<Map<String, dynamic>>> getGarageDrivers(String garageId) async {
    final db = await DatabaseService.getInstance();
    
    try {
      final result = await db.connection.execute('''
        SELECT id, full_name, email, phone, driver_status, vehicle_plate, vehicle_model
        FROM users WHERE role = 'driver' AND garage_id = \$1 AND status = 'active'
      ''', parameters: [garageId]);
      
      return result.map((row) => ({
        'id': row[0], 'fullName': row[1], 'email': row[2], 'phone': row[3],
        'driverStatus': row[4], 'vehiclePlate': row[5], 'vehicleModel': row[6],
      })).toList();
    } catch (e) {
      return [];
    }
  }
  
  Future<Map<String, dynamic>> getGarageStats(String garageId) async {
    final db = await DatabaseService.getInstance();
    
    try {
      // CORRECTION: Supprimer le mot-clé 'const' et utiliser 'final'
      final parcelsResult = await db.connection.execute('''
        SELECT COUNT(*), 
               SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END),
               SUM(CASE WHEN status IN ('picked_up', 'in_transit', 'arrived', 'out_for_delivery') THEN 1 ELSE 0 END),
               SUM(CASE WHEN status = 'delivered' THEN 1 ELSE 0 END),
               COALESCE(SUM(price), 0)
        FROM parcels WHERE departure_garage_id = \$1 OR arrival_garage_id = \$1
      ''', parameters: [garageId]);
      
      // CORRECTION: Supprimer le mot-clé 'const'
      final driversResult = await db.connection.execute('''
        SELECT COUNT(*),
               SUM(CASE WHEN driver_status = 'available' THEN 1 ELSE 0 END),
               SUM(CASE WHEN driver_status = 'busy' THEN 1 ELSE 0 END)
        FROM users WHERE role = 'driver' AND garage_id = \$1
      ''', parameters: [garageId]);
      
      // Vérifier que les résultats ne sont pas vides avant d'accéder aux indices
      final totalParcels = parcelsResult.isNotEmpty ? parcelsResult.first[0] ?? 0 : 0;
      final pendingParcels = parcelsResult.isNotEmpty ? parcelsResult.first[1] ?? 0 : 0;
      final inProgressParcels = parcelsResult.isNotEmpty ? parcelsResult.first[2] ?? 0 : 0;
      final deliveredParcels = parcelsResult.isNotEmpty ? parcelsResult.first[3] ?? 0 : 0;
      final totalRevenue = parcelsResult.isNotEmpty ? parcelsResult.first[4] ?? 0 : 0;
      
      final totalDrivers = driversResult.isNotEmpty ? driversResult.first[0] ?? 0 : 0;
      final availableDrivers = driversResult.isNotEmpty ? driversResult.first[1] ?? 0 : 0;
      final busyDrivers = driversResult.isNotEmpty ? driversResult.first[2] ?? 0 : 0;
      
      return {
        'totalParcels': totalParcels,
        'pendingParcels': pendingParcels,
        'inProgressParcels': inProgressParcels,
        'deliveredParcels': deliveredParcels,
        'totalRevenue': totalRevenue,
        'totalDrivers': totalDrivers,
        'availableDrivers': availableDrivers,
        'busyDrivers': busyDrivers,
      };
    } catch (e) {
      print('❌ Erreur getGarageStats: $e');
      return {
        'totalParcels': 0,
        'pendingParcels': 0,
        'inProgressParcels': 0,
        'deliveredParcels': 0,
        'totalRevenue': 0,
        'totalDrivers': 0,
        'availableDrivers': 0,
        'busyDrivers': 0,
      };
    }
  }
}