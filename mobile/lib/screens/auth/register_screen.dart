import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'otp_verification_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les mots de passe ne correspondent pas'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isLoading = true);
    final result = await ref.read(authProvider.notifier).register(
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      fullName: _fullNameController.text.trim(),
      password: _passwordController.text,
    );
    setState(() => _isLoading = false);
    if (result['success'] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerificationScreen(
            userId: result['userId'],
            identifier: _emailController.text.trim(),
            isLogin: false,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inscription'), backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text('Créer un compte', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Remplissez vos informations pour commencer'),
            const SizedBox(height: 32),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  CustomTextField(
                    controller: _fullNameController,
                    label: 'Nom complet',
                    prefixIcon: Icons.person,
                    validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _emailController,
                    label: 'Email',
                    prefixIcon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v == null || !v.contains('@') ? 'Email valide requis' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _phoneController,
                    label: 'Téléphone',
                    prefixIcon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Mot de passe',
                    prefixIcon: Icons.lock,
                    suffixIcon: _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    onSuffixPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    obscureText: _obscurePassword,
                    validator: (v) => v == null || v.length < 6 ? 'Min 6 caractères' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirmer mot de passe',
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                    onSuffixPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    obscureText: _obscureConfirmPassword,
                    validator: (v) => v == null || v.length < 6 ? 'Min 6 caractères' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            CustomButton(text: 'S\'inscrire', onPressed: _register, isLoading: _isLoading),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Déjà un compte ? ', style: TextStyle(color: Colors.grey[600])),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Se connecter', style: TextStyle(color: Color(0xFF0B6E3A))),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
