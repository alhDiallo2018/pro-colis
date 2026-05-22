// mobile/lib/screens/parcel/parcel_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:procolis/models/parcel.dart';
import 'package:procolis/services/api_service.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/status_timeline.dart';

class ParcelDetailScreen extends ConsumerStatefulWidget {
  final Parcel parcel;

  const ParcelDetailScreen({super.key, required this.parcel});

  @override
  ConsumerState<ParcelDetailScreen> createState() => _ParcelDetailScreenState();
}

class _ParcelDetailScreenState extends ConsumerState<ParcelDetailScreen> {
  final ApiService _apiService = ApiService();
  List<ParcelEvent> _events = [];
  bool _isLoadingEvents = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoadingEvents = true);
    try {
      final events = await _apiService.getParcelEvents(widget.parcel.id);
      if (mounted) {
        setState(() {
          _events = events;
          _isLoadingEvents = false;
        });
      }
    } catch (e) {
      // Ne pas afficher d'erreur, juste une liste vide
      debugPrint('⚠️ Impossible de charger les événements: $e');
      if (mounted) {
        setState(() {
          _events = [];
          _isLoadingEvents = false;
        });
      }
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdating = true);
    try {
      final updatedParcel = await _apiService.updateParcelStatus(
        widget.parcel.id,
        newStatus,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Statut mis à jour avec succès'), backgroundColor: Colors.green),
        );
        await _loadEvents();
        // Mettre à jour le widget parent si nécessaire
        if (mounted) {
          Navigator.pop(context, updatedParcel);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _acceptParcel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accepter le colis'),
        content: Text('Voulez-vous accepter la livraison du colis ${widget.parcel.trackingNumber} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
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

  Future<void> _confirmDelivery() async {
    final notesController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
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

  @override
  Widget build(BuildContext context) {
    final parcel = widget.parcel;
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isDriver = user?.isDriver ?? false;
    final isAdmin = user?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(parcel.trackingNumber),
        backgroundColor: const Color(0xFF0B6E3A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvents,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carte d'information
            _buildInfoCard(parcel),
            const SizedBox(height: 16),
            
            // Statut actuel
            _buildStatusCard(parcel),
            const SizedBox(height: 16),
            
            // Timeline des événements
            _buildTimelineSection(),
            const SizedBox(height: 16),
            
            // Actions (si chauffeur)
            if (isDriver || isAdmin) _buildActionsSection(parcel),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(Parcel parcel) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations du colis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Numéro de suivi', parcel.trackingNumber, Icons.numbers),
            const Divider(),
            _buildInfoRow('Expéditeur', parcel.senderName, Icons.person_outline),
            _buildInfoRow('Téléphone expéditeur', parcel.senderPhone, Icons.phone),
            const Divider(),
            _buildInfoRow('Destinataire', parcel.receiverName, Icons.person),
            _buildInfoRow('Téléphone destinataire', parcel.receiverPhone, Icons.phone),
            if (parcel.receiverEmail != null && parcel.receiverEmail!.isNotEmpty)
              _buildInfoRow('Email destinataire', parcel.receiverEmail!, Icons.email),
            const Divider(),
            _buildInfoRow('Description', parcel.description, Icons.description),
            _buildInfoRow('Poids', '${parcel.weight} kg', Icons.fitness_center),
            _buildInfoRow('Type', parcel.type.label, Icons.category),
            if (parcel.price != null)
              _buildInfoRow('Prix', '${parcel.price!.toInt()} FCFA', Icons.money),
            if (parcel.paymentMethod != null)
              _buildInfoRow('Mode de paiement', _getPaymentMethodLabel(parcel.paymentMethod!), Icons.payment),
            if (parcel.paymentStatus != null)
              _buildInfoRow('Statut paiement', _getPaymentStatusLabel(parcel.paymentStatus!), Icons.receipt),
            const Divider(),
            if (parcel.driverName != null)
              _buildInfoRow('Chauffeur', parcel.driverName!, Icons.delivery_dining),
            if (parcel.driverPhone != null)
              _buildInfoRow('Téléphone chauffeur', parcel.driverPhone!, Icons.phone),
            const Divider(),
            _buildInfoRow('Date de création', _formatDate(parcel.createdAt), Icons.calendar_today),
            if (parcel.pickupDate != null)
              _buildInfoRow('Date de ramassage', _formatDate(parcel.pickupDate!), Icons.inventory),
            if (parcel.deliveryDate != null)
              _buildInfoRow('Date de livraison', _formatDate(parcel.deliveryDate!), Icons.check_circle),
            
            // Options supplémentaires
            const SizedBox(height: 16),
            const Text('Options', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildOptionChip('Urgent', _isUrgent(parcel), Colors.red),
                const SizedBox(width: 8),
                _buildOptionChip('Assuré', _isInsured(parcel), Colors.blue),
              ],
            ),
            
            // Photos
            if (parcel.photoUrls.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Photos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: parcel.photoUrls.length,
                  itemBuilder: (context, index) {
                    return _buildPhotoThumbnail(parcel.photoUrls[index]);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoThumbnail(String url) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(
          image: NetworkImage(url),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildOptionChip(String label, bool isActive, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? color.withAlpha(25) : Colors.grey.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? color : Colors.grey,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.circle_outlined,
            size: 14,
            color: isActive ? color : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? color : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  bool _isUrgent(Parcel parcel) {
    // Vérifier si le colis est urgent (vous pouvez ajouter ce champ dans le modèle)
    // Pour l'instant, on vérifie dans la description ou on retourne false
    return parcel.description.toLowerCase().contains('urgent');
  }

  bool _isInsured(Parcel parcel) {
    // Vérifier si le colis est assuré
    // À adapter selon votre modèle
    return parcel.price != null && parcel.price! > 50000;
  }

  String _getPaymentMethodLabel(dynamic method) {
    if (method == null) return 'Non spécifié';
    
    // Si c'est une String
    if (method is String) {
      switch (method) {
        case 'cash': return 'Espèces';
        case 'wave': return 'Wave';
        case 'orange_money': return 'Orange Money';
        case 'card': return 'Carte bancaire';
        default: return method;
      }
    }
    
    // Si c'est un enum PaymentMethod
    // Convertir en String selon votre implémentation
    final methodStr = method.toString();
    if (methodStr.contains('cash')) return 'Espèces';
    if (methodStr.contains('wave')) return 'Wave';
    if (methodStr.contains('orange')) return 'Orange Money';
    if (methodStr.contains('card')) return 'Carte bancaire';
    
    return methodStr;
  }

  String _getPaymentStatusLabel(dynamic status) {
    if (status == null) return 'Non spécifié';
    
    if (status is String) {
      switch (status) {
        case 'pending': return 'En attente';
        case 'completed': return 'Payé';
        case 'failed': return 'Échoué';
        default: return status;
      }
    }
    
    final statusStr = status.toString();
    if (statusStr.contains('pending')) return 'En attente';
    if (statusStr.contains('completed')) return 'Payé';
    if (statusStr.contains('failed')) return 'Échoué';
    
    return statusStr;
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(Parcel parcel) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statut actuel',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: parcel.status.color.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    parcel.isDelivered ? Icons.check_circle : Icons.local_shipping,
                    color: parcel.status.color,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          parcel.status.label,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: parcel.status.color,
                          ),
                        ),
                        if (parcel.deliveryDate != null)
                          Text(
                            'Livré le: ${_formatDate(parcel.deliveryDate!)}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        if (parcel.estimatedDeliveryDate != null)
                          Text(
                            'Livraison estimée: ${_formatDate(parcel.estimatedDeliveryDate!)}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Historique du colis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_isLoadingEvents)
              const Center(child: CircularProgressIndicator())
            else if (_events.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Aucun historique disponible'),
                ),
              )
            else
              StatusTimeline(events: _events),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection(Parcel parcel) {
    // Déterminer les actions disponibles selon le statut
    List<Widget> actions = [];

    if (parcel.status == ParcelStatus.pending || parcel.status == ParcelStatus.confirmed) {
      actions.add(
        _buildActionButton(
          icon: Icons.check_circle,
          label: 'Accepter le colis',
          color: Colors.green,
          onPressed: _acceptParcel,
        ),
      );
    } else if (parcel.status == ParcelStatus.pickedUp) {
      actions.add(
        _buildActionButton(
          icon: Icons.directions_car,
          label: 'Démarrer le transport',
          color: Colors.blue,
          onPressed: () => _updateStatus('in_transit'),
        ),
      );
    } else if (parcel.status == ParcelStatus.inTransit) {
      actions.add(
        _buildActionButton(
          icon: Icons.location_on,
          label: 'Arrivé au garage',
          color: Colors.orange,
          onPressed: () => _updateStatus('arrived'),
        ),
      );
    } else if (parcel.status == ParcelStatus.arrived) {
      actions.add(
        _buildActionButton(
          icon: Icons.delivery_dining,
          label: 'Partir en livraison',
          color: Colors.purple,
          onPressed: () => _updateStatus('out_for_delivery'),
        ),
      );
    } else if (parcel.status == ParcelStatus.outForDelivery) {
      actions.add(
        _buildActionButton(
          icon: Icons.check_circle,
          label: 'Marquer comme livré',
          color: Colors.green,
          onPressed: _confirmDelivery,
        ),
      );
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...actions,
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isUpdating ? null : onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}