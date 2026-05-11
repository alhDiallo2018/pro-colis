import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:procolis/models/parcel.dart';

import '../../providers/parcel_provider.dart';
// ignore: unused_import
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/parcel_card.dart';

class TrackParcelScreen extends ConsumerStatefulWidget {
  const TrackParcelScreen({super.key});

  @override
  ConsumerState<TrackParcelScreen> createState() => _TrackParcelScreenState();
}

class _TrackParcelScreenState extends ConsumerState<TrackParcelScreen> {
  final _trackingController = TextEditingController();
  bool _isSearching = false;

  Future<void> _trackParcel() async {
    final trackingNumber = _trackingController.text.trim();
    if (trackingNumber.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez entrer un numéro de suivi')),
        );
      }
      return;
    }
    
    setState(() => _isSearching = true);
    final parcel = await ref.read(parcelProvider.notifier).trackParcel(trackingNumber);
    
    if (mounted) {
      setState(() => _isSearching = false);
    }
    
    if (parcel == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Colis non trouvé'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final parcelState = ref.watch(parcelProvider);
    // Utiliser 'trackedParcel' au lieu de 'currentParcel'
    final trackedParcel = parcelState.trackedParcel;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivre un colis'), 
        backgroundColor: const Color(0xFF0B6E3A),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _trackingController,
                    label: 'Numéro de suivi',
                    prefixIcon: Icons.search,
                  ),
                ),
                const SizedBox(width: 12),
                if (_isSearching)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: _trackParcel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B6E3A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Suivre', style: TextStyle(color: Colors.white)),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            if (trackedParcel != null)
              ParcelCard(
                parcel: trackedParcel, 
                onTap: () {
                  // Naviguer vers les détails du colis
                  _showParcelDetails(trackedParcel);
                }
              )
            else if (!_isSearching)
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.local_shipping, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Entrez un numéro de suivi pour localiser votre colis'),
                  ],
                ),
              ),
            if (parcelState.error != null && !_isSearching && trackedParcel == null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Center(
                  child: Text(
                    parcelState.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showParcelDetails(Parcel parcel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ParcelDetailsSheet(parcel: parcel),
    );
  }

  @override
  void dispose() {
    _trackingController.dispose();
    super.dispose();
  }
}

// Widget pour afficher les détails du colis
class _ParcelDetailsSheet extends StatelessWidget {
  final Parcel parcel;

  const _ParcelDetailsSheet({required this.parcel});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'Suivi de colis',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0B6E3A),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _DetailRow(
                icon: Icons.local_shipping,
                label: 'Numéro de suivi',
                value: parcel.trackingNumber,
              ),
              const Divider(),
              _DetailRow(
                icon: Icons.person,
                label: 'Expéditeur',
                value: parcel.senderName,
              ),
              const Divider(),
              _DetailRow(
                icon: Icons.person_outline,
                label: 'Destinataire',
                value: parcel.receiverName,
              ),
              const Divider(),
              _DetailRow(
                icon: Icons.phone,
                label: 'Téléphone destinataire',
                value: parcel.receiverPhone,
              ),
              const Divider(),
              _DetailRow(
                icon: Icons.description,
                label: 'Description',
                value: parcel.description,
              ),
              const Divider(),
              _DetailRow(
                icon: Icons.fitness_center,
                label: 'Poids',
                value: '${parcel.weight} kg',
              ),
              const Divider(),
              _DetailRow(
                icon: Icons.label,
                label: 'Type',
                value: parcel.type.label,
              ),
              const Divider(),
              _DetailRow(
                icon: Icons.timeline,
                label: 'Statut',
                value: parcel.status.label,
                valueColor: _getStatusColor(parcel.status),
              ),
              const Divider(),
              _DetailRow(
                icon: Icons.calendar_today,
                label: 'Date de création',
                value: _formatDate(parcel.createdAt),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(ParcelStatus status) {
    switch (status) {
      case ParcelStatus.delivered:
        return Colors.green;
      case ParcelStatus.inTransit:
      case ParcelStatus.outForDelivery:
        return Colors.orange;
      case ParcelStatus.cancelled:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}