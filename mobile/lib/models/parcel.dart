import 'package:flutter/material.dart';

import 'payment.dart'; // Importer PaymentMethod depuis payment.dart

enum ParcelStatus {
  pending('pending', 'En attente', Colors.orange),
  confirmed('confirmed', 'Confirmé', Colors.blue),
  pickedUp('picked_up', 'Ramassé', Colors.purple),
  inTransit('in_transit', 'En transit', Colors.indigo),
  arrived('arrived', 'Arrivé', Colors.teal),
  outForDelivery('out_for_delivery', 'En livraison', Colors.lightBlue),
  delivered('delivered', 'Livré', Colors.green),
  cancelled('cancelled', 'Annulé', Colors.red);

  final String value;
  final String label;
  final Color color;
  const ParcelStatus(this.value, this.label, this.color);

  static ParcelStatus fromString(String value) {
    return ParcelStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ParcelStatus.pending,
    );
  }
}

enum ParcelType {
  document('document', 'Documents', Icons.description),
  package('package', 'Colis standard', Icons.inventory),
  fragile('fragile', 'Fragile', Icons.warning),
  perishable('perishable', 'Périssable', Icons.food_bank),
  valuable('valuable', 'Valeur', Icons.attach_money);

  final String value;
  final String label;
  final IconData icon;
  const ParcelType(this.value, this.label, this.icon);

  static ParcelType fromString(String value) {
    return ParcelType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ParcelType.package,
    );
  }
}

// SUPPRIMER PaymentMethod D'ICI - il est déjà dans payment.dart

class Parcel {
  final String id;
  final String trackingNumber;
  final String senderId;
  final String senderName;
  final String senderPhone;
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
  final PaymentMethod? paymentMethod; // Utilise PaymentMethod depuis payment.dart
  final String? paymentStatus;
  final List<String> photoUrls;
  final String? signatureUrl;
  final DateTime? pickupDate;
  final DateTime? deliveryDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Parcel({
    required this.id,
    required this.trackingNumber,
    required this.senderId,
    required this.senderName,
    required this.senderPhone,
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
    this.paymentMethod,
    this.paymentStatus,
    this.photoUrls = const [],
    this.signatureUrl,
    this.pickupDate,
    this.deliveryDate,
    required this.createdAt,
    this.updatedAt,
  });

  factory Parcel.fromJson(Map<String, dynamic> json) {
    return Parcel(
      id: json['id'],
      trackingNumber: json['trackingNumber'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      senderPhone: json['senderPhone'],
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
      paymentMethod: json['paymentMethod'] != null 
          ? PaymentMethod.fromString(json['paymentMethod'])
          : null,
      paymentStatus: json['paymentStatus'],
      photoUrls: json['photoUrls'] != null ? List<String>.from(json['photoUrls']) : [],
      signatureUrl: json['signatureUrl'],
      pickupDate: json['pickupDate'] != null ? DateTime.parse(json['pickupDate']) : null,
      deliveryDate: json['deliveryDate'] != null ? DateTime.parse(json['deliveryDate']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'trackingNumber': trackingNumber,
    'senderId': senderId,
    'senderName': senderName,
    'senderPhone': senderPhone,
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
    'paymentMethod': paymentMethod?.value,
    'paymentStatus': paymentStatus,
    'photoUrls': photoUrls,
    'signatureUrl': signatureUrl,
    'pickupDate': pickupDate?.toIso8601String(),
    'deliveryDate': deliveryDate?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };
}

// Classe ParcelEvent définie en dehors de la classe Parcel
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