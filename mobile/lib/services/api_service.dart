import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/parcel.dart';
// ignore: unused_import
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

  // MÉTHODE REGISTER COMPLÈTE (avec tous les paramètres)
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

  // Parcels methods
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

  Future<List<Parcel>> getDriverParcels() async {
    try {
      final response = await _dio.get('/parcels/driver/assigned');
      
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
}