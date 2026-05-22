// mobile/lib/screens/dashboard/driver_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:procolis/models/parcel.dart';
import 'package:procolis/models/user.dart';
import 'package:procolis/services/api_service.dart';

import '../../providers/auth_provider.dart';
import '../../providers/parcel_provider.dart';
import '../parcel/new_parcel_screen.dart';
import '../parcel/parcel_detail_screen.dart';
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
      body: _getScreen(_selectedIndex, user, parcelState),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFF0B6E3A),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Mes colis'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Envoyer'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _getScreen(int index, User? user, ParcelState parcelState) {
    switch (index) {
      case 0:
        return _MyParcelsScreen(parcelState: parcelState, onRefresh: _loadData, user: user);
      case 1:
        return const NewParcelScreen();
      case 2:
        return const ProfileScreen();
      default:
        return _MyParcelsScreen(parcelState: parcelState, onRefresh: _loadData, user: user);
    }
  }
}

class _MyParcelsScreen extends StatefulWidget {
  final ParcelState parcelState;
  final VoidCallback onRefresh;
  final User? user;

  const _MyParcelsScreen({
    required this.parcelState,
    required this.onRefresh,
    this.user,
  });

  @override
  State<_MyParcelsScreen> createState() => _MyParcelsScreenState();
}

