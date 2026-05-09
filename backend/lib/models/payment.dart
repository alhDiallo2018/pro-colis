// backend/lib/models/payment.dart
class Payment {
  final String id;
  final String userId;
  final String? parcelId;
  final double amount;
  final String currency;
  final PaymentMethod method;
  final PaymentStatus status;
  final String? transactionId;
  final String? phoneNumber;
  final String? reference;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? completedAt;

  Payment({
    required this.id,
    required this.userId,
    this.parcelId,
    required this.amount,
    this.currency = 'XOF',
    required this.method,
    required this.status,
    this.transactionId,
    this.phoneNumber,
    this.reference,
    this.metadata,
    required this.createdAt,
    this.completedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'parcelId': parcelId,
    'amount': amount,
    'currency': currency,
    'method': method.name,
    'status': status.name,
    'transactionId': transactionId,
    'phoneNumber': phoneNumber,
    'reference': reference,
    'metadata': metadata,
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
  };
}

enum PaymentMethod {
  wave('Wave'),
  orangeMoney('Orange Money'),
  card('Carte Bancaire'),
  cash('Espèces');

  final String label;
  const PaymentMethod(this.label);
}

enum PaymentStatus {
  pending('En attente'),
  processing('En cours'),
  completed('Complété'),
  failed('Échoué'),
  refunded('Remboursé');

  final String label;
  const PaymentStatus(this.label);
}