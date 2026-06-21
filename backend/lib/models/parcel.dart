// backend/lib/models/parcel.dart

enum ParcelStatus {
  pending,
  free,
  confirmed,
  pickedUp,
  inTransit,
  arrived,
  outForDelivery,
  delivered,
  cancelled;

  String get value {
    switch (this) {
      case ParcelStatus.pending:
        return 'pending';
      case ParcelStatus.free:
        return 'free';
      case ParcelStatus.confirmed:
        return 'confirmed';
      case ParcelStatus.pickedUp:
        return 'picked_up';
      case ParcelStatus.inTransit:
        return 'in_transit';
      case ParcelStatus.arrived:
        return 'arrived';
      case ParcelStatus.outForDelivery:
        return 'out_for_delivery';
      case ParcelStatus.delivered:
        return 'delivered';
      case ParcelStatus.cancelled:
        return 'cancelled';
    }
  }

  static ParcelStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return ParcelStatus.pending;
      case 'free':
        return ParcelStatus.free;
      case 'confirmed':
        return ParcelStatus.confirmed;
      case 'picked_up':
        return ParcelStatus.pickedUp;
      case 'in_transit':
        return ParcelStatus.inTransit;
      case 'arrived':
        return ParcelStatus.arrived;
      case 'out_for_delivery':
        return ParcelStatus.outForDelivery;
      case 'delivered':
        return ParcelStatus.delivered;
      case 'cancelled':
        return ParcelStatus.cancelled;
      default:
        return ParcelStatus.pending;
    }
  }

  bool get isFree => this == ParcelStatus.free;
  bool get isPending => this == ParcelStatus.pending;
  bool get isConfirmed => this == ParcelStatus.confirmed;
  bool get isPickedUp => this == ParcelStatus.pickedUp;
  bool get isInTransit => this == ParcelStatus.inTransit;
  bool get isArrived => this == ParcelStatus.arrived;
  bool get isOutForDelivery => this == ParcelStatus.outForDelivery;
  bool get isDelivered => this == ParcelStatus.delivered;
  bool get isCancelled => this == ParcelStatus.cancelled;
  bool get isInProgress => this == ParcelStatus.confirmed ||
      this == ParcelStatus.pickedUp ||
      this == ParcelStatus.inTransit ||
      this == ParcelStatus.arrived ||
      this == ParcelStatus.outForDelivery;
}

enum ParcelType {
  document,
  package,
  fragile,
  perishable,
  valuable;

  String get value {
    switch (this) {
      case ParcelType.document:
        return 'document';
      case ParcelType.package:
        return 'package';
      case ParcelType.fragile:
        return 'fragile';
      case ParcelType.perishable:
        return 'perishable';
      case ParcelType.valuable:
        return 'valuable';
    }
  }

  static ParcelType fromString(String value) {
    switch (value) {
      case 'document':
        return ParcelType.document;
      case 'package':
        return ParcelType.package;
      case 'fragile':
        return ParcelType.fragile;
      case 'perishable':
        return ParcelType.perishable;
      case 'valuable':
        return ParcelType.valuable;
      default:
        return ParcelType.package;
    }
  }
}

enum PaymentMethod {
  cash,
  orangeMoney,
  wave,
  freeMoney;

  String get value {
    switch (this) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.orangeMoney:
        return 'orange_money';
      case PaymentMethod.wave:
        return 'wave';
      case PaymentMethod.freeMoney:
        return 'free_money';
    }
  }

  static PaymentMethod fromString(String value) {
    switch (value) {
      case 'cash':
        return PaymentMethod.cash;
      case 'orange_money':
        return PaymentMethod.orangeMoney;
      case 'wave':
        return PaymentMethod.wave;
      case 'free_money':
        return PaymentMethod.freeMoney;
      default:
        return PaymentMethod.cash;
    }
  }
}

// ==================== CLASSE BID (OFFRE) AVEC AUDIO ====================
class Bid {
  final String id;
  final String parcelId;
  final String driverId;
  final String driverName;
  final String driverPhone;
  final double price;
  final String? message;
  final BidStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? responseMessage;
  final String? audioUrl;

  Bid({
    required this.id,
    required this.parcelId,
    required this.driverId,
    required this.driverName,
    required this.driverPhone,
    required this.price,
    this.message,
    this.status = BidStatus.pending,
    required this.createdAt,
    this.respondedAt,
    this.responseMessage,
    this.audioUrl,
  });

