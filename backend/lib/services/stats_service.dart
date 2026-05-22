// lib/services/stats_service.dart
import '../utils/db_helper.dart';

class StatsService {
  Future<Map<String, dynamic>> getGlobalStats() async {
    final db = await DbHelper.getInstance();
    
    try {
      final userCount = await db.connection.execute('SELECT COUNT(*) FROM users');
      final driverCount = await db.connection.execute('SELECT COUNT(*) FROM users WHERE role = \'driver\'');
      final garageCount = await db.connection.execute('SELECT COUNT(*) FROM garages');
      final parcelCount = await db.connection.execute('SELECT COUNT(*) FROM parcels');
      final deliveredCount = await db.connection.execute('SELECT COUNT(*) FROM parcels WHERE status = \'delivered\'');
      final revenueResult = await db.connection.execute('SELECT COALESCE(SUM(price), 0) FROM parcels WHERE status = \'delivered\'');
      
      return {
        'totalUsers': userCount.first[0],
        'totalDrivers': driverCount.first[0],
        'totalGarages': garageCount.first[0],
        'totalParcels': parcelCount.first[0],
        'deliveredParcels': deliveredCount.first[0],
        'totalRevenue': revenueResult.first[0],
      };
    } catch (e) {
      print('❌ Erreur getGlobalStats: $e');
      return {
        'totalUsers': 0,
        'totalDrivers': 0,
        'totalGarages': 0,
        'totalParcels': 0,
        'deliveredParcels': 0,
        'totalRevenue': 0,
      };
    }
  }
  
  Future<Map<String, dynamic>> getAdvancedStats() async {
    final db = await DbHelper.getInstance();
    
    try {
      // Colis par statut
      final statusResult = await db.connection.execute('''
        SELECT status, COUNT(*) FROM parcels GROUP BY status
      ''');
      
      final statusCounts = <String, int>{};
      for (var row in statusResult) {
        statusCounts[row[0].toString()] = row[1] as int;
      }
      
      // Colis par mois (12 derniers mois)
      final monthlyResult = await db.connection.execute('''
        SELECT DATE_TRUNC('month', created_at) as month, COUNT(*)
        FROM parcels 
        WHERE created_at >= NOW() - INTERVAL '12 months'
        GROUP BY month ORDER BY month DESC
      ''');
      
      final monthlyCounts = <Map<String, dynamic>>[];
      for (var row in monthlyResult) {
        monthlyCounts.add({
          'month': (row[0] as DateTime).toIso8601String(),
          'count': row[1],
        });
      }
      
      // Revenus par mois
      final revenueMonthlyResult = await db.connection.execute('''
        SELECT DATE_TRUNC('month', created_at) as month, COALESCE(SUM(price), 0)
        FROM parcels 
        WHERE status = 'delivered' AND created_at >= NOW() - INTERVAL '12 months'
        GROUP BY month ORDER BY month DESC
      ''');
      
      final revenueMonthly = <Map<String, dynamic>>[];
      for (var row in revenueMonthlyResult) {
        revenueMonthly.add({
          'month': (row[0] as DateTime).toIso8601String(),
          'revenue': row[1],
        });
      }
      
      // Top 5 garages par chiffre d'affaires
      final topGaragesResult = await db.connection.execute('''
        SELECT g.name, COALESCE(SUM(p.price), 0) as revenue
        FROM garages g
        LEFT JOIN parcels p ON p.departure_garage_id = g.id AND p.status = 'delivered'
        GROUP BY g.id, g.name
        ORDER BY revenue DESC
        LIMIT 5
      ''');
      
      final topGarages = <Map<String, dynamic>>[];
      for (var row in topGaragesResult) {
        topGarages.add({
          'name': row[0],
          'revenue': row[1],
        });
      }
      
      return {
        'statusDistribution': statusCounts,
        'monthlyTrends': monthlyCounts,
        'monthlyRevenue': revenueMonthly,
        'topGarages': topGarages,
      };
    } catch (e) {
      print('❌ Erreur getAdvancedStats: $e');
      return {
        'statusDistribution': {},
        'monthlyTrends': [],
        'monthlyRevenue': [],
        'topGarages': [],
      };
    }
  }
  
  Future<Map<String, dynamic>> getDashboardStats() async {
    final db = await DbHelper.getInstance();
    
    try {
      // Colis du jour
      final todayResult = await db.connection.execute('''
        SELECT COUNT(*), COALESCE(SUM(price), 0)
        FROM parcels 
        WHERE DATE(created_at) = CURRENT_DATE
      ''');
      
      // Colis de la semaine
      final weekResult = await db.connection.execute('''
        SELECT COUNT(*), COALESCE(SUM(price), 0)
        FROM parcels 
        WHERE created_at >= DATE_TRUNC('week', CURRENT_DATE)
      ''');
      
      // Colis du mois
      final monthResult = await db.connection.execute('''
        SELECT COUNT(*), COALESCE(SUM(price), 0)
        FROM parcels 
        WHERE created_at >= DATE_TRUNC('month', CURRENT_DATE)
      ''');
      
      return {
        'today': {
          'count': todayResult.first[0],
          'revenue': todayResult.first[1],
        },
        'week': {
          'count': weekResult.first[0],
          'revenue': weekResult.first[1],
        },
        'month': {
          'count': monthResult.first[0],
          'revenue': monthResult.first[1],
        },
      };
    } catch (e) {
      print('❌ Erreur getDashboardStats: $e');
      return {
        'today': {'count': 0, 'revenue': 0},
        'week': {'count': 0, 'revenue': 0},
        'month': {'count': 0, 'revenue': 0},
      };
    }
  }
}