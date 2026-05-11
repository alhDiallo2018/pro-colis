import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import '../profile/profile_screen.dart';
import '../admin/users_management_screen.dart';
import '../admin/garages_management_screen.dart';
import '../admin/stats_screen.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isSuperAdmin = user?.role == UserRole.superAdmin;

    return Scaffold(
      body: _getScreen(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFF0B6E3A),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          const BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Utilisateurs'),
          if (isSuperAdmin)
            const BottomNavigationBarItem(icon: Icon(Icons.business), label: 'Garages'),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return const AdminStatsScreen();
      case 1:
        return const UsersManagementScreen();
      case 2:
        return const GaragesManagementScreen();
      case 3:
        return const ProfileScreen();
      default:
        return const AdminStatsScreen();
    }
  }
}
