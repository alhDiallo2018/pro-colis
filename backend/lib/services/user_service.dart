// lib/services/user_service.dart
import 'package:uuid/uuid.dart';

import '../utils/db_helper.dart';

class UserService {
  Future<Map<String, dynamic>?> getUserById(String userId) async {
  final db = await DbHelper.getInstance();
  
  try {
    final result = await db.connection.execute('''
      SELECT id, email, phone, full_name, role, status, address, city, region, 
             vehicle_plate, vehicle_model, vehicle_color, vehicle_year,
             driver_status, garage_id, profile_photo, created_at, updated_at, last_login
      FROM users WHERE id = \$1
    ''', parameters: [userId]);
    
    if (result.isEmpty) return null;
    
    final row = result.first;
    return {
      'id': row[0],
      'email': row[1],
      'phone': row[2],
      'fullName': row[3],
      'role': row[4],
      'status': row[5],
      'address': row[6] ?? '',
      'city': row[7] ?? '',
      'region': row[8] ?? '',
      'vehiclePlate': row[9] ?? '',
      'vehicleModel': row[10] ?? '',
      'vehicleColor': row[11] ?? '',
      'vehicleYear': row[12],
      'driverStatus': row[13],
      'garageId': row[14],
      'profilePhoto': row[15],
      'createdAt': (row[16] as DateTime).toIso8601String(),
      'updatedAt': (row[17] as DateTime).toIso8601String(),
      'lastLogin': row[18] != null ? (row[18] as DateTime).toIso8601String() : null,
    };
  } catch (e) {
    print('❌ Erreur getUserById: $e');
    return null;
  }
}
  
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await DbHelper.getInstance();
    
    try {
      final result = await db.connection.execute('''
        SELECT id, email, phone, full_name, role, status, created_at
        FROM users ORDER BY created_at DESC
      ''');
      
      return result.map((row) => ({
        'id': row[0], 'email': row[1], 'phone': row[2], 'fullName': row[3],
        'role': row[4], 'status': row[5],
        'createdAt': (row[6] as DateTime).toIso8601String(),
      })).toList();
    } catch (e) {
      return [];
    }
  }
  
  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    final db = await DbHelper.getInstance();
    
    await db.connection.execute('''
      UPDATE users SET full_name = \$2, email = \$3, phone = \$4, 
             address = \$5, city = \$6, region = \$7, updated_at = NOW()
      WHERE id = \$1
    ''', parameters: [
      userId, data['fullName'], data['email'], data['phone'],
      data['address'], data['city'], data['region']
    ]);
  }
  
  Future<void> updatePin(String userId, String currentPin, String newPin) async {
    final db = await DbHelper.getInstance();
    
    // Vérifier l'ancien PIN
    final checkResult = await db.connection.execute(
      'SELECT pin FROM users WHERE id = \$1 AND pin = \$2',
      parameters: [userId, currentPin],
    );
    
    if (checkResult.isEmpty) {
      throw Exception('PIN actuel incorrect');
    }
    
    await db.connection.execute(
      'UPDATE users SET pin = \$2, updated_at = NOW() WHERE id = \$1',
      parameters: [userId, newPin],
    );
  }
  
  Future<String> createUser(Map<String, dynamic> data) async {
    final db = await DbHelper.getInstance();
    final userId = const Uuid().v4();
    
    await db.connection.execute('''
      INSERT INTO users (id, email, phone, full_name, role, status, pin, address, city, region,
                         vehicle_plate, vehicle_model, driver_status, garage_id, created_at, updated_at)
      VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10, \$11, \$12, \$13, \$14, NOW(), NOW())
    ''', parameters: [
      userId, data['email'], data['phone'], data['fullName'],
      data['role'] ?? 'client', data['status'] ?? 'active', data['pin'] ?? '123456',
      data['address'], data['city'], data['region'],
      data['vehiclePlate'], data['vehicleModel'], data['driverStatus'], data['garageId']
    ]);
    
    return userId;
  }
  
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    final db = await DbHelper.getInstance();
    
    await db.connection.execute('''
      UPDATE users SET full_name = \$2, email = \$3, phone = \$4, role = \$5, status = \$6,
             address = \$7, city = \$8, region = \$9, vehicle_plate = \$10,
             vehicle_model = \$11, driver_status = \$12, garage_id = \$13, updated_at = NOW()
      WHERE id = \$1
    ''', parameters: [
      userId, data['fullName'], data['email'], data['phone'], data['role'], data['status'],
      data['address'], data['city'], data['region'], data['vehiclePlate'],
      data['vehicleModel'], data['driverStatus'], data['garageId']
    ]);
  }
  
  Future<void> updateUserRole(String userId, String role) async {
    final db = await DbHelper.getInstance();
    
    await db.connection.execute(
      'UPDATE users SET role = \$2, updated_at = NOW() WHERE id = \$1',
      parameters: [userId, role],
    );
  }
  
  Future<void> updateUserStatus(String userId, String status) async {
    final db = await DbHelper.getInstance();
    
    await db.connection.execute(
      'UPDATE users SET status = \$2, updated_at = NOW() WHERE id = \$1',
      parameters: [userId, status],
    );
  }
  
  Future<void> deleteUser(String userId) async {
    final db = await DbHelper.getInstance();
    
    await db.connection.execute('DELETE FROM users WHERE id = \$1', parameters: [userId]);
  }
}