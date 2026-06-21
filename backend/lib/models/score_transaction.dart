// lib/models/score_transaction.dart
class ScoreTransaction {
  final String id;
  final String userId;
  final int amount;
  final String type;
  final String? parcelId;
  final String description;
  String status;
  final Map<String, dynamic>? metadata;
  int balanceAfter;
  final DateTime createdAt;
  final String? reference;

  ScoreTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    this.parcelId,
    required this.description,
    this.status = 'completed',
    this.metadata,
    this.balanceAfter = 0,
    DateTime? createdAt,
    this.reference,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ScoreTransaction.fromJson(Map<String, dynamic> json) {
    return ScoreTransaction(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      amount: json['amount'] ?? 0,
      type: json['type']?.toString() ?? '',
      parcelId: json['parcelId']?.toString(),
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'completed',
      metadata: json['metadata'] as Map<String, dynamic>?,
      balanceAfter: json['balanceAfter'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      reference: json['reference']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'type': type,
      'parcelId': parcelId,
      'description': description,
      'status': status,
      'metadata': metadata,
      'balanceAfter': balanceAfter,
      'createdAt': createdAt.toIso8601String(),
      'reference': reference,
    };
  }

  Map<String, dynamic> toHistory() {
    return {
      'id': id,
      'amount': amount,
      'type': type,
      'description': description,
      'reference': reference,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'balanceAfter': balanceAfter,
    };
  }
}