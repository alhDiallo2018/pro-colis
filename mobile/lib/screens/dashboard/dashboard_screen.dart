import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.read(authProvider).user;
    return Scaffold(
      appBar: AppBar(title: const Text('PRO COLIS'), backgroundColor: const Color(0xFF0B6E3A)),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.check_circle, size: 80, color: Color(0xFF0B6E3A)),
          const SizedBox(height: 24),
          Text('Bienvenue ${user?.fullName ?? ""} !', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('Vous êtes connecté avec succès'),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Se déconnecter', style: TextStyle(color: Colors.white)),
          ),
        ]),
      ),
    );
  }
}
