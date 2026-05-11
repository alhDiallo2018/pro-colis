import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:procolis/models/user.dart';

import '../../providers/auth_provider.dart';
import '../../providers/parcel_provider.dart';
import '../../widgets/parcel_card.dart';
import '../parcel/new_parcel_screen.dart';
import '../parcel/track_parcel_screen.dart';
import '../profile/profile_screen.dart';

class ClientDashboard extends ConsumerStatefulWidget {
  const ClientDashboard({super.key});

  @override
  ConsumerState<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends ConsumerState<ClientDashboard> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    Future.microtask(() {
      ref.read(parcelProvider.notifier).loadMyParcels();
    });
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
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Envoyer'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Suivre'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _getScreen(int index, User? user, ParcelState parcelState) {
    switch (index) {
      case 0:
        return _HomeScreen(user: user, parcelState: parcelState);
      case 1:
        return const NewParcelScreen();
      case 2:
        return const TrackParcelScreen();
      case 3:
        return const ProfileScreen();
      default:
        return _HomeScreen(user: user, parcelState: parcelState);
    }
  }
}

class _HomeScreen extends StatelessWidget {
  final User? user;
  final ParcelState parcelState;

  const _HomeScreen({required this.user, required this.parcelState});

  @override
  Widget build(BuildContext context) {
    final pendingCount = parcelState.parcels.where((p) => p.status.name == 'pending').length;
    final inTransitCount = parcelState.parcels.where((p) => p.status.name == 'inTransit').length;
    final deliveredCount = parcelState.parcels.where((p) => p.status.name == 'delivered').length;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          floating: true,
          pinned: true,
          backgroundColor: const Color(0xFF0B6E3A),
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              'Bonjour ${user?.fullName.split(' ').first ?? "Client"} ��',
              style: const TextStyle(fontSize: 16),
            ),
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0B6E3A), Color(0xFF168A48)],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        'PRO COLIS',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Transport de colis en Afrique',
                        style: TextStyle(color: Colors.white.withAlpha(200)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Statistiques
              Row(
                children: [
                  _StatCard(title: 'En attente', value: pendingCount.toString(), color: Colors.orange),
                  const SizedBox(width: 12),
                  _StatCard(title: 'En transit', value: inTransitCount.toString(), color: Colors.blue),
                  const SizedBox(width: 12),
                  _StatCard(title: 'Livrés', value: deliveredCount.toString(), color: Colors.green),
                ],
              ),
              const SizedBox(height: 24),
              
              // Derniers colis
              const Text('Derniers colis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (parcelState.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (parcelState.parcels.isEmpty)
                Container(
                  padding: const EdgeInsets.all(40),
                  alignment: Alignment.center,
                  child: const Text('Aucun colis pour le moment'),
                )
              else
                ...parcelState.parcels.take(5).map((parcel) => ParcelCard(
                  parcel: parcel,
                  onTap: () {},
                )),
              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
