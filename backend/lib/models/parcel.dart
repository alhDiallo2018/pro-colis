// backend/lib/models/parcel.dart

enum ParcelType {
  document('document'),
  package('package'),
  fragile('fragile'),
  perishable('perishable'),
  valuable('valuable');

  final String name;
  const ParcelType(this.name);
}

enum ParcelStatus {
  pending('pending', 'En attente'),
  confirmed('confirmed', 'Confirmé'),
  pickedUp('picked_up', 'Ramassé'),
  inTransit('in_transit', 'En transit'),
  arrived('arrived', 'Arrivé'),
  outForDelivery('out_for_delivery', 'En livraison'),
  delivered('delivered', 'Livré'),
  cancelled('cancelled', 'Annulé');

  final String name;
  final String label;
  const ParcelStatus(this.name, this.label);
}

// Définir ParcelEvent AVANT Parcel
class ParcelEvent {
  final String id;
  final String parcelId;
  final ParcelStatus status;
  final String description;
  final String? location;
  final String? userId;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  ParcelEvent({
    required this.id,
    required this.parcelId,
    required this.status,
    required this.description,
    this.location,
    this.userId,
    this.metadata,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'parcelId': parcelId,
    'status': status.name,
    'description': description,
    'location': location,
    'userId': userId,
    'metadata': metadata,
    'timestamp': timestamp.toIso8601String(),
  };
}

// Définir ParcelPhoto AVANT Parcel
class ParcelPhoto {
  final String id;
  final String parcelId;
  final String url;
  final String thumbnailUrl;
  final DateTime uploadedAt;

  ParcelPhoto({
    required this.id,
    required this.parcelId,
    required this.url,
    required this.thumbnailUrl,
    required this.uploadedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'parcelId': parcelId,
    'url': url,
    'thumbnailUrl': thumbnailUrl,
    'uploadedAt': uploadedAt.toIso8601String(),
  };
}

// Ensuite Parcel
class Parcel {
  final String id;
  final String trackingNumber;
  final String senderId;
  final String receiverName;
  final String receiverPhone;
  final String? receiverEmail;
  final String? receiverId;
  final String description;
  final double weight;
  final ParcelType type;
  final ParcelStatus status;
  final String departureGarageId;
  final String? arrivalGarageId;
  final String? currentLocationId;
  final String? driverId;
  final String? assignedVehicleId;
  final double? price;
  final String? paymentStatus;
  final DateTime createdAt;
  final DateTime? pickedUpAt;
  final DateTime? departedAt;
  final DateTime? arrivedAt;
  final DateTime? deliveredAt;
  final List<ParcelPhoto> photos;
  final List<ParcelEvent> events;

  Parcel({
    required this.id,
    required this.trackingNumber,
    required this.senderId,
    required this.receiverName,
    required this.receiverPhone,
    this.receiverEmail,
    this.receiverId,
    required this.description,
    required this.weight,
    required this.type,
    required this.status,
    required this.departureGarageId,
    this.arrivalGarageId,
    this.currentLocationId,
    this.driverId,
    this.assignedVehicleId,
    this.price,
    this.paymentStatus,
    required this.createdAt,
    this.pickedUpAt,
    this.departedAt,
    this.arrivedAt,
    this.deliveredAt,
    this.photos = const [],
    this.events = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'trackingNumber': trackingNumber,
    'senderId': senderId,
    'receiverName': receiverName,
    'receiverPhone': receiverPhone,
    'receiverEmail': receiverEmail,
    'receiverId': receiverId,
    'description': description,
    'weight': weight,
    'type': type.name,
    'status': status.name,
    'departureGarageId': departureGarageId,
    'arrivalGarageId': arrivalGarageId,
    'currentLocationId': currentLocationId,
    'driverId': driverId,
    'assignedVehicleId': assignedVehicleId,
    'price': price,
    'paymentStatus': paymentStatus,
    'createdAt': createdAt.toIso8601String(),
    'pickedUpAt': pickedUpAt?.toIso8601String(),
    'departedAt': departedAt?.toIso8601String(),
    'arrivedAt': arrivedAt?.toIso8601String(),
    'deliveredAt': deliveredAt?.toIso8601String(),
    'photos': photos.map((p) => p.toJson()).toList(),
    'events': events.map((e) => e.toJson()).toList(),
  };
}