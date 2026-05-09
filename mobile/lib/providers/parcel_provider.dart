import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/parcel.dart';

final parcelProvider = StateNotifierProvider<ParcelNotifier, ParcelState>((ref) {
  return ParcelNotifier();
});

class ParcelNotifier extends StateNotifier<ParcelState> {
  ParcelNotifier() : super(ParcelState.initial());

  final ApiService _apiService = ApiService();

  Future<void> loadMyParcels({String? status}) async {
    state = state.copyWith(isLoading: true);
    try {
      final parcels = await _apiService.getMyParcels(status: status);
      state = state.copyWith(isLoading: false, parcels: parcels);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Parcel?> createParcel(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true);
    try {
      final parcel = await _apiService.createParcel(data);
      final newParcels = [parcel, ...state.parcels];
      state = state.copyWith(isLoading: false, parcels: newParcels);
      return parcel;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<Parcel?> trackParcel(String trackingNumber) async {
    state = state.copyWith(isLoading: true);
    try {
      final parcel = await _apiService.trackParcel(trackingNumber);
      state = state.copyWith(isLoading: false, currentParcel: parcel);
      return parcel;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<List<ParcelEvent>?> getParcelEvents(String parcelId) async {
    try {
      return await _apiService.getParcelEvents(parcelId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<Parcel?> updateStatus(String parcelId, String status, {String? location}) async {
    try {
      final updated = await _apiService.updateParcelStatus(parcelId, status, location: location);
      final updatedParcels = state.parcels.map((p) => p.id == parcelId ? updated : p).toList();
      state = state.copyWith(parcels: updatedParcels, currentParcel: updated);
      return updated;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

class ParcelState {
  final bool isLoading;
  final List<Parcel> parcels;
  final Parcel? currentParcel;
  final String? error;

  ParcelState({
    required this.isLoading,
    required this.parcels,
    this.currentParcel,
    this.error,
  });

  factory ParcelState.initial() => ParcelState(
    isLoading: false,
    parcels: [],
  );

  ParcelState copyWith({
    bool? isLoading,
    List<Parcel>? parcels,
    Parcel? currentParcel,
    String? error,
  }) {
    return ParcelState(
      isLoading: isLoading ?? this.isLoading,
      parcels: parcels ?? this.parcels,
      currentParcel: currentParcel ?? this.currentParcel,
      error: error ?? this.error,
    );
  }
}
