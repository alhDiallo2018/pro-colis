import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user.dart';
import '../../providers/auth_provider.dart';
// ignore: unused_import
import '../../providers/parcel_provider.dart';
// ignore: unused_import
import '../parcel/new_parcel_screen.dart';
// ignore: unused_import
import '../parcel/track_parcel_screen.dart';
// ignore: unused_import
import '../profile/profile_screen.dart';
import 'admin_dashboard.dart';
import 'client_dashboard.dart';
import 'driver_dashboard.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Utilisateur non trouvé')),
      );
    }
    
    // Rediriger vers le dashboard selon le rôle
    switch (user.role) {
      case UserRole.driver:
        return const DriverDashboard();
      case UserRole.admin:
      case UserRole.superAdmin:
        return const AdminDashboard();
      default:
        return const ClientDashboard();
    }
  }
}
