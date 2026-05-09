import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/garage.dart';
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
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await refreshToken();
          if (refreshed) {
            return handler.resolve(await _retry(error.requestOptions));
          }
        }
        return handler.next(error);
      },
    ));
  }

  Future<String?> getToken() async => await _storage.read(key: 'access_token');
  Future<String?> getRefreshToken() async => await _storage.read(key: 'refresh_token');

  Future<void> setTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  Future<bool> refreshToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return false;
      final response = await _dio.post('/auth/refresh-token', data: {'refreshToken': refreshToken});
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        await setTokens(data['accessToken'] as String, refreshToken);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final options = Options(method: requestOptions.method, headers: requestOptions.headers);
    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  // Auth
  Future<Map<String, dynamic>> sendOtp(String identifier) async {
    final response = await _dio.post('/auth/send-otp', data: {'identifier': identifier});
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> verifyOtp(String userId, String code, String type) async {
    final response = await _dio.post('/auth/verify-otp', data: {
      'userId': userId,
      'code': code,
      'type': type,
    });
    final data = response.data as Map<String, dynamic>;
    if (data['success'] == true) {
      await setTokens(data['accessToken'] as String, data['refreshToken'] as String);
    }
    return data;
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String phone,
    required String fullName,
    required String password,
    String role = 'client',
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'email': email,
      'phone': phone,
      'fullName': fullName,
      'password': password,
      'role': role,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<User> getCurrentUser() async {
    final response = await _dio.get('/auth/me');
    final data = response.data as Map<String, dynamic>;
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _dio.post('/auth/logout');
    await clearTokens();
  }

  // Parcels
  Future<Parcel> createParcel(Map<String, dynamic> data) async {
    final response = await _dio.post('/parcels/create', data: data);
    final responseData = response.data as Map<String, dynamic>;
    return Parcel.fromJson(responseData['parcel'] as Map<String, dynamic>);
  }

  Future<List<Parcel>> getMyParcels({String? status}) async {
    final Map<String, dynamic> queryParams = {};
    if (status != null) queryParams['status'] = status;
    final response = await _dio.get('/parcels/my-parcels', queryParameters: queryParams);
    final data = response.data as Map<String, dynamic>;
    final List<dynamic> parcelsData = data['parcels'] as List<dynamic>;
    return parcelsData.map((json) => Parcel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Parcel> trackParcel(String trackingNumber) async {
    final response = await _dio.get('/parcels/track/$trackingNumber');
    final data = response.data as Map<String, dynamic>;
    return Parcel.fromJson(data['parcel'] as Map<String, dynamic>);
  }

  Future<Parcel> getParcel(String id) async {
    final response = await _dio.get('/parcels/$id');
    final data = response.data as Map<String, dynamic>;
    return Parcel.fromJson(data['parcel'] as Map<String, dynamic>);
  }

  Future<List<ParcelEvent>> getParcelEvents(String id) async {
    final response = await _dio.get('/parcels/$id/events');
    final data = response.data as Map<String, dynamic>;
    final List<dynamic> eventsData = data['events'] as List<dynamic>;
    return eventsData.map((json) => ParcelEvent.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Parcel> updateParcelStatus(String id, String status, {String? location}) async {
    final response = await _dio.put('/parcels/$id/status', data: {
      'status': status,
      'location': location,
    });
    final data = response.data as Map<String, dynamic>;
    return Parcel.fromJson(data['parcel'] as Map<String, dynamic>);
  }

  // Payments
  Future<Map<String, dynamic>> initiatePayment({
    required String parcelId,
    required double amount,
    required String method,
    String? phoneNumber,
  }) async {
    final response = await _dio.post('/payments/init', data: {
      'parcelId': parcelId,
      'amount': amount,
      'method': method,
      'phoneNumber': phoneNumber,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getPaymentStatus(String paymentId) async {
    final response = await _dio.get('/payments/$paymentId');
    return response.data as Map<String, dynamic>;
  }

  // Garages
  Future<List<Garage>> getGarages() async {
    final response = await _dio.get('/garages');
    final data = response.data as Map<String, dynamic>;
    final List<dynamic> garagesData = data['garages'] as List<dynamic>;
    return garagesData.map((json) => Garage.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Garage> getGarage(String id) async {
    final response = await _dio.get('/garages/$id');
    final data = response.data as Map<String, dynamic>;
    return Garage.fromJson(data['garage'] as Map<String, dynamic>);
  }

  // Admin
  Future<Map<String, dynamic>> getAdminStats() async {
    final response = await _dio.get('/admin/stats/overview');
    final data = response.data as Map<String, dynamic>;
    return data['stats'] as Map<String, dynamic>;
  }

  Future<List<User>> getAllUsers({int page = 1, String? role}) async {
    final Map<String, dynamic> queryParams = {'page': page, 'limit': 20};
    if (role != null) queryParams['role'] = role;
    final response = await _dio.get('/admin/users', queryParameters: queryParams);
    final data = response.data as Map<String, dynamic>;
    final List<dynamic> usersData = data['users'] as List<dynamic>;
    return usersData.map((json) => User.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<User> updateUserRole(String userId, String role) async {
    final response = await _dio.put('/admin/users/$userId/role', data: {'role': role});
    final data = response.data as Map<String, dynamic>;
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  // Driver
  Future<List<Parcel>> getDriverParcels() async {
    final response = await _dio.get('/parcels/driver/assigned');
    final data = response.data as Map<String, dynamic>;
    final List<dynamic> parcelsData = data['parcels'] as List<dynamic>;
    return parcelsData.map((json) => Parcel.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Parcel> confirmPickup(String parcelId) async {
    final response = await _dio.post('/parcels/driver/$parcelId/pickup');
    final data = response.data as Map<String, dynamic>;
    return Parcel.fromJson(data['parcel'] as Map<String, dynamic>);
  }

  Future<Parcel> confirmDelivery(String parcelId, {String? signature, String? photoUrl}) async {
    final response = await _dio.post('/parcels/driver/$parcelId/deliver', data: {
      'signature': signature,
      'photoUrl': photoUrl,
    });
    final data = response.data as Map<String, dynamic>;
    return Parcel.fromJson(data['parcel'] as Map<String, dynamic>);
  }

  Future<void> updateDriverLocation(double latitude, double longitude) async {
    await _dio.post('/driver/location', data: {
      'latitude': latitude,
      'longitude': longitude,
    });
  }
}
