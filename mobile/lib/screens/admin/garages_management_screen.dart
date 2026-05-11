import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GaragesManagementScreen extends ConsumerStatefulWidget {
  const GaragesManagementScreen({super.key});

  @override
  ConsumerState<GaragesManagementScreen> createState() => _GaragesManagementScreenState();
}

class _GaragesManagementScreenState extends ConsumerState<GaragesManagementScreen> {
  final List<Map<String, dynamic>> _garages = [
    {'id': '1', 'name': 'Garage Dakar Centre', 'city': 'Dakar', 'drivers': 12, 'parcels': 234, 'phone': '+221 33 123 45 67'},
    {'id': '2', 'name': 'Garage Thiès', 'city': 'Thiès', 'drivers': 8, 'parcels': 156, 'phone': '+221 33 987 65 43'},
    {'id': '3', 'name': 'Garage Saint-Louis', 'city': 'Saint-Louis', 'drivers': 5, 'parcels': 89, 'phone': '+221 33 456 78 90'},
    {'id': '4', 'name': 'Garage Ziguinchor', 'city': 'Ziguinchor', 'drivers': 6, 'parcels': 67, 'phone': '+221 33 234 56 78'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des garages'),
        backgroundColor: const Color(0xFF0B6E3A),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Ajouter un garage
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _garages.length,
        itemBuilder: (context, index) {
          final garage = _garages[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF0B6E3A).withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.business, color: Color(0xFF0B6E3A)),
              ),
              title: Text(garage['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(garage['city']),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _InfoRow(label: 'Téléphone', value: garage['phone']),
                      const SizedBox(height: 8),
                      _InfoRow(label: 'Chauffeurs', value: '${garage['drivers']}'),
                      const SizedBox(height: 8),
                      _InfoRow(label: 'Colis traités', value: '${garage['parcels']}'),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.edit),
                              label: const Text('Modifier'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.people),
                              label: const Text('Chauffeurs'),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: const TextStyle(color: Colors.grey)),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }
}
