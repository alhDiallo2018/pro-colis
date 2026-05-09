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
  final String? adminName;
  final int activeDrivers;
  final int parcelsToday;
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
    this.adminName,
    this.activeDrivers = 0,
    this.parcelsToday = 0,
    required this.createdAt,
  });

  factory Garage.fromJson(Map<String, dynamic> json) {
    return Garage(
      id: json['id'],
      name: json['name'],
      city: json['city'],
      region: json['region'],
      address: json['address'],
      phone: json['phone'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      adminId: json['adminId'],
      adminName: json['adminName'],
      activeDrivers: json['activeDrivers'] ?? 0,
      parcelsToday: json['parcelsToday'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
