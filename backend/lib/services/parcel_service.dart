import 'package:uuid/uuid.dart';

enum ParcelStatus {
  pending,
  pickedUp,
  inTransit,
  arrived,
  delivered,
  cancelled,
}

class Parcel {
  final String id;
  final String trackingNumber;
  final String senderId;
  final String receiverName;
  final String receiverPhone;
  final String? receiverEmail;
  final String description;
  final double weight;
  final String type;
  final ParcelStatus status;
  final String departureGarageId;
  final String? arrivalGarageId;
  final String? driverId;
  final double? price;
  final DateTime createdAt;
  final DateTime? deliveredAt;

  Parcel({
    required this.id,
    required this.trackingNumber,
    required this.senderId,
    required this.receiverName,
    required this.receiverPhone,
    this.receiverEmail,
    required this.description,
    required this.weight,
    required this.type,
    required this.status,
    required this.departureGarageId,
    this.arrivalGarageId,
    this.driverId,
    this.price,
    required this.createdAt,
    this.deliveredAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'trackingNumber': trackingNumber,
    'senderId': senderId,
    'receiverName': receiverName,
    'receiverPhone': receiverPhone,
    'receiverEmail': receiverEmail,
    'description': description,
    'weight': weight,
    'type': type,
    'status': status.name,
    'departureGarageId': departureGarageId,
    'arrivalGarageId': arrivalGarageId,
    'driverId': driverId,
    'price': price,
    'createdAt': createdAt.toIso8601String(),
    'deliveredAt': deliveredAt?.toIso8601String(),
  };
}

class ParcelEvent {
  final String id;
  final String parcelId;
  final String status;
  final String description;
  final DateTime timestamp;

  ParcelEvent({
    required this.id,
    required this.parcelId,
    required this.status,
    required this.description,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'parcelId': parcelId,
    'status': status,
    'description': description,
    'timestamp': timestamp.toIso8601String(),
  };
}

class ParcelService {
  final List<Parcel> _parcels = [];
  final List<ParcelEvent> _events = [];
  final _uuid = const Uuid();
  
  Future<Parcel> createParcel({
    required String trackingNumber,
    required String senderId,
    required String receiverName,
    required String receiverPhone,
    String? receiverEmail,
    required String description,
    required double weight,
    required String type,
    required String departureGarageId,
    String? arrivalGarageId,
    double? price,
  }) async {
    final parcel = Parcel(
      id: _uuid.v4(),
      trackingNumber: trackingNumber,
      senderId: senderId,
      receiverName: receiverName,
      receiverPhone: receiverPhone,
      receiverEmail: receiverEmail,
      description: description,
      weight: weight,
      type: type,
      status: ParcelStatus.pending,
      departureGarageId: departureGarageId,
      arrivalGarageId: arrivalGarageId,
      price: price,
      createdAt: DateTime.now(),
    );
    
    _parcels.add(parcel);
    
    // Ajouter un événement initial
    _events.add(ParcelEvent(
      id: _uuid.v4(),
      parcelId: parcel.id,
      status: 'pending',
      description: 'Colis créé',
      timestamp: DateTime.now(),
    ));
    
    return parcel;
  }
  
  Future<Parcel?> findByTrackingNumber(String trackingNumber) async {
    try {
      return _parcels.firstWhere((p) => p.trackingNumber == trackingNumber);
    } catch (e) {
      return null;
    }
  }
  
  Future<Parcel?> getParcel(String id) async {
    try {
      return _parcels.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }
  
  Future<List<Parcel>> getUserParcels(String userId, {String? status}) async {
    var userParcels = _parcels.where((p) => p.senderId == userId).toList();
    
    if (status != null) {
      userParcels = userParcels.where((p) => p.status.name == status).toList();
    }
    
    return userParcels;
  }
  
  Future<Parcel?> updateStatus(
    String parcelId,
    String status,
    String userId,
    String userRole, {
    String? location,
    Map<String, dynamic>? metadata,
  }) async {
    final index = _parcels.indexWhere((p) => p.id == parcelId);
    if (index == -1) return null;
    
    final old = _parcels[index];
    final newStatus = ParcelStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => old.status,
    );
    
    final updated = Parcel(
      id: old.id,
      trackingNumber: old.trackingNumber,
      senderId: old.senderId,
      receiverName: old.receiverName,
      receiverPhone: old.receiverPhone,
      receiverEmail: old.receiverEmail,
      description: old.description,
      weight: old.weight,
      type: old.type,
      status: newStatus,
      departureGarageId: old.departureGarageId,
      arrivalGarageId: old.arrivalGarageId,
      driverId: newStatus == ParcelStatus.inTransit ? userId : old.driverId,
      price: old.price,
      createdAt: old.createdAt,
      deliveredAt: newStatus == ParcelStatus.delivered ? DateTime.now() : old.deliveredAt,
    );
    
    _parcels[index] = updated;
    
    // Ajouter un événement pour le changement de statut
    _events.add(ParcelEvent(
      id: _uuid.v4(),
      parcelId: parcelId,
      status: status,
      description: 'Statut mis à jour: $status${location != null ? ' à $location' : ''}',
      timestamp: DateTime.now(),
    ));
    
    return updated;
  }
  
  Future<Parcel?> confirmPickup(String parcelId, String driverId) async {
    return await updateStatus(parcelId, 'pickedUp', driverId, 'driver');
  }
  
  Future<Parcel?> confirmDelivery(
    String parcelId,
    String driverId, {
    String? signature,
    String? photoUrl,
  }) async {
    return await updateStatus(parcelId, 'delivered', driverId, 'driver');
  }
  
  Future<List<Parcel>> getDriverParcels(String driverId) async {
    return _parcels.where((p) => p.driverId == driverId).toList();
  }
  
  Future<List<Parcel>> getGarageParcels(String garageId) async {
    return _parcels.where((p) => 
      p.departureGarageId == garageId || p.arrivalGarageId == garageId
    ).toList();
  }
  
  Future<List<ParcelEvent>> getEvents(String parcelId) async {
    return _events.where((e) => e.parcelId == parcelId).toList();
  }
  
  Future<Map<String, dynamic>> getStats() async {
    return {
      'totalParcels': _parcels.length,
      'pending': _parcels.where((p) => p.status == ParcelStatus.pending).length,
      'pickedUp': _parcels.where((p) => p.status == ParcelStatus.pickedUp).length,
      'inTransit': _parcels.where((p) => p.status == ParcelStatus.inTransit).length,
      'arrived': _parcels.where((p) => p.status == ParcelStatus.arrived).length,
      'delivered': _parcels.where((p) => p.status == ParcelStatus.delivered).length,
      'cancelled': _parcels.where((p) => p.status == ParcelStatus.cancelled).length,
    };
  }
}