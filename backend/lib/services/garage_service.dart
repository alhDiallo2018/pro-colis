import 'package:uuid/uuid.dart';

class Garage {
  final String id;
  final String name;
  final String city;
  final String region;
  final String address;
  final String phone;
  final double? latitude;
  final double? longitude;
  final String? adminId;
  final DateTime createdAt;

  Garage({
    required this.id,
    required this.name,
    required this.city,
    required this.region,
    required this.address,
    required this.phone,
    this.latitude,
    this.longitude,
    this.adminId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'city': city,
    'region': region,
    'address': address,
    'phone': phone,
    'latitude': latitude,
    'longitude': longitude,
    'adminId': adminId,
    'createdAt': createdAt.toIso8601String(),
  };
}

class GarageService {
  final List<Garage> _garages = [];
  final _uuid = const Uuid();
  
  Future<Garage> createGarage({
    required String name,
    required String city,
    required String region,
    required String address,
    required String phone,
    double? latitude,
    double? longitude,
  }) async {
    final garage = Garage(
      id: _uuid.v4(),
      name: name,
      city: city,
      region: region,
      address: address,
      phone: phone,
      latitude: latitude,
      longitude: longitude,
      createdAt: DateTime.now(),
    );
    
    _garages.add(garage);
    return garage;
  }
  
  Future<List<Garage>> getAllGarages() async {
    return _garages;
  }
  
  Future<Garage?> getGarage(String id) async {
    try {
      return _garages.firstWhere((g) => g.id == id);
    } catch (e) {
      return null;
    }
  }
  
  Future<Garage?> updateGarage(String id, Map<String, dynamic> data) async {
    final index = _garages.indexWhere((g) => g.id == id);
    if (index == -1) return null;
    
    final old = _garages[index];
    final updated = Garage(
      id: old.id,
      name: data['name'] ?? old.name,
      city: data['city'] ?? old.city,
      region: data['region'] ?? old.region,
      address: data['address'] ?? old.address,
      phone: data['phone'] ?? old.phone,
      latitude: data['latitude'] ?? old.latitude,
      longitude: data['longitude'] ?? old.longitude,
      adminId: data['adminId'] ?? old.adminId,
      createdAt: old.createdAt,
    );
    
    _garages[index] = updated;
    return updated;
  }
  
  Future<bool> deleteGarage(String id) async {
    final index = _garages.indexWhere((g) => g.id == id);
    if (index == -1) return false;
    _garages.removeAt(index);
    return true;
  }
  
  Future<Garage?> assignAdmin(String garageId, String adminId) async {
    return await updateGarage(garageId, {'adminId': adminId});
  }
  
  Future<List<Map<String, dynamic>>> getGarageDrivers(String garageId) async {
    // Dans une implémentation réelle, on récupérerait les chauffeurs du garage
    return [];
  }
}
