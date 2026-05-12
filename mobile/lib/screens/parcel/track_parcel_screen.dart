import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/parcel_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../models/parcel.dart';

class TrackParcelScreen extends ConsumerStatefulWidget {
  const TrackParcelScreen({super.key});

  @override
  ConsumerState<TrackParcelScreen> createState() => _TrackParcelScreenState();
}

class _TrackParcelScreenState extends ConsumerState<TrackParcelScreen> {
  final _trackingController = TextEditingController();
  bool _isSearching = false;
  Parcel? _trackedParcel;

  Future<void> _trackParcel() async {
    final trackingNumber = _trackingController.text.trim();
    if (trackingNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un numéro de suivi')),
      );
      return;
    }
    
    setState(() => _isSearching = true);
    final parcel = await ref.read(parcelProvider.notifier).trackParcel(trackingNumber);
    setState(() {
      _isSearching = false;
      _trackedParcel = parcel;
    });
    
    if (parcel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Colis non trouvé'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildStatusTimeline(Parcel parcel) {
    final List<Map<String, dynamic>> steps = [
      {'status': 'pending', 'label': 'Création', 'icon': Icons.create, 'completed': true},
      {'status': 'confirmed', 'label': 'Confirmé', 'icon': Icons.check_circle, 'completed': true},
      {'status': 'pickedUp', 'label': 'Ramassé', 'icon': Icons.local_shipping, 'completed': parcel.status.value == 'pickedUp' || parcel.status.value == 'inTransit' || parcel.status.value == 'delivered'},
      {'status': 'inTransit', 'label': 'En transit', 'icon': Icons.transfer_within_a_station, 'completed': parcel.status.value == 'inTransit' || parcel.status.value == 'delivered'},
      {'status': 'arrived', 'label': 'Arrivé', 'icon': Icons.location_on, 'completed': parcel.status.value == 'arrived' || parcel.status.value == 'delivered'},
      {'status': 'delivered', 'label': 'Livré', 'icon': Icons.check_circle, 'completed': parcel.status.value == 'delivered'},
    ];

    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isCompleted = step['completed'] as bool;
        final isLast = index == steps.length - 1;
        
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? const Color(0xFF0B6E3A) : Colors.grey.shade300,
                  ),
                  child: Icon(step['icon'], color: Colors.white, size: 20),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 60,
                    color: isCompleted ? const Color(0xFF0B6E3A) : Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step['label'],
                      style: TextStyle(
                        fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                        color: isCompleted ? const Color(0xFF0B6E3A) : Colors.grey,
                      ),
                    ),
                    if (isCompleted && step['status'] == parcel.status.value)
                      Text(
                        'En cours',
                        style: TextStyle(fontSize: 12, color: const Color(0xFF0B6E3A)),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivre un colis'),
        backgroundColor: const Color(0xFF0B6E3A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Recherche
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _trackingController,
                      label: 'Numéro de suivi',
                      prefixIcon: Icons.search,
                      hint: 'Ex: PC-20250511-0042',
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Suivre mon colis',
                      onPressed: _trackParcel,
                      isLoading: _isSearching,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Résultat
            if (_trackedParcel != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _trackedParcel!.trackingNumber,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _trackedParcel!.status.color.withAlpha(25),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _trackedParcel!.status.label,
                                  style: TextStyle(fontSize: 12, color: _trackedParcel!.status.color),
                                ),
                              ),
                            ],
                          ),
                          if (_trackedParcel!.price != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Montant', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(
                                  '${_trackedParcel!.price!.toStringAsFixed(0)} FCFA',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0B6E3A)),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const Divider(height: 32),
                      
                      // Timeline
                      _buildStatusTimeline(_trackedParcel!),
                      const Divider(height: 32),
                      
                      // Informations
                      ListTile(
                        leading: const Icon(Icons.person, color: Colors.blue),
                        title: const Text('Destinataire'),
                        subtitle: Text(_trackedParcel!.receiverName),
                        trailing: IconButton(
                          icon: const Icon(Icons.phone, color: Colors.green),
                          onPressed: () {},
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.description, color: Colors.orange),
                        title: const Text('Description'),
                        subtitle: Text(_trackedParcel!.description),
                      ),
                      ListTile(
                        leading: const Icon(Icons.fitness_center, color: Colors.purple),
                        title: const Text('Poids'),
                        subtitle: Text('${_trackedParcel!.weight} kg'),
                      ),
                      if (_trackedParcel!.driverName != null)
                        ListTile(
                          leading: const Icon(Icons.delivery_dining, color: Colors.green),
                          title: const Text('Chauffeur'),
                          subtitle: Text(_trackedParcel!.driverName!),
                          trailing: IconButton(
                            icon: const Icon(Icons.phone, color: Colors.green),
                            onPressed: () {},
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.share),
                      label: const Text('Partager'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download),
                      label: const Text('Reçu'),
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
