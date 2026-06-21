// lib/services/score_service.dart
// ignore_for_file: unused_import

import 'dart:convert';

import 'package:procolis_backend/config/constants.dart';
import 'package:procolis_backend/models/parcel.dart';
import 'package:procolis_backend/models/score.dart';
import 'package:procolis_backend/models/score_transaction.dart';
import 'package:procolis_backend/services/database_service.dart';

// ✅ AJOUTER LA CLASSE DATABASE
class Database {
  static final Map<String, Score> scores = {};
  static final Map<String, ScoreTransaction> transactions = {};
  static final Map<String, Parcel> parcels = {};
  static int transactionCounter = 0;
}

class ScoreService {
  /// Initialiser les scores depuis la base de données PostgreSQL
  static Future<void> initializeScoresFromDatabase() async {
    try {
      print('🔄 Initialisation des scores depuis la base de données...');
      
      final db = await DatabaseService.getInstance();
      
      // Récupérer tous les scores avec les utilisateurs
      final result = await db.connection.execute('''
        SELECT 
          s.user_id,
          s.points,
          s.total_earned,
          s.total_spent,
          s.last_updated,
          s.created_at
        FROM scores s
        JOIN users u ON u.id = s.user_id
        WHERE u.status = 'active'
      ''');
      
      print('📊 ${result.length} scores trouvés en base de données');
      
      // Charger les scores en mémoire
      for (final row in result) {
        final userId = row[0].toString();
        final points = (row[1] as int?) ?? 0;
        final totalEarned = (row[2] as int?) ?? 0;
        final totalSpent = (row[3] as int?) ?? 0;
        final lastUpdated = row[4] as DateTime? ?? DateTime.now();
        final createdAt = row[5] as DateTime? ?? DateTime.now();
        
        final score = Score(
          userId: userId,
          points: points,
          totalEarned: totalEarned,
          totalSpent: totalSpent,
          lastUpdated: lastUpdated,
          createdAt: createdAt,
        );
        
        Database.scores[userId] = score;
        print('✅ Score chargé pour user: $userId, points: $points');
      }
      
      // Récupérer les transactions
      final transactionResult = await db.connection.execute('''
        SELECT 
          id,
          user_id,
          amount,
          type,
          parcel_id,
          description,
          status,
          reference,
          metadata,
          balance_after,
          created_at
        FROM score_transactions
        ORDER BY created_at DESC
      ''');
      
      print('📊 ${transactionResult.length} transactions trouvées en base de données');
      
      // Charger les transactions en mémoire
      for (final row in transactionResult) {
        final transaction = ScoreTransaction(
          id: row[0].toString(),
          userId: row[1].toString(),
          amount: (row[2] as int?) ?? 0,
          type: row[3].toString(),
          parcelId: row[4]?.toString(),
          description: row[5].toString(),
          status: row[6]?.toString() ?? 'completed',
          reference: row[7]?.toString(),
          metadata: row[8] != null ? jsonDecode(row[8].toString()) : null,
          balanceAfter: (row[9] as int?) ?? 0,
          createdAt: row[10] as DateTime? ?? DateTime.now(),
        );
        
        Database.transactions[transaction.id] = transaction;
      }
      
      print('✅ Initialisation des scores terminée avec succès !');
      print('📊 ${Database.scores.length} scores en mémoire');
      print('📊 ${Database.transactions.length} transactions en mémoire');
      
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation des scores: $e');
      rethrow;
    }
  }