class _MyParcelsScreenState extends State<_MyParcelsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Parcel> get _pendingParcels {
    return widget.parcelState.parcels.where((p) => 
      p.status == ParcelStatus.pending || p.status == ParcelStatus.confirmed
    ).toList();
  }

  List<Parcel> get _activeDeliveries {
    return widget.parcelState.parcels.where((p) => 
      p.status == ParcelStatus.pickedUp ||
      p.status == ParcelStatus.inTransit ||
      p.status == ParcelStatus.arrived ||
      p.status == ParcelStatus.outForDelivery
    ).toList();
  }

  List<Parcel> get _completedParcels {
    return widget.parcelState.parcels.where((p) => p.isDelivered).toList();
  }

  List<Parcel> get _myParcels {
    return widget.parcelState.parcels.toList();
  }

  @override
  Widget build(BuildContext context) {
    // CORRECTION: widget.user est nullable, on utilise fullName directement
    final userName = widget.user?.fullName.split(' ').first ?? "Chauffeur";

    return RefreshIndicator(
      onRefresh: () async => widget.onRefresh(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0B6E3A), Color(0xFF168A48)],
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, color: Color(0xFF0B6E3A), size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bonjour $userName',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Gérez vos livraisons',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(50),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, size: 14, color: Colors.green[300]),
                            const SizedBox(width: 4),
                            Text(
                              '${_activeDeliveries.length} en cours',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatItem(Icons.pending, 'En attente', _pendingParcels.length, Colors.orange),
                      _buildStatItem(Icons.local_shipping, 'En cours', _activeDeliveries.length, Colors.blue),
                      _buildStatItem(Icons.check_circle, 'Livrés', _completedParcels.length, Colors.green),
                    ],
                  ),
                ],
              ),
            ),
          ),
          TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF0B6E3A),
            labelColor: const Color(0xFF0B6E3A),
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Tous'),
              Tab(text: 'En attente'),
              Tab(text: 'En cours'),
              Tab(text: 'Livrés'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildParcelList(_myParcels),
                _buildParcelList(_pendingParcels),
                _buildParcelList(_activeDeliveries),
                _buildParcelList(_completedParcels),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, int count, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              count.toString(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildParcelList(List<Parcel> parcels) {
    if (widget.parcelState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (parcels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey.withAlpha(100)),
            const SizedBox(height: 16),
            Text(
              'Aucun colis',
              style: TextStyle(color: Colors.grey.withAlpha(150)),
            ),
            const SizedBox(height: 8),
            const Text('Les colis apparaîtront ici', style: TextStyle(fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: parcels.length,
      itemBuilder: (context, index) {
        final parcel = parcels[index];
        return _ParcelCard(parcel: parcel, onRefresh: widget.onRefresh);
      },
    );
  }
}

class _ParcelCard extends StatefulWidget {
  final Parcel parcel;
  final VoidCallback onRefresh;

  const _ParcelCard({required this.parcel, required this.onRefresh});

  @override
  State<_ParcelCard> createState() => _ParcelCardState();
}

class _ParcelCardState extends State<_ParcelCard> {
  bool _isUpdating = false;

  Color _getStatusColor(ParcelStatus status) {
    switch (status) {
      case ParcelStatus.pending:
        return Colors.orange;
      case ParcelStatus.confirmed:
        return Colors.blue;
      case ParcelStatus.pickedUp:
        return Colors.purple;
      case ParcelStatus.inTransit:
        return Colors.indigo;
      case ParcelStatus.arrived:
        return Colors.teal;
      case ParcelStatus.outForDelivery:
        return Colors.lightBlue;
      case ParcelStatus.delivered:
        return Colors.green;
      case ParcelStatus.cancelled:
        return Colors.red;
    }
  }

  Future<void> _acceptDelivery() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Accepter la livraison'),
        content: Text('Voulez-vous accepter la livraison du colis ${widget.parcel.trackingNumber} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Accepter'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _updateStatus('picked_up');
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdating = true);
    final apiService = ApiService();
    try {
      await apiService.updateParcelStatus(widget.parcel.id, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Statut mis à jour'), backgroundColor: Colors.green),
        );
        widget.onRefresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _showDeliveryConfirmation() async {
    final notesController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmation de livraison'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Confirmez-vous la livraison du colis ?'),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                hintText: 'Notes (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _updateStatus('delivered');
    }
    notesController.dispose();
  }

  void _navigateToDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParcelDetailScreen(parcel: widget.parcel),
      ),
    ).then((_) => widget.onRefresh());
  }

  @override
  Widget build(BuildContext context) {
    final parcel = widget.parcel;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: _navigateToDetail,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      parcel.trackingNumber,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 14),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(parcel.status).withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      parcel.status.label,
                      style: TextStyle(fontSize: 11, color: _getStatusColor(parcel.status)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(child: Text('Destinataire: ${parcel.receiverName}')),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(child: Text(parcel.receiverAddress ?? 'Adresse non précisée')),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(parcel.formattedPrice),
                  const Spacer(),
                  if (parcel.driverName != null)
                    Row(
                      children: [
                        const Icon(Icons.delivery_dining, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(parcel.driverName!, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (!_isUpdating)
                _buildActionButtons()
              else
                const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final parcel = widget.parcel;
    
    if (parcel.status == ParcelStatus.pending || parcel.status == ParcelStatus.confirmed) {
      return _buildActionButton(
        icon: Icons.check_circle,
        label: 'Accepter la livraison',
        color: Colors.green,
        onTap: _acceptDelivery,
      );
    } else if (parcel.status == ParcelStatus.pickedUp) {
      return _buildActionButton(
        icon: Icons.directions_car,
        label: 'Démarrer le transport',
        color: Colors.blue,
        onTap: () => _updateStatus('in_transit'),
      );
    } else if (parcel.status == ParcelStatus.inTransit) {
      return _buildActionButton(
        icon: Icons.location_on,
        label: 'Arrivé au garage',
        color: Colors.orange,
        onTap: () => _updateStatus('arrived'),
      );
    } else if (parcel.status == ParcelStatus.arrived) {
      return _buildActionButton(
        icon: Icons.delivery_dining,
        label: 'Partir en livraison',
        color: Colors.purple,
        onTap: () => _updateStatus('out_for_delivery'),
      );
    } else if (parcel.status == ParcelStatus.outForDelivery) {
      return _buildActionButton(
        icon: Icons.check_circle,
        label: 'Marquer comme livré',
        color: Colors.green,
        onTap: _showDeliveryConfirmation,
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}