  factory Bid.fromJson(Map<String, dynamic> json) {
    return Bid(
      id: json['id']?.toString() ?? '',
      parcelId: json['parcel_id']?.toString() ?? json['parcelId']?.toString() ?? '',
      driverId: json['driver_id']?.toString() ?? json['driverId']?.toString() ?? '',
      driverName: json['driver_name']?.toString() ?? json['driverName']?.toString() ?? '',
      driverPhone: json['driver_phone']?.toString() ?? json['driverPhone']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      message: json['message']?.toString(),
      status: json['status'] != null
          ? BidStatus.fromString(json['status'].toString())
          : BidStatus.pending,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : (json['createdAt'] != null
              ? DateTime.parse(json['createdAt'].toString())
              : DateTime.now()),
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'].toString())
          : (json['respondedAt'] != null
              ? DateTime.parse(json['respondedAt'].toString())
              : null),
      responseMessage: json['response_message']?.toString() ??
          json['responseMessage']?.toString(),
      audioUrl: json['audio_url']?.toString() ?? json['audioUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'parcel_id': parcelId,
    'driver_id': driverId,
    'driver_name': driverName,
    'driver_phone': driverPhone,
    'price': price,
    'message': message,
    'status': status.value,
    'created_at': createdAt.toIso8601String(),
    'responded_at': respondedAt?.toIso8601String(),
    'response_message': responseMessage,
    'audio_url': audioUrl,
  };

  bool get hasAudio => audioUrl != null && audioUrl!.isNotEmpty;
}

enum BidStatus {
  pending,
  accepted,
  rejected;

  String get value {
    switch (this) {
      case BidStatus.pending:
        return 'pending';
      case BidStatus.accepted:
        return 'accepted';
      case BidStatus.rejected:
        return 'rejected';
    }
  }

  static BidStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return BidStatus.pending;
      case 'accepted':
        return BidStatus.accepted;
      case 'rejected':
        return BidStatus.rejected;
      default:
        return BidStatus.pending;
    }
  }
}

// ==================== CLASSE PARCEL ====================
class Parcel {
  final String id;
  final String trackingNumber;
  final String senderId;
  final String senderName;
  final String senderPhone;
  final String? senderEmail;
  final String receiverName;
  final String receiverPhone;
  final String? receiverEmail;
  final String? receiverAddress;
  final String description;
  final double weight;
  final double? length;
  final double? width;
  final double? height;
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
  final double? deliveryFees;
  final double? totalAmount;
  final PaymentMethod? paymentMethod;
  final String? paymentPhoneNumber;
  final String? paymentStatus;
  final List<String> photoUrls;
  final List<String> videoUrls;
  final List<String> audioUrls;
  final String? signatureUrl;
  final bool isInsured;
  final double? insuranceAmount;
  final bool isUrgent;
  final double? urgentFee;
  final String? notes;
  final DateTime? pickupDate;
  final DateTime? deliveryDate;
  final DateTime? estimatedDeliveryDate;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? createdByName;
  final String? cancelledBy;
  final String? cancellationReason;
  final DateTime? cancelledAt;

  // ✅ CHAMPS POUR LE SCORE
  final bool scoreDebited;
  final bool scoreRefunded;

  // Champs pour le libre service (marchandage)
  final bool isFreeForBidding;
  final double? proposedPrice;
  final double? negotiatedPrice;
  final String? selectedBidId;
  final List<Bid> bids;

  Parcel({
    required this.id,
    required this.trackingNumber,
    required this.senderId,
    required this.senderName,
    required this.senderPhone,
    this.senderEmail,
    required this.receiverName,
    required this.receiverPhone,
    this.receiverEmail,
    this.receiverAddress,
    required this.description,
    required this.weight,
    this.length,
    this.width,
    this.height,
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
    this.deliveryFees,
    this.totalAmount,
    this.paymentMethod,
    this.paymentPhoneNumber,
    this.paymentStatus,
    this.photoUrls = const [],
    this.videoUrls = const [],
    this.audioUrls = const [],
    this.signatureUrl,
    this.isInsured = false,
    this.insuranceAmount,
    this.isUrgent = false,
    this.urgentFee,
    this.notes,
    this.pickupDate,
    this.deliveryDate,
    this.estimatedDeliveryDate,
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.createdByName,
    this.cancelledBy,
    this.cancellationReason,
    this.cancelledAt,
    // ✅ CHAMPS POUR LE SCORE
    this.scoreDebited = false,
    this.scoreRefunded = false,
    // Libre service
    this.isFreeForBidding = false,
    this.proposedPrice,
    this.negotiatedPrice,
    this.selectedBidId,
    this.bids = const [],
  });

