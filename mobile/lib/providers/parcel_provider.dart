import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/parcel.dart';
import '../services/api_service.dart';

// Provider pour le gestionnaire des colis
final parcelProvider = StateNotifierProvider<ParcelNotifier, ParcelState>((ref) {
  return ParcelNotifier();
});

class ParcelNotifier extends StateNotifier<ParcelState> {
  ParcelNotifier() : super(ParcelState.initial());
  
  final ApiService _apiService = ApiService();

  // Charger tous les colis de l'utilisateur (client)
  Future<void> loadMyParcels({String? status}) async {
    state = ParcelState.loading();
    try {
      final parcels = await _apiService.getMyParcels(status: status);
      state = ParcelState.loaded(parcels);
    } catch (e) {
      state = ParcelState.error(e.toString());
    }
  }

  // Charger les colis assignés au chauffeur
  Future<void> loadDriverParcels() async {
    state = ParcelState.loading();
    try {
      final parcels = await _apiService.getDriverParcels();
      state = ParcelState.loaded(parcels);
    } catch (e) {
      state = ParcelState.error(e.toString());
    }
  }

  // Créer un nouveau colis
  Future<Parcel?> createParcel(Map<String, dynamic> data) async {
    state = ParcelState.loading();
    try {
      final parcel = await _apiService.createParcel(data);
      // Recharger la liste après création
      await loadMyParcels();
      return parcel;
    } catch (e) {
      state = ParcelState.error(e.toString());
      return null;
    }
  }

  // Suivre un colis par numéro de tracking
  Future<Parcel?> trackParcel(String trackingNumber) async {
    state = ParcelState.loading();
    try {
      final parcel = await _apiService.trackParcel(trackingNumber);
      state = ParcelState.tracked(parcel);
      return parcel;
    } catch (e) {
      state = ParcelState.error(e.toString());
      return null;
    }
  }

  // Mettre à jour le statut d'un colis
  Future<Parcel?> updateParcelStatus(String parcelId, String status, {String? location}) async {
    try {
      final parcel = await _apiService.updateParcelStatus(parcelId, status, location: location);
      // Recharger la liste après mise à jour
      await loadMyParcels();
      return parcel;
    } catch (e) {
      state = ParcelState.error(e.toString());
      return null;
    }
  }

  // Récupérer les événements d'un colis
  Future<List<ParcelEvent>> getParcelEvents(String parcelId) async {
    try {
      final events = await _apiService.getParcelEvents(parcelId);
      return events;
    } catch (e) {
      state = ParcelState.error(e.toString());
      return [];
    }
  }

  // Marquer un colis comme ramassé (chauffeur)
  Future<void> markAsPickedUp(String parcelId) async {
    state = ParcelState.loading();
    try {
      await _apiService.updateParcelStatus(parcelId, 'picked_up', location: 'Au garage');
      await loadDriverParcels();
    } catch (e) {
      state = ParcelState.error(e.toString());
    }
  }

  // Marquer un colis comme en transit (chauffeur)
  Future<void> markAsInTransit(String parcelId) async {
    state = ParcelState.loading();
    try {
      await _apiService.updateParcelStatus(parcelId, 'in_transit');
      await loadDriverParcels();
    } catch (e) {
      state = ParcelState.error(e.toString());
    }
  }

  // Marquer un colis comme livré (chauffeur)
  Future<void> markAsDelivered(String parcelId) async {
    state = ParcelState.loading();
    try {
      await _apiService.updateParcelStatus(parcelId, 'delivered', location: 'Au destinataire');
      await loadDriverParcels();
    } catch (e) {
      state = ParcelState.error(e.toString());
    }
  }

  // Réinitialiser l'état
  void reset() {
    state = ParcelState.initial();
  }

  // Effacer les erreurs
  void clearError() {
    if (state.error != null) {
      state = ParcelState.initial();
    }
  }
}

// État du provider
class ParcelState {
  final bool isLoading;
  final List<Parcel> parcels;
  final Parcel? trackedParcel;
  final String? error;
  final bool isSuccess;

  ParcelState({
    required this.isLoading,
    this.parcels = const [],
    this.trackedParcel,
    this.error,
    this.isSuccess = false,
  });

  // État initial
  factory ParcelState.initial() => ParcelState(
    isLoading: false,
    parcels: const [],
    trackedParcel: null,
    error: null,
    isSuccess: false,
  );

  // État de chargement
  factory ParcelState.loading() => ParcelState(
    isLoading: true,
    parcels: const [],
    trackedParcel: null,
    error: null,
    isSuccess: false,
  );

  // État avec liste de colis chargée
  factory ParcelState.loaded(List<Parcel> parcels) => ParcelState(
    isLoading: false,
    parcels: parcels,
    trackedParcel: null,
    error: null,
    isSuccess: true,
  );

  // État avec colis suivi
  factory ParcelState.tracked(Parcel parcel) => ParcelState(
    isLoading: false,
    parcels: const [],
    trackedParcel: parcel,
    error: null,
    isSuccess: true,
  );

  // État d'erreur
  factory ParcelState.error(String error) => ParcelState(
    isLoading: false,
    parcels: const [],
    trackedParcel: null,
    error: error,
    isSuccess: false,
  );

  // Getter pour vérifier si la liste est vide
  bool get hasParcels => parcels.isNotEmpty;
  
  // Getter pour obtenir les colis par statut
  List<Parcel> getParcelsByStatus(ParcelStatus status) {
    return parcels.where((parcel) => parcel.status == status).toList();
  }
  
  // Getter pour les colis en attente de ramassage
  List<Parcel> get pendingParcels {
    return parcels.where((parcel) => 
      parcel.status == ParcelStatus.pending || 
      parcel.status == ParcelStatus.confirmed
    ).toList();
  }
  
  // Getter pour les colis en cours
  List<Parcel> get inProgressParcels {
    return parcels.where((parcel) => 
      parcel.status == ParcelStatus.pickedUp || 
      parcel.status == ParcelStatus.inTransit ||
      parcel.status == ParcelStatus.arrived ||
      parcel.status == ParcelStatus.outForDelivery
    ).toList();
  }
  
  // Getter pour les colis terminés
  List<Parcel> get completedParcels {
    return parcels.where((parcel) => 
      parcel.status == ParcelStatus.delivered
    ).toList();
  }
}