class AdminStats {
  final int totalUsers;
  final int totalDrivers;
  final int totalClients;
  final int totalGarages;
  final int totalParcels;
  final int parcelsInTransit;
  final int parcelsDeliveredToday;
  final double totalRevenue;
  
  AdminStats({
    required this.totalUsers,
    required this.totalDrivers,
    required this.totalClients,
    required this.totalGarages,
    required this.totalParcels,
    required this.parcelsInTransit,
    required this.parcelsDeliveredToday,
    required this.totalRevenue,
  });
  
  Map<String, dynamic> toJson() => {
    'totalUsers': totalUsers,
    'totalDrivers': totalDrivers,
    'totalClients': totalClients,
    'totalGarages': totalGarages,
    'totalParcels': totalParcels,
    'parcelsInTransit': parcelsInTransit,
    'parcelsDeliveredToday': parcelsDeliveredToday,
    'totalRevenue': totalRevenue,
  };
}

class AdminService {
  Future<AdminStats> getOverviewStats() async {
    // Dans une implémentation réelle, on calculerait les stats depuis la DB
    return AdminStats(
      totalUsers: 0,
      totalDrivers: 0,
      totalClients: 0,
      totalGarages: 0,
      totalParcels: 0,
      parcelsInTransit: 0,
      parcelsDeliveredToday: 0,
      totalRevenue: 0,
    );
  }
  
  Future<Map<String, dynamic>> getRevenueStats(String period) async {
    return {
      'period': period,
      'revenue': 0,
      'trend': 0,
    };
  }
}
