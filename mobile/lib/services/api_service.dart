import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/parcel.dart';
import '../models/user.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8080';
  final Dio _dio = Dio();
  final _storage = const FlutterSecureStorage();

  ApiService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.headers['Content-Type'] = 'application/json';
    _dio.options.connectTimeout = const Duration(seconds: 30);
    
    // Intercepteur pour logger (désactivé pour production)
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) => handler.next(options),
      onResponse: (response, handler) => handler.next(response),
      onError: (error, handler) => handler.next(error),
    ));
  }

  Future<String?> getToken() async => await _storage.read(key: 'token');
  Future<void> setToken(String token) async => await _storage.write(key: 'token', value: token);
  Future<void> clearToken() async => await _storage.delete(key: 'token');

  // ==================== MÉTHODES D'AUTHENTIFICATION ====================
  
  Future<Map<String, dynamic>> register({
    required String email,
    required String phone,
    required String fullName,
    required String password,
    String role = 'client',
    String? address,
    String? city,
    String? region,
    String? vehiclePlate,
    String? vehicleModel,
    String? garageId,
  }) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'email': email,
        'phone': phone,
        'fullName': fullName,
        'password': password,
        'role': role,
        'address': address,
        'city': city,
        'region': region,
        'vehiclePlate': vehiclePlate,
        'vehicleModel': vehicleModel,
        'garageId': garageId,
      });
      
      Map<String, dynamic> responseData;
      if (response.data is String) {
        responseData = jsonDecode(response.data as String);
      } else {
        responseData = response.data as Map<String, dynamic>;
      }
      
      return responseData;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> sendOtp(String identifier) async {
    try {
      final response = await _dio.post('/auth/send-otp', data: {'identifier': identifier});
      
      Map<String, dynamic> responseData;
      if (response.data is String) {
        responseData = jsonDecode(response.data as String);
      } else {
        responseData = response.data as Map<String, dynamic>;
      }
      
      return responseData;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String userId, String code, String type) async {
    try {
      final response = await _dio.post('/auth/verify-otp', data: {
        'userId': userId,
        'code': code,
        'type': type,
      });
      
      Map<String, dynamic> responseData;
      if (response.data is String) {
        responseData = jsonDecode(response.data as String);
      } else {
        responseData = response.data as Map<String, dynamic>;
      }
      
      if (responseData['success'] == true) {
        await setToken(responseData['accessToken'] ?? '');
      }
      return responseData;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<void> logout() async {
    await clearToken();
  }

  Future<Map<String, dynamic>> loginWithPin(String pin) async {
    try {
      final response = await _dio.post('/auth/login-with-pin', data: {'pin': pin});
      
      Map<String, dynamic> responseData;
      if (response.data is String) {
        responseData = jsonDecode(response.data as String);
      } else {
        responseData = response.data as Map<String, dynamic>;
      }
      
      if (responseData['success'] == true) {
        await setToken(responseData['accessToken'] ?? '');
      }
      return responseData;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ==================== MÉTHODES UTILISATEUR ====================
  
  Future<User> getCurrentUser() async {
    final token = await getToken();
    if (token == null) throw Exception('Non authentifié');
    
    final response = await _dio.get('/users/me',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    
    Map<String, dynamic> responseData;
    if (response.data is String) {
      responseData = jsonDecode(response.data as String);
    } else {
      responseData = response.data as Map<String, dynamic>;
    }
    
    return User.fromJson(responseData['user']);
  }

  Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    required String email,
    required String phone,
    String? address,
    String? city,
    String? region,
    String? vehiclePlate,
    String? vehicleModel,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Non authentifié');
      
      final response = await _dio.put('/users/profile',
        data: {
          'fullName': fullName,
          'email': email,
          'phone': phone,
          'address': address,
          'city': city,
          'region': region,
          'vehiclePlate': vehiclePlate,
          'vehicleModel': vehicleModel,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      Map<String, dynamic> responseData;
      if (response.data is String) {
        responseData = jsonDecode(response.data as String);
      } else {
        responseData = response.data as Map<String, dynamic>;
      }
      return responseData;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updatePin(String currentPin, String newPin) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Non authentifié');
      
      final response = await _dio.put('/users/pin',
        data: {'currentPin': currentPin, 'newPin': newPin},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      Map<String, dynamic> responseData;
      if (response.data is String) {
        responseData = jsonDecode(response.data as String);
      } else {
        responseData = response.data as Map<String, dynamic>;
      }
      return responseData;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ==================== MÉTHODES PARCELS ====================
  
  Future<List<Parcel>> getMyParcels({String? status}) async {
    try {
      final queryParams = status != null ? {'status': status} : <String, dynamic>{};
      final response = await _dio.get('/parcels/my-parcels', queryParameters: queryParams);
      
      Map<String, dynamic> responseData;
      if (response.data is String) {
        responseData = jsonDecode(response.data as String);
      } else {
        responseData = response.data as Map<String, dynamic>;
      }
      
      final List<dynamic> parcelsData = responseData['parcels'] ?? [];
      return parcelsData.map((json) => Parcel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  // Driver: Récupérer les colis assignés
  Future<List<Parcel>> getDriverParcels() async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Non authentifié');
      
      final response = await _dio.get('/driver/parcels',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      Map<String, dynamic> responseData;
      if (response.data is String) {
        responseData = jsonDecode(response.data as String);
      } else {
        responseData = response.data as Map<String, dynamic>;
      }
      
      final List<dynamic> parcelsData = responseData['parcels'] ?? [];
      return parcelsData.map((json) => Parcel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  // Driver: Confirmer ramassage
  Future<Map<String, dynamic>> confirmPickup(String parcelId) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Non authentifié');
      
      final response = await _dio.post('/driver/parcels/$parcelId/pickup',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      Map<String, dynamic> responseData;
      if (response.data is String) {
        responseData = jsonDecode(response.data as String);
      } else {
        responseData = response.data as Map<String, dynamic>;
      }
      return responseData;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Driver: Confirmer livraison
  Future<Map<String, dynamic>> confirmDelivery(String parcelId, {String? signature, String? photoUrl}) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Non authentifié');
      
      final response = await _dio.post('/driver/parcels/$parcelId/deliver',
        data: {'signature': signature, 'photoUrl': photoUrl},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      Map<String, dynamic> responseData;
      if (response.data is String) {
        responseData = jsonDecode(response.data as String);
      } else {
        responseData = response.data as Map<String, dynamic>;
      }
      return responseData;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Parcel> createParcel(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/parcels/create', data: data);
      
      Map<String, dynamic> responseData;
      if (response.data is String) {
        responseData = jsonDecode(response.data as String);
      } else {
        responseData = response.data as Map<String, dynamic>;
      }
      
      return Parcel.fromJson(responseData['parcel'] as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  Future<Parcel> trackParcel(String trackingNumber) async {
    try {
      final response = await _dio.get('/parcels/track/$trackingNumber');
      
      Map<String, dynamic> responseData;
      if (response.data is String) {
        responseData = jsonDecode(response.data as String);
      } else {
        responseData = response.data as Map<String, dynamic>;
      }
      
      return Parcel.fromJson(responseData['parcel'] as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ParcelEvent>> getParcelEvents(String parcelId) async {
    try {
      final response = await _dio.get('/parcels/$parcelId/events');
      
      Map<String, dynamic> responseData;
      if (response.data is String) {
        responseData = jsonDecode(response.data as String);
      } else {
        responseData = response.data as Map<String, dynamic>;
      }
      
      final List<dynamic> eventsData = responseData['events'] ?? [];
      return eventsData.map((json) => ParcelEvent.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Parcel> updateParcelStatus(String parcelId, String status, {String? location}) async {
    try {
      final response = await _dio.put('/parcels/$parcelId/status', data: {
        'status': status,
        'location': location,
      });
      
      Map<String, dynamic> responseData;
      if (response.data is String) {
        responseData = jsonDecode(response.data as String);
      } else {
        responseData = response.data as Map<String, dynamic>;
      }
      
      return Parcel.fromJson(responseData['parcel'] as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  // ==================== MÉTHODES ADMIN ====================
  
  // Admin: Récupérer tous les utilisateurs
  Future<List<User>> getAllUsers() async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Non authentifié');
      
      final response = await _dio.get('/admin/users',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      Map<String, dynamic> responseData;
      if (response.data is String) {
        responseData = jsonDecode(response.data as String);
      } else {
        responseData = response.data as Map<String, dynamic>;
      }
      
      final List<dynamic> usersData = responseData['users'] ?? [];
      return usersData.map((json) => User.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  // Admin: Créer un utilisateur
  Future<Map<String, dynamic>> createUserByAdmin({
    required String fullName,
    required String email,
    required String phone,
    required String role,
    required String status,
    String? address,
    String? city,
    String? region,
    required String pin,
    String? gender,
    String? vehiclePlate,
    String? vehicleModel,
    String? driverStatus,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Non authentifié');
      
      final response = await _dio.post('/admin/users',
        data: {
          'fullName': fullName,
          'email': email,
          'phone': phone,
          'role': role,
          'status': status,
          'address': address,
          'city': city,
          'region': region,
          'pin': pin,
          'gender': gender,
          'vehiclePlate': vehiclePlate,
          'vehicleModel': vehicleModel,
          'driverStatus': driverStatus,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      Map<String, dynamic> responseData;
      if (response.data is String) {
        responseData = jsonDecode(response.data as String);
      } else {
        responseData = response.data as Map<String, dynamic>;
      }
      return responseData;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Admin: Modifier un utilisateur
  Future<Map<String, dynamic>> updateUserByAdmin({
    required String userId,
    required String fullName,
    required String email,
    required String phone,
    required String role,
    required String status,
    String? address,
    String? city,
    String? region,
    String? vehiclePlate,
    String? vehicleModel,
    String? driverStatus,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Non authentifié');
      
      final response = await _dio.put('/admin/users/$userId',
        data: {
          'fullName': fullName,
          'email': email,
          'phone': phone,
          'role': role,
          'status': status,
          'address': address,
          'city': city,
          'region': region,
          'vehiclePlate': vehiclePlate,
          'vehicleModel': vehicleModel,
          'driverStatus': driverStatus,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      Map<String, dynamic> responseData;
      if (response.data is String) {
        responseData = jsonDecode(response.data as String);
      } else {
        responseData = response.data as Map<String, dynamic>;
      }
      return responseData;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Admin: Changer le statut d'un utilisateur
  Future<Map<String, dynamic>> updateUserStatus(String userId, String status) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Non authentifié');
      
      final response = await _dio.patch('/admin/users/$userId/status',
        data: {'status': status},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      Map<String, dynamic> responseData;
      if (response.data is String) {
        responseData = jsonDecode(response.data as String);
      } else {
        responseData = response.data as Map<String, dynamic>;
      }
      return responseData;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Admin: Supprimer un utilisateur
  Future<Map<String, dynamic>> deleteUser(String userId) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Non authentifié');
      
      final response = await _dio.delete('/admin/users/$userId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      Map<String, dynamic> responseData;
      if (response.data is String) {
        responseData = jsonDecode(response.data as String);
      } else {
        responseData = response.data as Map<String, dynamic>;
      }
      return responseData;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Admin: Réinitialiser le PIN d'un utilisateur
  Future<Map<String, dynamic>> resetUserPin(String userId) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('Non authentifié');
      
      final response = await _dio.post('/admin/users/$userId/reset-pin',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      Map<String, dynamic> responseData;
      if (response.data is String) {
        responseData = jsonDecode(response.data as String);
      } else {
        responseData = response.data as Map<String, dynamic>;
      }
      return responseData;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}