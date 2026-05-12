import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/parcel.dart';
import '../../providers/auth_provider.dart';
import '../../providers/parcel_provider.dart';
import '../../widgets/custom_button.dart';
import '../profile/profile_screen.dart';

class DriverDashboard extends ConsumerStatefulWidget {
  const DriverDashboard({super.key});

  @override
  ConsumerState<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends ConsumerState<DriverDashboard> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    Future.microtask(() {
      ref.read(parcelProvider.notifier).loadDriverParcels();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final parcelState = ref.watch(parcelProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Bonjour ${user?.fullName.split(' ').first ?? "Chauffeur"} 👋'),
        backgroundColor: const Color(0xFF0B6E3A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _getScreen(_selectedIndex, parcelState),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFF0B6E3A),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.delivery_dining), label: 'Livraisons'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historique'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _getScreen(int index, ParcelState parcelState) {
    switch (index) {
      case 0:
        return _DeliveriesScreen(parcelState: parcelState, onRefresh: _loadData);
      case 1:
        return _HistoryScreen(parcelState: parcelState);
      default:
        return const ProfileScreen();
    }
  }
}

// Convertir en ConsumerWidget pour avoir accès à ref
class _DeliveriesScreen extends ConsumerWidget {
  final ParcelState parcelState;
  final VoidCallback onRefresh;

  const _DeliveriesScreen({required this.parcelState, required this.onRefresh});

  void _showPickupDialog(BuildContext context, WidgetRef ref, Parcel parcel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer ramassage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Avez-vous bien récupéré le colis ?'),
            const SizedBox(height: 16),
            Text(
              'Colis: ${parcel.trackingNumber}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Destinataire: ${parcel.receiverName}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(parcelProvider.notifier).updateParcelStatus(parcel.id, 'in_transit');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ramassage confirmé'), backgroundColor: Colors.green),
                );
                onRefresh();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B6E3A)),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _showDeliveryDialog(BuildContext context, WidgetRef ref, Parcel parcel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer livraison'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Avez-vous bien livré le colis au destinataire ?'),
            const SizedBox(height: 16),
            Text(
              'Colis: ${parcel.trackingNumber}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Destinataire: ${parcel.receiverName}'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.camera_alt),
              label: const Text('Prendre une photo'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(parcelProvider.notifier).updateParcelStatus(parcel.id, 'delivered');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Livraison confirmée'), backgroundColor: Colors.green),
                );
                onRefresh();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B6E3A)),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingDeliveries = parcelState.parcels.where((p) => 
      p.status == ParcelStatus.pending || 
      p.status == ParcelStatus.pickedUp || 
      p.status == ParcelStatus.inTransit
    ).toList();
    
    final completedDeliveries = parcelState.parcels.where((p) => 
      p.status == ParcelStatus.delivered
    ).toList();

    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
        return Future.value();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistiques
            Row(
              children: [
                _StatCard(
                  title: 'À livrer',
                  value: pendingDeliveries.length.toString(),
                  icon: Icons.pending,
                  color: Colors.orange,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  title: 'Livrées',
                  value: completedDeliveries.length.toString(),
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Livraisons en cours
            const Text(
              'Livraisons en cours',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (parcelState.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (pendingDeliveries.isEmpty)
              Container(
                padding: const EdgeInsets.all(40),
                alignment: Alignment.center,
                child: const Text('Aucune livraison en cours'),
              )
            else
              ...pendingDeliveries.map((parcel) => _DeliveryCard(
                parcel: parcel,
                onPickup: () => _showPickupDialog(context, ref, parcel),
                onDeliver: () => _showDeliveryDialog(context, ref, parcel),
              )),
            
            const SizedBox(height: 24),
            
            // Livraisons terminées
            if (completedDeliveries.isNotEmpty) ...[
              const Text(
                'Livraisons terminées',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...completedDeliveries.take(3).map((parcel) => _DeliveryCard(
                parcel: parcel,
                isCompleted: true,
                onPickup: () {},
                onDeliver: () {},
              )),
            ],
          ],
        ),
      ),
    );
  }
}

class _HistoryScreen extends StatelessWidget {
  final ParcelState parcelState;

  const _HistoryScreen({required this.parcelState});

  @override
  Widget build(BuildContext context) {
    final deliveredParcels = parcelState.parcels.where((p) => p.status == ParcelStatus.delivered).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique'),
        backgroundColor: const Color(0xFF0B6E3A),
        foregroundColor: Colors.white,
      ),
      body: parcelState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : deliveredParcels.isEmpty
              ? const Center(child: Text('Aucune livraison terminée'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: deliveredParcels.length,
                  itemBuilder: (context, index) {
                    final parcel = deliveredParcels[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.check_circle, color: Colors.green),
                        title: Text(parcel.trackingNumber),
                        subtitle: Text('${parcel.receiverName} - ${parcel.receiverPhone}'),
                        trailing: Text(
                          parcel.deliveryDate != null 
                              ? '${parcel.deliveryDate!.day}/${parcel.deliveryDate!.month}'
                              : '',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        onTap: () {},
                      ),
                    );
                  },
                ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final Parcel parcel;
  final VoidCallback onPickup;
  final VoidCallback onDeliver;
  final bool isCompleted;

  const _DeliveryCard({
    required this.parcel,
    required this.onPickup,
    required this.onDeliver,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: parcel.status.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.local_shipping, color: parcel.status.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        parcel.trackingNumber,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                      ),
                      Text(parcel.receiverName),
                      Text(parcel.receiverPhone, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: parcel.status.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    parcel.status.label,
                    style: TextStyle(fontSize: 10, color: parcel.status.color),
                  ),
                ),
              ],
            ),
            if (!isCompleted) ...[
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Ramassage',
                      onPressed: onPickup,
                      backgroundColor: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomButton(
                      text: 'Livrer',
                      onPressed: onDeliver,
                      backgroundColor: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}