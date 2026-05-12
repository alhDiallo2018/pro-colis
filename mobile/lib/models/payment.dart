import 'package:flutter/material.dart';

enum PaymentMethod {
  wave('wave', 'Wave', Icons.waves),
  orangeMoney('orange_money', 'Orange Money', Icons.phone_android),
  card('card', 'Carte Bancaire', Icons.credit_card),
  cash('cash', 'Espèces', Icons.money);

  final String value;
  final String label;
  final IconData icon;
  const PaymentMethod(this.value, this.label, this.icon);

  static PaymentMethod fromString(String value) {
    return PaymentMethod.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PaymentMethod.cash,
    );
  }
}

enum PaymentStatus {
  pending('pending', 'En attente'),
  processing('processing', 'En cours'),
  completed('completed', 'Payé'),
  failed('failed', 'Échoué'),
  refunded('refunded', 'Remboursé');

  final String value;
  final String label;
  const PaymentStatus(this.value, this.label);
}

class Payment {
  final String id;
  final String userId;
  final String? parcelId;
  final double amount;
  final PaymentMethod method;
  final PaymentStatus status;
  final String? transactionId;
  final String? phoneNumber;
  final DateTime createdAt;
  final DateTime? completedAt;

  Payment({
    required this.id,
    required this.userId,
    this.parcelId,
    required this.amount,
    required this.method,
    required this.status,
    this.transactionId,
    this.phoneNumber,
    required this.createdAt,
    this.completedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      userId: json['userId'],
      parcelId: json['parcelId'],
      amount: json['amount'].toDouble(),
      method: PaymentMethod.fromString(json['method']),
      status: PaymentStatus.values.firstWhere(
        (e) => e.value == json['status'],
        orElse: () => PaymentStatus.pending,
      ),
      transactionId: json['transactionId'],
      phoneNumber: json['phoneNumber'],
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
    );
  }
}