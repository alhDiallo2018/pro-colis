enum ParcelStatus {
  pending('pending', 'En attente'),
  confirmed('confirmed', 'Confirmé'),
  pickedUp('picked_up', 'Ramassé'),
  inTransit('in_transit', 'En transit'),
  arrived('arrived', 'Arrivé'),
  outForDelivery('out_for_delivery', 'En livraison'),
  delivered('delivered', 'Livré'),
  cancelled('cancelled', 'Annulé');

  final String value;
  final String label;
  const ParcelStatus(this.value, this.label);

  static ParcelStatus fromString(String value) {
    return ParcelStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ParcelStatus.pending,
    );
  }
}

enum ParcelType {
  document('document', 'Documents'),
  package('package', 'Colis standard'),
  fragile('fragile', 'Fragile'),
  perishable('perishable', 'Périssable'),
  valuable('valuable', 'Valeur');

  final String value;
  final String label;
  const ParcelType(this.value, this.label);

  static ParcelType fromString(String value) {
    return ParcelType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ParcelType.package,
    );
  }
}

class Parcel {
  final String id;
  final String trackingNumber;
  final String senderId;
  final String senderName;
  final String receiverName;
  final String receiverPhone;
  final String? receiverEmail;
  final String description;
  final double weight;
  final ParcelType type;
  final ParcelStatus status;
  final String departureGarageId;
  final String departureGarageName;
  final String? arrivalGarageId;
  final String? arrivalGarageName;
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final double? price;
  final String? paymentStatus;
  final List<String> photoUrls;
  final DateTime createdAt;
  final DateTime? pickedUpAt;
  final DateTime? departedAt;
  final DateTime? arrivedAt;
  final DateTime? deliveredAt;

  Parcel({
    required this.id,
    required this.trackingNumber,
    required this.senderId,
    required this.senderName,
    required this.receiverName,
    required this.receiverPhone,
    this.receiverEmail,
    required this.description,
    required this.weight,
    required this.type,
    required this.status,
    required this.departureGarageId,
    required this.departureGarageName,
    this.arrivalGarageId,
    this.arrivalGarageName,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.price,
    this.paymentStatus,
    this.photoUrls = const [],
    required this.createdAt,
    this.pickedUpAt,
    this.departedAt,
    this.arrivedAt,
    this.deliveredAt,
  });

  factory Parcel.fromJson(Map<String, dynamic> json) {
    return Parcel(
      id: json['id'],
      trackingNumber: json['trackingNumber'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      receiverName: json['receiverName'],
      receiverPhone: json['receiverPhone'],
      receiverEmail: json['receiverEmail'],
      description: json['description'],
      weight: json['weight'].toDouble(),
      type: ParcelType.fromString(json['type']),
      status: ParcelStatus.fromString(json['status']),
      departureGarageId: json['departureGarageId'],
      departureGarageName: json['departureGarageName'],
      arrivalGarageId: json['arrivalGarageId'],
      arrivalGarageName: json['arrivalGarageName'],
      driverId: json['driverId'],
      driverName: json['driverName'],
      driverPhone: json['driverPhone'],
      price: json['price']?.toDouble(),
      paymentStatus: json['paymentStatus'],
      photoUrls: json['photoUrls'] != null ? List<String>.from(json['photoUrls']) : [],
      createdAt: DateTime.parse(json['createdAt']),
      pickedUpAt: json['pickedUpAt'] != null ? DateTime.parse(json['pickedUpAt']) : null,
      departedAt: json['departedAt'] != null ? DateTime.parse(json['departedAt']) : null,
      arrivedAt: json['arrivedAt'] != null ? DateTime.parse(json['arrivedAt']) : null,
      deliveredAt: json['deliveredAt'] != null ? DateTime.parse(json['deliveredAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'trackingNumber': trackingNumber,
    'senderId': senderId,
    'senderName': senderName,
    'receiverName': receiverName,
    'receiverPhone': receiverPhone,
    'receiverEmail': receiverEmail,
    'description': description,
    'weight': weight,
    'type': type.value,
    'status': status.value,
    'departureGarageId': departureGarageId,
    'departureGarageName': departureGarageName,
    'arrivalGarageId': arrivalGarageId,
    'arrivalGarageName': arrivalGarageName,
    'driverId': driverId,
    'driverName': driverName,
    'driverPhone': driverPhone,
    'price': price,
    'paymentStatus': paymentStatus,
    'photoUrls': photoUrls,
    'createdAt': createdAt.toIso8601String(),
    'pickedUpAt': pickedUpAt?.toIso8601String(),
    'departedAt': departedAt?.toIso8601String(),
    'arrivedAt': arrivedAt?.toIso8601String(),
    'deliveredAt': deliveredAt?.toIso8601String(),
  };
}


class ParcelEvent {
  final String id;
  final String parcelId;
  final ParcelStatus status;
  final String description;
  final String? location;
  final String? userId;
  final String? userName;
  final DateTime timestamp;

  ParcelEvent({
    required this.id,
    required this.parcelId,
    required this.status,
    required this.description,
    this.location,
    this.userId,
    this.userName,
    required this.timestamp,
  });

  factory ParcelEvent.fromJson(Map<String, dynamic> json) {
    return ParcelEvent(
      id: json['id'],
      parcelId: json['parcelId'],
      status: ParcelStatus.fromString(json['status']),
      description: json['description'],
      location: json['location'],
      userId: json['userId'],
      userName: json['userName'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parcelId': parcelId,
      'status': status.value,
      'description': description,
      'location': location,
      'userId': userId,
      'userName': userName,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}