  /// Charger un score depuis la base de données pour un utilisateur spécifique
  static Future<void> _loadScoreFromDatabase(String userId) async {
    try {
      final db = await DatabaseService.getInstance();
      
      // Charger le score
      final scoreResult = await db.connection.execute('''
        SELECT points, total_earned, total_spent, last_updated, created_at
        FROM scores
        WHERE user_id = \$1
      ''', parameters: [userId]);
      
      if (scoreResult.isNotEmpty) {
        final row = scoreResult.first;
        final score = Score(
          userId: userId,
          points: (row[0] as int?) ?? 0,
          totalEarned: (row[1] as int?) ?? 0,
          totalSpent: (row[2] as int?) ?? 0,
          lastUpdated: row[3] as DateTime? ?? DateTime.now(),
          createdAt: row[4] as DateTime? ?? DateTime.now(),
        );
        Database.scores[userId] = score;
        
        // Charger les transactions
        final transactionResult = await db.connection.execute('''
          SELECT id, amount, type, parcel_id, description, status, reference,
                 metadata, balance_after, created_at
          FROM score_transactions
          WHERE user_id = \$1
          ORDER BY created_at DESC
        ''', parameters: [userId]);
        
        for (final rowT in transactionResult) {
          final transaction = ScoreTransaction(
            id: rowT[0].toString(),
            userId: userId,
            amount: (rowT[1] as int?) ?? 0,
            type: rowT[2].toString(),
            parcelId: rowT[3]?.toString(),
            description: rowT[4].toString(),
            status: rowT[5]?.toString() ?? 'completed',
            reference: rowT[6]?.toString(),
            metadata: rowT[7] != null ? jsonDecode(rowT[7].toString()) : null,
            balanceAfter: (rowT[8] as int?) ?? 0,
            createdAt: rowT[9] as DateTime? ?? DateTime.now(),
          );
          Database.transactions[transaction.id] = transaction;
        }
        
        print('✅ Score chargé pour user: $userId, points: ${score.points}');
      } else {
        // Si l'utilisateur n'a pas de score, le créer
        await getOrCreateScore(userId);
      }
    } catch (e) {
      print('❌ Erreur chargement score pour user $userId: $e');
      rethrow;
    }
  }

  /// Créer ou récupérer le score d'un utilisateur
  static Future<Score> getOrCreateScore(String userId) async {
    // Vérifier d'abord en mémoire
    if (Database.scores.containsKey(userId)) {
      return Database.scores[userId]!;
    }

    // Vérifier en base de données
    try {
      final db = await DatabaseService.getInstance();
      final result = await db.connection.execute('''
        SELECT points, total_earned, total_spent, last_updated, created_at
        FROM scores
        WHERE user_id = \$1
      ''', parameters: [userId]);

      if (result.isNotEmpty) {
        final row = result.first;
        final score = Score(
          userId: userId,
          points: (row[0] as int?) ?? 0,
          totalEarned: (row[1] as int?) ?? 0,
          totalSpent: (row[2] as int?) ?? 0,
          lastUpdated: row[3] as DateTime? ?? DateTime.now(),
          createdAt: row[4] as DateTime? ?? DateTime.now(),
        );
        Database.scores[userId] = score;
        return score;
      }
    } catch (e) {
      print('⚠️ Erreur vérification score en base: $e');
    }

    // Créer un nouveau score avec bonus de bienvenue
    final score = Score(
      userId: userId,
      points: AppConstants.welcomeBonusPoints,
      totalEarned: AppConstants.welcomeBonusPoints,
      totalSpent: 0,
    );

    Database.scores[userId] = score;

    // Sauvegarder en base de données
    try {
      final db = await DatabaseService.getInstance();
      await db.connection.execute('''
        INSERT INTO scores (user_id, points, total_earned, total_spent)
        VALUES (\$1, \$2, \$3, \$4)
      ''', parameters: [
        userId,
        AppConstants.welcomeBonusPoints,
        AppConstants.welcomeBonusPoints,
        0
      ]);

      // Créer la transaction de bienvenue en base
      await db.connection.execute('''
        INSERT INTO score_transactions (
          user_id, amount, type, description, balance_after
        ) VALUES (\$1, \$2, \$3, \$4, \$5)
      ''', parameters: [
        userId,
        AppConstants.welcomeBonusPoints,
        AppConstants.transactionTypeBonus,
        '🎉 Bonus de bienvenue',
        AppConstants.welcomeBonusPoints
      ]);

      print('✅ Score créé pour user: $userId avec bonus de bienvenue');
    } catch (e) {
      print('⚠️ Erreur sauvegarde score en base: $e');
    }

    // Créer la transaction en mémoire
    await createTransaction(
      userId: userId,
      amount: AppConstants.welcomeBonusPoints,
      type: AppConstants.transactionTypeBonus,
      description: '🎉 Bonus de bienvenue',
      balanceAfter: AppConstants.welcomeBonusPoints,
    );

    return score;
  }

