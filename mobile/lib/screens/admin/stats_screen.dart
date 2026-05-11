import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminStatsScreen extends ConsumerStatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  ConsumerState<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends ConsumerState<AdminStatsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        backgroundColor: const Color(0xFF0B6E3A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Cartes de statistiques
            Row(
              children: [
                _StatsCard(
                  title: 'Utilisateurs',
                  value: '156',
                  icon: Icons.people,
                  color: Colors.blue,
                ),
                const SizedBox(width: 12),
                _StatsCard(
                  title: 'Chauffeurs',
                  value: '45',
                  icon: Icons.delivery_dining,
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatsCard(
                  title: 'Colis',
                  value: '1,234',
                  icon: Icons.inventory,
                  color: Colors.orange,
                ),
                const SizedBox(width: 12),
                _StatsCard(
                  title: 'Garages',
                  value: '12',
                  icon: Icons.business,
                  color: Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatsCard(
                  title: 'En transit',
                  value: '89',
                  icon: Icons.local_shipping,
                  color: Colors.teal,
                ),
                const SizedBox(width: 12),
                _StatsCard(
                  title: 'Livrés',
                  value: '1,023',
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Graphique des revenus
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Revenus',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 200,
                      color: Colors.grey.shade100,
                      child: const Center(
                        child: Text('Graphique des revenus'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Dernières activités
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dernières activités',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: const Icon(Icons.person_add, color: Colors.green),
                      title: const Text('Nouvel utilisateur'),
                      subtitle: Text('Inscription de Mamadou Diallo', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      trailing: const Text('Il y a 5 min', style: TextStyle(fontSize: 12)),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.local_shipping, color: Colors.orange),
                      title: const Text('Colis livré'),
                      subtitle: Text('PC-20250511-0042 livré à Thiès', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      trailing: const Text('Il y a 15 min', style: TextStyle(fontSize: 12)),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.payment, color: Colors.blue),
                      title: const Text('Paiement reçu'),
                      subtitle: Text('5 000 FCFA - Wave', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      trailing: const Text('Il y a 1h', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatsCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
