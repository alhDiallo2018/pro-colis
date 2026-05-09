// backend/lib/models/garage.dart
class Garage {
  final String id;
  final String name;
  final String city;
  final String region;
  final String? country;
  final String address;
  final String phone;
  final List<double> coordinates;
  final String? adminId;
  final DateTime createdAt;

  Garage({
    required this.id,
    required this.name,
    required this.city,
    required this.region,
    this.country = 'Sénégal',
    required this.address,
    required this.phone,
    required this.coordinates,
    this.adminId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'city': city,
    'region': region,
    'country': country,
    'address': address,
    'phone': phone,
    'latitude': coordinates[0],
    'longitude': coordinates[1],
    'adminId': adminId,
    'createdAt': createdAt.toIso8601String(),
  };
}