  /// Récupérer le score d'un utilisateur avec ses transactions
  static Future<Map<String, dynamic>> getUserScore(
    String userId, {
    int page = 1,
    int limit = 20,
  }) async {
    // Charger le score depuis la base si pas en mémoire
    if (!Database.scores.containsKey(userId)) {
      await _loadScoreFromDatabase(userId);
    }
    
    final score = Database.scores[userId];
    if (score == null) {
      // Créer le score s'il n'existe pas
      await getOrCreateScore(userId);
      final newScore = Database.scores[userId];
      return {
        'score': newScore?.toJson(),
        'transactions': [],
        'pagination': {
          'page': page,
          'limit': limit,
          'total': 0,
          'pages': 0,
        },
      };
    }

    final allTransactions = Database.transactions.values
        .where((t) => t.userId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final skip = (page - 1) * limit;
    final paginated = allTransactions.skip(skip).take(limit).toList();

    return {
      'score': score.toJson(),
      'transactions': paginated.map((t) => t.toHistory()).toList(),
      'pagination': {
        'page': page,
        'limit': limit,
        'total': allTransactions.length,
        'pages': (allTransactions.length / limit).ceil(),
      },
    };
  }

  /// Débiter des points d'un utilisateur
  static Future<Map<String, dynamic>> debitPoints({
    required String userId,
    required int amount,
    required String type,
    String? parcelId,
    required String description,
    Map<String, dynamic> metadata = const {},
  }) async {
    if (amount <= 0) {
      throw Exception('Le montant du débit doit être supérieur à 0');
    }

    // Charger le score depuis la base si pas en mémoire
    if (!Database.scores.containsKey(userId)) {
      await _loadScoreFromDatabase(userId);
    }

    final score = Database.scores[userId];
    if (score == null) {
      throw Exception('Score non trouvé pour cet utilisateur');
    }

    if (!score.hasEnoughPoints(amount)) {
      throw Exception('Points insuffisants. Solde: ${score.points}, requis: $amount');
    }

    // Débiter les points
    score.debit(amount);

    // Créer la transaction
    final transaction = ScoreTransaction(
      id: 'txn_${DateTime.now().millisecondsSinceEpoch}_${++Database.transactionCounter}',
      userId: userId,
      amount: -amount,
      type: type,
      parcelId: parcelId,
      description: description,
      status: AppConstants.transactionStatusCompleted,
      metadata: metadata,
      balanceAfter: score.points,
      createdAt: DateTime.now(),
    );

    Database.transactions[transaction.id] = transaction;

    // Sauvegarder en base de données
    try {
      final db = await DatabaseService.getInstance();
      
      // Mettre à jour le score
      await db.connection.execute('''
        UPDATE scores 
        SET points = \$2, total_spent = total_spent + \$3, last_updated = NOW()
        WHERE user_id = \$1
      ''', parameters: [userId, score.points, amount]);

      // Créer la transaction
      await db.connection.execute('''
        INSERT INTO score_transactions (
          user_id, amount, type, parcel_id, description, balance_after
        ) VALUES (\$1, \$2, \$3, \$4, \$5, \$6)
      ''', parameters: [
        userId,
        -amount,
        type,
        parcelId,
        description,
        score.points
      ]);

      // Si c'est une transaction de création de colis, marquer le colis
      if (parcelId != null && type == AppConstants.transactionTypeParcelCreation) {
        await db.connection.execute('''
          UPDATE parcels SET score_debited = true WHERE id = \$1
        ''', parameters: [parcelId]);
      }

      print('✅ Débit de $amount points pour user: $userId, nouveau solde: ${score.points}');
    } catch (e) {
      print('⚠️ Erreur sauvegarde débit en base: $e');
      // Rollback en mémoire
      score.credit(amount);
      Database.transactions.remove(transaction.id);
      throw Exception('Erreur lors de la sauvegarde en base de données');
    }

    return {
      'success': true,
      'newBalance': score.points,
      'transaction': transaction.toHistory(),
    };
  }

  /// Créditer des points à un utilisateur
  static Future<Map<String, dynamic>> creditPoints({
    required String userId,
    required int amount,
    required String type,
    String? parcelId,
    required String description,
    Map<String, dynamic> metadata = const {},
  }) async {
    if (amount <= 0) {
      throw Exception('Le montant du crédit doit être supérieur à 0');
    }

    // Charger le score depuis la base si pas en mémoire
    if (!Database.scores.containsKey(userId)) {
      await _loadScoreFromDatabase(userId);
    }

    var score = Database.scores[userId];
    if (score == null) {
      // Créer un nouveau score
      score = await getOrCreateScore(userId);
    }

    // Créditer les points
    score.credit(amount);

    // Créer la transaction
    final transaction = ScoreTransaction(
      id: 'txn_${DateTime.now().millisecondsSinceEpoch}_${++Database.transactionCounter}',
      userId: userId,
      amount: amount,
      type: type,
      parcelId: parcelId,
      description: description,
      status: AppConstants.transactionStatusCompleted,
      metadata: metadata,
      balanceAfter: score.points,
      createdAt: DateTime.now(),
    );

    Database.transactions[transaction.id] = transaction;

    // Sauvegarder en base de données
    try {
      final db = await DatabaseService.getInstance();
      
      // Mettre à jour le score
      await db.connection.execute('''
        INSERT INTO scores (user_id, points, total_earned) 
        VALUES (\$1, \$2, \$3)
        ON CONFLICT (user_id) 
        DO UPDATE SET 
          points = scores.points + \$2, 
          total_earned = scores.total_earned + \$3,
          last_updated = NOW()
      ''', parameters: [userId, amount, amount]);

      // Créer la transaction
      await db.connection.execute('''
        INSERT INTO score_transactions (
          user_id, amount, type, parcel_id, description, balance_after
        ) VALUES (\$1, \$2, \$3, \$4, \$5, \$6)
      ''', parameters: [
        userId,
        amount,
        type,
        parcelId,
        description,
        score.points
      ]);

      print('✅ Crédit de $amount points pour user: $userId, nouveau solde: ${score.points}');
    } catch (e) {
      print('⚠️ Erreur sauvegarde crédit en base: $e');
      // Rollback en mémoire
      score.debit(amount);
      Database.transactions.remove(transaction.id);
      throw Exception('Erreur lors de la sauvegarde en base de données');
    }

    return {
      'success': true,
      'newBalance': score.points,
      'transaction': transaction.toHistory(),
    };
  }

  /// Créer une transaction (sans modifier le solde)
  static Future<Map<String, dynamic>> createTransaction({
    required String userId,
    required int amount,
    required String type,
    String? parcelId,
    required String description,
    String status = AppConstants.transactionStatusCompleted,
    Map<String, dynamic> metadata = const {},
    int balanceAfter = 0,
  }) async {
    final transaction = ScoreTransaction(
      id: 'txn_${DateTime.now().millisecondsSinceEpoch}_${++Database.transactionCounter}',
      userId: userId,
      amount: amount,
      type: type,
      parcelId: parcelId,
      description: description,
      status: status,
      metadata: metadata,
      balanceAfter: balanceAfter,
      createdAt: DateTime.now(),
    );

    Database.transactions[transaction.id] = transaction;

    // Sauvegarder en base de données
    try {
      final db = await DatabaseService.getInstance();
      await db.connection.execute('''
        INSERT INTO score_transactions (
          user_id, amount, type, parcel_id, description, status, 
          metadata, balance_after
        ) VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8)
      ''', parameters: [
        userId,
        amount,
        type,
        parcelId,
        description,
        status,
        jsonEncode(metadata),
        balanceAfter
      ]);
    } catch (e) {
      print('⚠️ Erreur sauvegarde transaction en base: $e');
    }

    return transaction.toHistory();
  }

  /// Vérifier si un utilisateur a assez de points
  static Future<bool> hasEnoughPoints(String userId, int requiredPoints) async {
    // Charger le score depuis la base si pas en mémoire
    if (!Database.scores.containsKey(userId)) {
      await _loadScoreFromDatabase(userId);
    }
    
    final score = Database.scores[userId];
    if (score == null) return false;
    return score.hasEnoughPoints(requiredPoints);
  }

  /// Obtenir le solde d'un utilisateur
  static Future<int> getBalance(String userId) async {
    // Charger le score depuis la base si pas en mémoire
    if (!Database.scores.containsKey(userId)) {
      await _loadScoreFromDatabase(userId);
    }
    
    final score = Database.scores[userId];
    return score?.points ?? 0;
  }

  /// Rembourser une transaction (admin seulement)
  static Future<Map<String, dynamic>> refundTransaction({
    required String userId,
    required String transactionId,
    String reason = 'Remboursement administratif',
  }) async {
    final transaction = Database.transactions[transactionId];

    if (transaction == null) {
      throw Exception('Transaction non trouvée');
    }

    if (transaction.userId != userId) {
      throw Exception('Transaction non trouvée pour cet utilisateur');
    }

    if (transaction.status == AppConstants.transactionStatusRefunded) {
      throw Exception('Cette transaction a déjà été remboursée');
    }

    if (transaction.amount >= 0) {
      throw Exception('Seules les transactions de débit peuvent être remboursées');
    }

    final amount = transaction.amount.abs();
    
    // Charger le score depuis la base si pas en mémoire
    if (!Database.scores.containsKey(userId)) {
      await _loadScoreFromDatabase(userId);
    }
    
    final score = Database.scores[userId];
    if (score == null) {
      throw Exception('Score non trouvé');
    }

    // Rembourser les points
    score.credit(amount);

    // Marquer la transaction originale comme remboursée
    transaction.status = AppConstants.transactionStatusRefunded;

    // Créer la transaction de remboursement
    final refundTransaction = ScoreTransaction(
      id: 'txn_${DateTime.now().millisecondsSinceEpoch}_${++Database.transactionCounter}',
      userId: userId,
      amount: amount,
      type: AppConstants.transactionTypeRefund,
      parcelId: transaction.parcelId,
      description: '$reason - ${transaction.description}',
      status: AppConstants.transactionStatusCompleted,
      metadata: {
        'refundedTransactionId': transactionId,
        'originalAmount': transaction.amount,
        'reason': reason,
      },
      balanceAfter: score.points,
      createdAt: DateTime.now(),
    );

    Database.transactions[refundTransaction.id] = refundTransaction;

    // Sauvegarder en base de données
    try {
      final db = await DatabaseService.getInstance();
      
      // Mettre à jour le score
      await db.connection.execute('''
        UPDATE scores 
        SET points = \$2, total_spent = total_spent - \$3, last_updated = NOW()
        WHERE user_id = \$1
      ''', parameters: [userId, score.points, amount]);

      // Mettre à jour la transaction originale
      await db.connection.execute('''
        UPDATE score_transactions 
        SET status = 'refunded', updated_at = NOW()
        WHERE id = \$1
      ''', parameters: [transactionId]);

      // Créer la transaction de remboursement
      await db.connection.execute('''
        INSERT INTO score_transactions (
          user_id, amount, type, parcel_id, description, 
          status, metadata, balance_after
        ) VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8)
      ''', parameters: [
        userId,
        amount,
        AppConstants.transactionTypeRefund,
        transaction.parcelId,
        '$reason - ${transaction.description}',
        'completed',
        jsonEncode({
          'refundedTransactionId': transactionId,
          'originalAmount': transaction.amount,
          'reason': reason,
        }),
        score.points
      ]);

      // Si c'était une transaction de création de colis, marquer le remboursement
      if (transaction.parcelId != null && 
          transaction.type == AppConstants.transactionTypeParcelCreation) {
        await db.connection.execute('''
          UPDATE parcels SET score_refunded = true WHERE id = \$1
        ''', parameters: [transaction.parcelId]);
      }

      print('✅ Remboursement effectué pour user: $userId, montant: $amount');
    } catch (e) {
      print('⚠️ Erreur sauvegarde remboursement en base: $e');
      // Rollback en mémoire
      score.debit(amount);
      transaction.status = AppConstants.transactionStatusCompleted;
      Database.transactions.remove(refundTransaction.id);
      throw Exception('Erreur lors de la sauvegarde en base de données');
    }

    return {
      'success': true,
      'newBalance': score.points,
      'refundTransaction': refundTransaction.toHistory(),
    };
  }

  /// Obtenir les statistiques des points
  static Future<Map<String, dynamic>> getStats() async {
    final scores = Database.scores.values.toList();
    final totalUsers = scores.length;
    final totalPoints = scores.fold(0, (sum, s) => sum + s.points);
    final totalEarned = scores.fold(0, (sum, s) => sum + s.totalEarned);
    final totalSpent = scores.fold(0, (sum, s) => sum + s.totalSpent);
    final avgPoints = totalUsers > 0 ? totalPoints / totalUsers : 0;

    // Top 10 utilisateurs
    final topUsers = scores
        .map((s) => {
              'userId': s.userId,
              'points': s.points,
              'totalEarned': s.totalEarned,
              'totalSpent': s.totalSpent,
            })
        .toList()
      ..sort((a, b) => (b['points'] as int).compareTo(a['points'] as int))
      ..take(10);

    return {
      'totalUsers': totalUsers,
      'totalPoints': totalPoints,
      'averagePoints': avgPoints,
      'totalEarned': totalEarned,
      'totalSpent': totalSpent,
      'topUsers': topUsers,
    };
  }

  /// Traiter le débit pour un colis
  static Future<Map<String, dynamic>> processParcelCreation(
    String userId,
    String parcelId,
    String trackingNumber,
  ) {
    return debitPoints(
      userId: userId,
      amount: AppConstants.parcelCreationPoints,
      type: AppConstants.transactionTypeParcelCreation,
      parcelId: parcelId,
      description: 'Création du colis #$trackingNumber',
    );
  }

  /// Traiter le débit pour l'acceptation d'un colis (chauffeur)
  static Future<Map<String, dynamic>> processParcelAcceptance(
    String userId,
    String parcelId,
    String trackingNumber,
  ) {
    return debitPoints(
      userId: userId,
      amount: AppConstants.parcelAcceptancePoints,
      type: AppConstants.transactionTypeParcelAcceptance,
      parcelId: parcelId,
      description: 'Acceptation du colis #$trackingNumber',
    );
  }

  /// Traiter le débit pour la livraison d'un colis (chauffeur)
  static Future<Map<String, dynamic>> processParcelDelivery(
    String userId,
    String parcelId,
    String trackingNumber,
  ) {
    return debitPoints(
      userId: userId,
      amount: AppConstants.parcelDeliveryPoints,
      type: AppConstants.transactionTypeParcelDelivery,
      parcelId: parcelId,
      description: 'Livraison du colis #$trackingNumber',
    );
  }

  /// Traiter l'achat de points
  static Future<Map<String, dynamic>> processPurchase(
    String userId,
    int amount,
    String paymentMethod,
    String? paymentReference,
  ) {
    return creditPoints(
      userId: userId,
      amount: amount,
      type: AppConstants.transactionTypePurchase,
      description: 'Achat de $amount points ($paymentMethod)',
      metadata: {
        'paymentMethod': paymentMethod,
        'paymentReference': paymentReference,
        'purchaseDate': DateTime.now().toIso8601String(),
      },
    );
  }
}