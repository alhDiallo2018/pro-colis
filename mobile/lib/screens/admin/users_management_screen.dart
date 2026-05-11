import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UsersManagementScreen extends ConsumerStatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  ConsumerState<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends ConsumerState<UsersManagementScreen> {
  String _selectedRole = 'all';
  final List<Map<String, dynamic>> _users = [
    {'id': '1', 'name': 'Mamadou Diallo', 'email': 'mamadou@example.com', 'role': 'client', 'status': 'actif', 'createdAt': '2024-01-15'},
    {'id': '2', 'name': 'Amadou Diop', 'email': 'amadou@example.com', 'role': 'driver', 'status': 'actif', 'createdAt': '2024-02-20'},
    {'id': '3', 'name': 'Fatou Ndiaye', 'email': 'fatou@example.com', 'role': 'client', 'status': 'inactif', 'createdAt': '2024-03-10'},
    {'id': '4', 'name': 'Ibrahima Sow', 'email': 'ibrahima@example.com', 'role': 'admin', 'status': 'actif', 'createdAt': '2024-01-05'},
  ];

  List<Map<String, dynamic>> get _filteredUsers {
    if (_selectedRole == 'all') return _users;
    return _users.where((u) => u['role'] == _selectedRole).toList();
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin': return Colors.purple;
      case 'driver': return Colors.blue;
      case 'client': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des utilisateurs'),
        backgroundColor: const Color(0xFF0B6E3A),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Ajouter un utilisateur
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtres
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(label: 'Tous', value: 'all', selected: _selectedRole == 'all', onSelected: () => setState(() => _selectedRole = 'all')),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Clients', value: 'client', selected: _selectedRole == 'client', onSelected: () => setState(() => _selectedRole = 'client')),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Chauffeurs', value: 'driver', selected: _selectedRole == 'driver', onSelected: () => setState(() => _selectedRole = 'driver')),
                  const SizedBox(width: 8),
                  _FilterChip(label: 'Admins', value: 'admin', selected: _selectedRole == 'admin', onSelected: () => setState(() => _selectedRole = 'admin')),
                ],
              ),
            ),
          ),
          // Liste des utilisateurs
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                final user = _filteredUsers[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getRoleColor(user['role']).withAlpha(25),
                      child: Icon(Icons.person, color: _getRoleColor(user['role'])),
                    ),
                    title: Text(user['name']),
                    subtitle: Text(user['email']),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getRoleColor(user['role']).withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user['role'],
                            style: TextStyle(fontSize: 10, color: _getRoleColor(user['role'])),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user['status'],
                          style: TextStyle(
                            fontSize: 10,
                            color: user['status'] == 'actif' ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      // Voir détails utilisateur
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      backgroundColor: Colors.grey.shade100,
      selectedColor: const Color(0xFF0B6E3A).withAlpha(50),
      checkmarkColor: const Color(0xFF0B6E3A),
    );
  }
}
