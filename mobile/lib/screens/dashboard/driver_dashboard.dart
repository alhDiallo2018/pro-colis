import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/parcel.dart'; // IMPORTANT: Ajouter cet import pour ParcelStatus
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/parcel_provider.dart';
import '../../widgets/delivery_card.dart';
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

  Future<void> _refreshData() async {
    await ref.read(parcelProvider.notifier).loadDriverParcels();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final parcelState = ref.watch(parcelProvider);

    return Scaffold(
      body: _getScreen(_selectedIndex, user, parcelState),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFF0B6E3A),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.delivery_dining), label: 'Livraisons'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _getScreen(int index, User? user, ParcelState parcelState) {
    switch (index) {
      case 0:
        return _DeliveriesScreen(
          parcelState: parcelState,
          onRefresh: _refreshData,
        );
      case 1:
        return const ProfileScreen();
      default:
        return _DeliveriesScreen(
          parcelState: parcelState,
          onRefresh: _refreshData,
        );
    }
  }
}

class _DeliveriesScreen extends StatelessWidget {
  final ParcelState parcelState;
  final Future<void> Function()? onRefresh;

  const _DeliveriesScreen({
    required this.parcelState,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes livraisons'),
        backgroundColor: const Color(0xFF0B6E3A),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: onRefresh ?? () async {},
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (parcelState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (parcelState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Erreur: ${parcelState.error}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRefresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B6E3A),
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    
    if (parcelState.parcels.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucune livraison assignée',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: parcelState.parcels.length,
      itemBuilder: (context, index) {
        final parcel = parcelState.parcels[index];
        return DeliveryCard(
          parcel: parcel,
          onPickup: () => _handlePickup(context, parcel.id),
          onDeliver: () => _handleDeliver(context, parcel.id),
          isPickupEnabled: parcel.status == ParcelStatus.pending || 
                           parcel.status == ParcelStatus.confirmed,
          isDeliverEnabled: parcel.status == ParcelStatus.inTransit ||
                           parcel.status == ParcelStatus.outForDelivery,
        );
      },
    );
  }

  void _handlePickup(BuildContext context, String parcelId) async {
    final notifier = ProviderScope.containerOf(context).read(parcelProvider.notifier);
    
    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    await notifier.markAsPickedUp(parcelId);
    
    if (context.mounted) {
      Navigator.pop(context); // Fermer le dialogue
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Colis marqué comme ramassé'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleDeliver(BuildContext context, String parcelId) async {
    final notifier = ProviderScope.containerOf(context).read(parcelProvider.notifier);
    
    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    await notifier.markAsDelivered(parcelId);
    
    if (context.mounted) {
      Navigator.pop(context); // Fermer le dialogue
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Colis marqué comme livré'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}