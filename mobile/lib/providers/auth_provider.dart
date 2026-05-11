import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import '../services/api_service.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.initial());

  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> sendOtp({required String identifier}) async {
    state = AuthState.loading();
    try {
      final result = await _apiService.sendOtp(identifier);
      if (result['success'] == true) {
        state = AuthState.otpSent(result['userId']);
      } else {
        state = AuthState.error(result['message'] ?? 'Erreur');
      }
      return result;
    } catch (e) {
      state = AuthState.error(e.toString());
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String userId,
    required String code,
    required String type,
  }) async {
    try {
      final result = await _apiService.verifyOtp(userId, code, type);
      if (result['success'] == true) {
        final userData = result['user'];
        if (userData != null) {
          final user = User.fromJson(userData);
          state = AuthState.authenticated(user);
        } else {
          state = AuthState.authenticated(null);
        }
      } else {
        state = AuthState.error(result['message'] ?? 'Code invalide');
      }
      return result;
    } catch (e) {
      state = AuthState.error(e.toString());
      return {'success': false, 'message': e.toString()};
    }
  }

  // MÉTHODE REGISTER COMPLÈTE (avec tous les paramètres optionnels)
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
    state = AuthState.loading();
    try {
      final result = await _apiService.register(
        email: email,
        phone: phone,
        fullName: fullName,
        password: password,
        role: role,
        address: address,
        city: city,
        region: region,
        vehiclePlate: vehiclePlate,
        vehicleModel: vehicleModel,
        garageId: garageId,
      );
      if (result['success'] == true) {
        state = AuthState.otpSent(result['userId']);
      } else {
        state = AuthState.error(result['message'] ?? 'Erreur');
      }
      return result;
    } catch (e) {
      state = AuthState.error(e.toString());
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> loginWithPin(String pin) async {
    state = AuthState.loading();
    try {
      final result = await _apiService.loginWithPin(pin);
      if (result['success'] == true) {
        final user = User.fromJson(result['user']);
        state = AuthState.authenticated(user);
      } else {
        state = AuthState.error(result['message'] ?? 'PIN incorrect');
      }
      return result;
    } catch (e) {
      state = AuthState.error(e.toString());
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<void> logout() async {
    await _apiService.logout();
    state = AuthState.unauthenticated();
  }
}

class AuthState {
  final bool isLoading;
  final User? user;
  final String? userId;
  final String? error;
  final bool isAuthenticated;
  final bool isOtpSent;

  AuthState({
    required this.isLoading,
    this.user,
    this.userId,
    this.error,
    this.isAuthenticated = false,
    this.isOtpSent = false,
  });

  factory AuthState.initial() => AuthState(isLoading: false);
  factory AuthState.loading() => AuthState(isLoading: true);
  factory AuthState.authenticated(User? user) => AuthState(
    isLoading: false,
    user: user,
    isAuthenticated: true,
  );
  factory AuthState.unauthenticated() => AuthState(
    isLoading: false,
    isAuthenticated: false,
  );
  factory AuthState.otpSent(String userId) => AuthState(
    isLoading: false,
    userId: userId,
    isOtpSent: true,
  );
  factory AuthState.error(String error) => AuthState(
    isLoading: false,
    error: error,
  );
}