  factory Parcel.fromJson(Map<String, dynamic> json) {
    // Récupérer les offres (bids)
    List<Bid> bids = [];
    if (json['bids'] != null && json['bids'] is List) {
      bids = (json['bids'] as List)
          .where((e) => e != null)
          .map((bid) => Bid.fromJson(bid as Map<String, dynamic>))
          .toList();
    }

    // Fonctions utilitaires
    String? parseString(dynamic value) => value?.toString();
    double? parseDouble(dynamic value) =>
        value != null ? (value is double ? value : double.tryParse(value.toString())) : null;
    DateTime? parseDateTime(dynamic value) =>
        value != null ? DateTime.tryParse(value.toString()) : null;

    List<String> parseList(dynamic value) {
      if (value == null) return [];
      if (value is List) return value.map((e) => e.toString()).toList();
      return [];
    }

    return Parcel(
      id: parseString(json['id']) ?? '',
      trackingNumber: parseString(json['tracking_number']) ?? '',
      senderId: parseString(json['sender_id']) ?? '',
      senderName: parseString(json['sender_name']) ?? '',
      senderPhone: parseString(json['sender_phone']) ?? '',
      senderEmail: parseString(json['sender_email']),
      receiverName: parseString(json['receiver_name']) ?? '',
      receiverPhone: parseString(json['receiver_phone']) ?? '',
      receiverEmail: parseString(json['receiver_email']),
      receiverAddress: parseString(json['receiver_address']),
      description: parseString(json['description']) ?? '',
      weight: parseDouble(json['weight']) ?? 0,
      length: parseDouble(json['length']),
      width: parseDouble(json['width']),
      height: parseDouble(json['height']),
      type: json['type'] != null
          ? ParcelType.fromString(parseString(json['type'])!)
          : ParcelType.package,
      status: json['status'] != null
          ? ParcelStatus.fromString(parseString(json['status'])!)
          : ParcelStatus.pending,
      departureGarageId: parseString(json['departure_garage_id']) ?? '',
      departureGarageName: parseString(json['departure_garage_name']) ?? '',
      arrivalGarageId: parseString(json['arrival_garage_id']),
      arrivalGarageName: parseString(json['arrival_garage_name']),
      driverId: parseString(json['driver_id']),
      driverName: parseString(json['driver_name']),
      driverPhone: parseString(json['driver_phone']),
      price: parseDouble(json['price']),
      deliveryFees: parseDouble(json['delivery_fees']),
      totalAmount: parseDouble(json['total_amount']),
      paymentMethod: json['payment_method'] != null
          ? PaymentMethod.fromString(parseString(json['payment_method'])!)
          : null,
      paymentPhoneNumber: parseString(json['payment_phone_number']),
      paymentStatus: parseString(json['payment_status']),
      photoUrls: parseList(json['photo_urls'] ?? json['photoUrls']),
      videoUrls: parseList(json['video_urls'] ?? json['videoUrls']),
      audioUrls: parseList(json['audio_urls'] ?? json['audioUrls']),
      signatureUrl: parseString(json['signature_url']),
      isInsured: json['is_insured'] ?? false,
      insuranceAmount: parseDouble(json['insurance_amount']),
      isUrgent: json['is_urgent'] ?? false,
      urgentFee: parseDouble(json['urgent_fee']),
      notes: parseString(json['notes']),
      pickupDate: parseDateTime(json['pickup_date']),
      deliveryDate: parseDateTime(json['delivery_date']),
      estimatedDeliveryDate: parseDateTime(json['estimated_delivery_date']),
      createdAt: parseDateTime(json['created_at']) ?? DateTime.now(),
      updatedAt: parseDateTime(json['updated_at']),
      createdBy: parseString(json['created_by']),
      createdByName: parseString(json['created_by_name']),
      cancelledBy: parseString(json['cancelled_by']),
      cancellationReason: parseString(json['cancellation_reason']),
      cancelledAt: parseDateTime(json['cancelled_at']),
      // ✅ CHAMPS POUR LE SCORE
      scoreDebited: json['score_debited'] ?? false,
      scoreRefunded: json['score_refunded'] ?? false,
      // Libre service
      isFreeForBidding: json['is_free_for_bidding'] ?? false,
      proposedPrice: parseDouble(json['proposed_price'] ?? json['proposedPrice']),
      negotiatedPrice: parseDouble(json['negotiated_price'] ?? json['negotiatedPrice']),
      selectedBidId: parseString(json['selected_bid_id'] ?? json['selectedBidId']),
      bids: bids,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tracking_number': trackingNumber,
    'sender_id': senderId,
    'sender_name': senderName,
    'sender_phone': senderPhone,
    'sender_email': senderEmail,
    'receiver_name': receiverName,
    'receiver_phone': receiverPhone,
    'receiver_email': receiverEmail,
    'receiver_address': receiverAddress,
    'description': description,
    'weight': weight,
    'length': length,
    'width': width,
    'height': height,
    'type': type.value,
    'status': status.value,
    'departure_garage_id': departureGarageId,
    'departure_garage_name': departureGarageName,
    'arrival_garage_id': arrivalGarageId,
    'arrival_garage_name': arrivalGarageName,
    'driver_id': driverId,
    'driver_name': driverName,
    'driver_phone': driverPhone,
    'price': price,
    'delivery_fees': deliveryFees,
    'total_amount': totalAmount,
    'payment_method': paymentMethod?.value,
    'payment_phone_number': paymentPhoneNumber,
    'payment_status': paymentStatus,
    'photo_urls': photoUrls,
    'video_urls': videoUrls,
    'audio_urls': audioUrls,
    'signature_url': signatureUrl,
    'is_insured': isInsured,
    'insurance_amount': insuranceAmount,
    'is_urgent': isUrgent,
    'urgent_fee': urgentFee,
    'notes': notes,
    'pickup_date': pickupDate?.toIso8601String(),
    'delivery_date': deliveryDate?.toIso8601String(),
    'estimated_delivery_date': estimatedDeliveryDate?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'created_by': createdBy,
    'created_by_name': createdByName,
    'cancelled_by': cancelledBy,
    'cancellation_reason': cancellationReason,
    'cancelled_at': cancelledAt?.toIso8601String(),
    // ✅ CHAMPS POUR LE SCORE
    'score_debited': scoreDebited,
    'score_refunded': scoreRefunded,
    // Libre service
    'is_free_for_bidding': isFreeForBidding,
    'proposed_price': proposedPrice,
    'negotiated_price': negotiatedPrice,
    'selected_bid_id': selectedBidId,
    'bids': bids.map((b) => b.toJson()).toList(),
  };

  // ==================== PROPRIÉTÉS CALCULÉES ====================

  bool get hasBids => bids.isNotEmpty;
  int get bidsCount => bids.length;
  bool get hasAudio => audioUrls.isNotEmpty;
  int get audioCount => audioUrls.length;

  Bid? get bestBid {
    if (bids.isEmpty) return null;
    return bids.reduce((a, b) => a.price > b.price ? a : b);
  }

  Bid? get selectedBid {
    if (selectedBidId == null) return null;
    try {
      return bids.firstWhere((b) => b.id == selectedBidId);
    } catch (e) {
      return null;
    }
  }

  List<Bid> get pendingBids => bids.where((b) => b.status == BidStatus.pending).toList();
  List<Bid> get acceptedBids => bids.where((b) => b.status == BidStatus.accepted).toList();
  List<Bid> get rejectedBids => bids.where((b) => b.status == BidStatus.rejected).toList();

  // ✅ PROPRIÉTÉS POUR LE SCORE
  bool get isScoreDebited => scoreDebited;
  bool get isScoreRefunded => scoreRefunded;
}

// ==================== CLASSE PARCEL EVENT ====================
class ParcelEvent {
  final String id;
  final String parcelId;
  final ParcelStatus status;
  final String description;
  final String? location;
  final String? locationLat;
  final String? locationLng;
  final String? userId;
  final String? userName;
  final String? userRole;
  final String? photoUrl;
  final DateTime timestamp;

