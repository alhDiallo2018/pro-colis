// lib/models/score.dart
import 'package:procolis_backend/models/score_transaction.dart';

class Score {
  final String userId;
  int points;
  int totalEarned;
  int totalSpent;
  DateTime lastUpdated;
  DateTime createdAt;
  List<ScoreTransaction>? transactions;

  Score({
    required this.userId,
    this.points = 0,
    this.totalEarned = 0,
    this.totalSpent = 0,
    DateTime? lastUpdated,
    DateTime? createdAt,
    this.transactions,
  })  : lastUpdated = lastUpdated ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  factory Score.fromJson(Map<String, dynamic> json) {
    return Score(
      userId: json['userId']?.toString() ?? '',
      points: json['points'] ?? 0,
      totalEarned: json['totalEarned'] ?? 0,
      totalSpent: json['totalSpent'] ?? 0,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      transactions: json['transactions'] != null
          ? (json['transactions'] as List)
              .map((t) => ScoreTransaction.fromJson(t))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'points': points,
      'totalEarned': totalEarned,
      'totalSpent': totalSpent,
      'lastUpdated': lastUpdated.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'transactions': transactions?.map((t) => t.toJson()).toList(),
    };
  }

  Score copyWith({
    String? userId,
    int? points,
    int? totalEarned,
    int? totalSpent,
    DateTime? lastUpdated,
    DateTime? createdAt,
    List<ScoreTransaction>? transactions,
  }) {
    return Score(
      userId: userId ?? this.userId,
      points: points ?? this.points,
      totalEarned: totalEarned ?? this.totalEarned,
      totalSpent: totalSpent ?? this.totalSpent,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      createdAt: createdAt ?? this.createdAt,
      transactions: transactions ?? this.transactions,
    );
  }

  bool hasEnoughPoints(int requiredPoints) {
    return points >= requiredPoints;
  }

  void debit(int amount) {
    if (points < amount) {
      throw Exception('Points insuffisants. Solde: $points, requis: $amount');
    }
    points -= amount;
    totalSpent += amount;
  }

  void credit(int amount) {
    points += amount;
    totalEarned += amount;
  }
}