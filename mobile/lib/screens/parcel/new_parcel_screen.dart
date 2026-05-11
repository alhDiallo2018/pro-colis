import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final _receiverNameController = TextEditingController();
  final _receiverPhoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _weightController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isLoading = false;

  Future<void> _createParcel() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    final data = {
      'receiverName': _receiverNameController.text.trim(),
      'receiverPhone': _receiverPhoneController.text.trim(),
      'description': _descriptionController.text.trim(),
      'weight': double.parse(_weightController.text),
      'type': 'package',
      'departureGarageId': 'garage_1',
      'arrivalGarageId': 'garage_2',
      'price': double.tryParse(_priceController.text) ?? 0,
    };
    
    final result = await ref.read(parcelProvider.notifier).createParcel(data);
    
    setState(() => _isLoading = false);
    
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Colis créé avec succès !'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la création'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau colis'), backgroundColor: const Color(0xFF0B6E3A)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                controller: _receiverNameController,
                label: 'Nom du destinataire',
                prefixIcon: Icons.person,
                validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _receiverPhoneController,
                label: 'Téléphone du destinataire',
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _descriptionController,
                label: 'Description',
                prefixIcon: Icons.description,
                validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _weightController,
                label: 'Poids (kg)',
                prefixIcon: Icons.fitness_center,
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _priceController,
                label: 'Prix (FCFA)',
                prefixIcon: Icons.money,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Créer le colis',
                onPressed: _createParcel,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
