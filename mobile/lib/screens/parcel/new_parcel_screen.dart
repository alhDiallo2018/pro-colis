import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/parcel.dart';
// ignore: unused_import
import '../../providers/auth_provider.dart';
import '../../providers/parcel_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class NewParcelScreen extends ConsumerStatefulWidget {
  const NewParcelScreen({super.key});

  @override
  ConsumerState<NewParcelScreen> createState() => _NewParcelScreenState();
}

class _NewParcelScreenState extends ConsumerState<NewParcelScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Destinataire
  final _receiverNameController = TextEditingController();
  final _receiverPhoneController = TextEditingController();
  final _receiverEmailController = TextEditingController();
  
  // Colis
  final _descriptionController = TextEditingController();
  final _weightController = TextEditingController();
  final _priceController = TextEditingController();
  ParcelType _selectedType = ParcelType.package;
  
  // Lieux
  String? _selectedDepartureGarage;
  String? _selectedArrivalGarage;
  
  bool _isLoading = false;
  bool _urgentDelivery = false;
  bool _insurance = false;

  final List<Map<String, String>> _garages = [
    {'id': '1', 'name': 'Garage Dakar Centre', 'city': 'Dakar'},
    {'id': '2', 'name': 'Garage Thiès', 'city': 'Thiès'},
    {'id': '3', 'name': 'Garage Saint-Louis', 'city': 'Saint-Louis'},
    {'id': '4', 'name': 'Garage Ziguinchor', 'city': 'Ziguinchor'},
    {'id': '5', 'name': 'Garage Kaolack', 'city': 'Kaolack'},
  ];

  @override
  void dispose() {
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    _receiverEmailController.dispose();
    _descriptionController.dispose();
    _weightController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _createParcel() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    final data = {
      'receiverName': _receiverNameController.text.trim(),
      'receiverPhone': _receiverPhoneController.text.trim(),
      'receiverEmail': _receiverEmailController.text.trim().isEmpty ? null : _receiverEmailController.text.trim(),
      'description': _descriptionController.text.trim(),
      'weight': double.parse(_weightController.text),
      'type': _selectedType.value,
      'departureGarageId': _selectedDepartureGarage,
      'departureGarageName': _garages.firstWhere((g) => g['id'] == _selectedDepartureGarage)['name'],
      'arrivalGarageId': _selectedArrivalGarage,
      'arrivalGarageName': _garages.firstWhere((g) => g['id'] == _selectedArrivalGarage)['name'],
      'price': double.tryParse(_priceController.text) ?? 0,
      'urgent': _urgentDelivery,
      'insurance': _insurance,
    };
    
    final result = await ref.read(parcelProvider.notifier).createParcel(data);
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
    
    if (result != null && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('✅ Colis créé !'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 64, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                'Numéro de suivi',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                result.trackingNumber,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
              ),
              const SizedBox(height: 16),
              Text(
                'Un email de confirmation a été envoyé',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _resetForm();
              },
              child: const Text('Nouveau colis'),
            ),
          ],
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la création'), backgroundColor: Colors.red),
      );
    }
  }

  void _resetForm() {
    _receiverNameController.clear();
    _receiverPhoneController.clear();
    _receiverEmailController.clear();
    _descriptionController.clear();
    _weightController.clear();
    _priceController.clear();
    setState(() {
      _selectedType = ParcelType.package;
      _selectedDepartureGarage = null;
      _selectedArrivalGarage = null;
      _urgentDelivery = false;
      _insurance = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau colis'),
        backgroundColor: const Color(0xFF0B6E3A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Destinataire
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text('Destinataire', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _receiverNameController,
                      label: 'Nom complet',
                      prefixIcon: Icons.person,
                      validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _receiverPhoneController,
                      label: 'Téléphone',
                      prefixIcon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _receiverEmailController,
                      label: 'Email (optionnel)',
                      prefixIcon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Section Colis
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.inventory, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        Text('Informations colis', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _descriptionController,
                      label: 'Description',
                      prefixIcon: Icons.description,
                      maxLines: 3,
                      validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _weightController,
                            label: 'Poids (kg)',
                            prefixIcon: Icons.fitness_center,
                            keyboardType: TextInputType.number,
                            validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: _priceController,
                            label: 'Prix (FCFA)',
                            prefixIcon: Icons.money,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ParcelType>(
                      initialValue: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Type de colis',
                        prefixIcon: Icon(Icons.category),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      items: ParcelType.values.map((type) => DropdownMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            Icon(_getTypeIcon(type), size: 18),
                            const SizedBox(width: 8),
                            Text(type.label),
                          ],
                        ),
                      )).toList(),
                      onChanged: (value) => setState(() => _selectedType = value!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Section Trajet
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.route, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Text('Trajet', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade700)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedDepartureGarage,
                      decoration: const InputDecoration(
                        labelText: 'Garage départ',
                        prefixIcon: Icon(Icons.departure_board),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      items: _garages.map((garage) => DropdownMenuItem(
                        value: garage['id'],
                        child: Text('${garage['name']} - ${garage['city']}'),
                      )).toList(),
                      onChanged: (value) => setState(() => _selectedDepartureGarage = value),
                      validator: (v) => v == null ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedArrivalGarage,
                      decoration: const InputDecoration(
                        labelText: 'Garage arrivée',
                        prefixIcon: Icon(Icons.location_on), // Remplacé Icons.arrival qui n'existe pas
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      items: _garages.map((garage) => DropdownMenuItem(
                        value: garage['id'],
                        child: Text('${garage['name']} - ${garage['city']}'),
                      )).toList(),
                      onChanged: (value) => setState(() => _selectedArrivalGarage = value),
                      validator: (v) => v == null ? 'Champ requis' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Options supplémentaires
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Livraison urgente'),
                      subtitle: const Text('Priorité + 500 FCFA'),
                      value: _urgentDelivery,
                      onChanged: (value) => setState(() => _urgentDelivery = value),
                      activeTrackColor: const Color(0xFF0B6E3A).withValues(alpha: 0.5),
                      activeThumbColor: const Color(0xFF0B6E3A),
                    ),
                    SwitchListTile(
                      title: const Text('Assurance colis'),
                      subtitle: const Text('Protection jusqu\'à 50 000 FCFA'),
                      value: _insurance,
                      onChanged: (value) => setState(() => _insurance = value),
                      activeTrackColor: const Color(0xFF0B6E3A).withValues(alpha: 0.5),
                      activeThumbColor: const Color(0xFF0B6E3A),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Créer le colis',
                onPressed: _createParcel,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(ParcelType type) {
    switch (type) {
      case ParcelType.document:
        return Icons.description;
      case ParcelType.package:
        return Icons.inventory;
      case ParcelType.fragile:
        return Icons.science;
      case ParcelType.perishable:
        return Icons.eco;
      case ParcelType.valuable:
        return Icons.attach_money;
      }
  }
}