  ParcelEvent({
    required this.id,
    required this.parcelId,
    required this.status,
    required this.description,
    this.location,
    this.locationLat,
    this.locationLng,
    this.userId,
    this.userName,
    this.userRole,
    this.photoUrl,
    required this.timestamp,
  });

  factory ParcelEvent.fromJson(Map<String, dynamic> json) {
    return ParcelEvent(
      id: json['id']?.toString() ?? '',
      parcelId: json['parcel_id']?.toString() ?? json['parcelId']?.toString() ?? '',
      status: json['status'] != null
          ? ParcelStatus.fromString(json['status'].toString())
          : ParcelStatus.pending,
      description: json['description']?.toString() ?? '',
      location: json['location']?.toString(),
      locationLat: json['location_lat']?.toString() ?? json['locationLat']?.toString(),
      locationLng: json['location_lng']?.toString() ?? json['locationLng']?.toString(),
      userId: json['user_id']?.toString() ?? json['userId']?.toString(),
      userName: json['user_name']?.toString() ?? json['userName']?.toString(),
      userRole: json['user_role']?.toString() ?? json['userRole']?.toString(),
      photoUrl: json['photo_url']?.toString() ?? json['photoUrl']?.toString(),
      timestamp: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : (json['timestamp'] != null
              ? DateTime.parse(json['timestamp'].toString())
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'parcel_id': parcelId,
    'status': status.value,
    'description': description,
    'location': location,
    'location_lat': locationLat,
    'location_lng': locationLng,
    'user_id': userId,
    'user_name': userName,
    'user_role': userRole,
    'photo_url': photoUrl,
    'created_at': timestamp.toIso8601String(),
  };
}