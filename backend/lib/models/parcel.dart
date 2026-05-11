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
  final String receiverName;
  final String receiverPhone;
  final String description;
  final double weight;
  final ParcelStatus status;
  final double? price;
  final DateTime createdAt;

  Parcel({
    required this.id,
    required this.trackingNumber,
    required this.receiverName,
    required this.receiverPhone,
    required this.description,
    required this.weight,
    required this.status,
    this.price,
    required this.createdAt,
  });

  factory Parcel.fromJson(Map<String, dynamic> json) {
    ParcelStatus status;
    switch (json['status']) {
      case 'pending':
        status = ParcelStatus.pending;
        break;
      case 'pickedUp':
        status = ParcelStatus.pickedUp;
        break;
      case 'inTransit':
        status = ParcelStatus.inTransit;
        break;
      case 'arrived':
        status = ParcelStatus.arrived;
        break;
      case 'delivered':
        status = ParcelStatus.delivered;
        break;
      case 'cancelled':
        status = ParcelStatus.cancelled;
        break;
      default:
        status = ParcelStatus.pending;
    }
    
    return Parcel(
      id: json['id'],
      trackingNumber: json['trackingNumber'],
      receiverName: json['receiverName'],
      receiverPhone: json['receiverPhone'],
      description: json['description'],
      weight: json['weight'].toDouble(),
      status: status,
      price: json['price']?.toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'trackingNumber': trackingNumber,
    'receiverName': receiverName,
    'receiverPhone': receiverPhone,
    'description': description,
    'weight': weight,
    'status': status.name,
    'price': price,
    'createdAt': createdAt.toIso8601String(),
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

  factory ParcelEvent.fromJson(Map<String, dynamic> json) {
    return ParcelEvent(
      id: json['id'],
      parcelId: json['parcelId'],
      status: json['status'],
      description: json['description'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
