// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late User _user;
  bool _isEditing = false;
  bool _isLoading = false;
  
  // Contrôleurs pour les informations personnelles
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _regionController = TextEditingController();
  
  // Contrôleurs pour les informations professionnelles
  final _vehiclePlateController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  
  // Contrôleurs pour le PIN
  final _currentPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _showPinChangeForm = false;
  
  // États
  bool _obscureCurrentPin = true;
  bool _obscureNewPin = true;
  bool _obscureConfirmPin = true;

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authProvider);
    if (authState.user != null) {
      _user = authState.user!;
      _initControllers();
    }
  }

  void _initControllers() {
    _fullNameController.text = _user.fullName;
    _emailController.text = _user.email;
    _phoneController.text = _user.phone;
    _addressController.text = _user.address ?? '';
    _cityController.text = _user.city ?? '';
    _regionController.text = _user.region ?? '';
    _vehiclePlateController.text = _user.vehiclePlate ?? '';
    _vehicleModelController.text = _user.vehicleModel ?? '';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _regionController.dispose();
    _vehiclePlateController.dispose();
    _vehicleModelController.dispose();
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    
    final result = await ref.read(authProvider.notifier).updateProfile(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      region: _regionController.text.trim(),
      vehiclePlate: _vehiclePlateController.text.trim(),
      vehicleModel: _vehicleModelController.text.trim(),
    );
    
    setState(() => _isLoading = false);
    
    if (result['success'] == true) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour avec succès'), backgroundColor: Colors.green),
      );
      // Recharger les données
      await ref.read(authProvider.notifier).refreshUser();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _updatePin() async {
    if (_newPinController.text != _confirmPinController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les codes PIN ne correspondent pas'), backgroundColor: Colors.red),
      );
      return;
    }
    
    if (_newPinController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le code PIN doit contenir 6 chiffres'), backgroundColor: Colors.red),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    final result = await ref.read(authProvider.notifier).updatePin(
      currentPin: _currentPinController.text,
      newPin: _newPinController.text,
    );
    
    setState(() => _isLoading = false);
    
    if (result['success'] == true) {
      setState(() => _showPinChangeForm = false);
      _currentPinController.clear();
      _newPinController.clear();
      _confirmPinController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code PIN mis à jour avec succès'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    if (authState.user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    _user = authState.user!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier le profil' : 'Mon profil'),
        backgroundColor: const Color(0xFF0B6E3A),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            TextButton(
              onPressed: _isLoading ? null : _updateProfile,
              child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section photo de profil
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: const Color(0xFF0B6E3A).withAlpha(25),
                          child: _user.profilePhoto != null
                              ? ClipOval(
                                  child: Image.network(
                                    _user.profilePhoto!,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Text(
                                  _user.fullName[0].toUpperCase(),
                                  style: const TextStyle(fontSize: 40, color: Color(0xFF0B6E3A)),
                                ),
                        ),
                        const SizedBox(height: 8),
                        if (_isEditing)
                          TextButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.camera_alt, size: 16),
                            label: const Text('Changer la photo'),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Informations personnelles
                  _SectionHeader(title: 'Informations personnelles', icon: Icons.person),
                  const SizedBox(height: 12),
                  _EditableField(
                    label: 'Nom complet',
                    value: _user.fullName,
                    isEditing: _isEditing,
                    controller: _fullNameController,
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 12),
                  _EditableField(
                    label: 'Email',
                    value: _user.email,
                    isEditing: _isEditing,
                    controller: _emailController,
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  _EditableField(
                    label: 'Téléphone',
                    value: _user.phone,
                    isEditing: _isEditing,
                    controller: _phoneController,
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  _EditableField(
                    label: 'Adresse',
                    value: _user.address ?? 'Non renseigné',
                    isEditing: _isEditing,
                    controller: _addressController,
                    icon: Icons.location_on,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _EditableField(
                          label: 'Ville',
                          value: _user.city ?? 'Non renseigné',
                          isEditing: _isEditing,
                          controller: _cityController,
                          icon: Icons.location_city,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _EditableField(
                          label: 'Région',
                          value: _user.region ?? 'Non renseigné',
                          isEditing: _isEditing,
                          controller: _regionController,
                          icon: Icons.map,
                        ),
                      ),
                    ],
                  ),
                  
                  // Section Code PIN (toujours modifiable hors mode édition)
                  const SizedBox(height: 24),
                  _SectionHeader(title: 'Sécurité', icon: Icons.lock),
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.pin, color: Color(0xFF0B6E3A)),
                      title: const Text('Code PIN'),
                      subtitle: Text(_showPinChangeForm ? 'Modification en cours' : '●●●●●●'),
                      trailing: IconButton(
                        icon: Icon(_showPinChangeForm ? Icons.close : Icons.edit),
                        onPressed: () => setState(() => _showPinChangeForm = !_showPinChangeForm),
                      ),
                    ),
                  ),
                  if (_showPinChangeForm) ...[
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            TextField(
                              controller: _currentPinController,
                              obscureText: _obscureCurrentPin,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              decoration: InputDecoration(
                                labelText: 'Code PIN actuel',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureCurrentPin ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _obscureCurrentPin = !_obscureCurrentPin),
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _newPinController,
                              obscureText: _obscureNewPin,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              decoration: InputDecoration(
                                labelText: 'Nouveau code PIN',
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureNewPin ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _obscureNewPin = !_obscureNewPin),
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _confirmPinController,
                              obscureText: _obscureConfirmPin,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              decoration: InputDecoration(
                                labelText: 'Confirmer le code PIN',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureConfirmPin ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _obscureConfirmPin = !_obscureConfirmPin),
                                ),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => setState(() => _showPinChangeForm = false),
                                    child: const Text('Annuler'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _updatePin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0B6E3A),
                                    ),
                                    child: const Text('Modifier le PIN'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  
                  // Informations professionnelles (selon rôle)
                  if (_user.role == UserRole.driver) ...[
                    const SizedBox(height: 24),
                    _SectionHeader(title: 'Informations véhicule', icon: Icons.directions_car),
                    const SizedBox(height: 12),
                    _EditableField(
                      label: 'Plaque d\'immatriculation',
                      value: _user.vehiclePlate ?? 'Non renseigné',
                      isEditing: _isEditing,
                      controller: _vehiclePlateController,
                      icon: Icons.local_taxi,
                    ),
                    const SizedBox(height: 12),
                    _EditableField(
                      label: 'Modèle du véhicule',
                      value: _user.vehicleModel ?? 'Non renseigné',
                      isEditing: _isEditing,
                      controller: _vehicleModelController,
                      icon: Icons.directions_car,
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Statistiques du compte
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Statistiques du compte', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          _InfoRow(label: 'Date d\'inscription', value: _formatDate(_user.createdAt)),
                          _InfoRow(label: 'Dernière connexion', value: _formatDate(_user.lastLogin)),
                          _InfoRow(label: 'Rôle', value: _user.role.label),
                          _InfoRow(label: 'Statut', value: _user.isActive ? 'Vérifié' : 'Non vérifié'),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Bouton de déconnexion
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(context, '/login');
                        }
                      },
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text('Se déconnecter', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Jamais';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF0B6E3A)),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _EditableField extends StatelessWidget {
  final String label;
  final String value;
  final bool isEditing;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType? keyboardType;

  const _EditableField({
    required this.label,
    required this.value,
    required this.isEditing,
    required this.controller,
    required this.icon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    if (isEditing) {
      return CustomTextField(
        controller: controller,
        label: label,
        prefixIcon: icon,
        keyboardType: keyboardType ?? TextInputType.text,
      );
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}
