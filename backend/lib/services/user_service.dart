// ignore: unused_import
import 'dart:convert';

import 'package:bcrypt/bcrypt.dart';
import 'package:uuid/uuid.dart';

class User {
  final String id;
  final String email;
  final String phone;
  final String fullName;
  final String? passwordHash;
  final String role;
  final String? garageId;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final DateTime createdAt;
  final DateTime? lastLogin;

  User({
    required this.id,
    required this.email,
    required this.phone,
    required this.fullName,
    this.passwordHash,
    required this.role,
    this.garageId,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    required this.createdAt,
    this.lastLogin,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'phone': phone,
    'fullName': fullName,
    'role': role,
    'garageId': garageId,
    'isEmailVerified': isEmailVerified,
    'isPhoneVerified': isPhoneVerified,
    'createdAt': createdAt.toIso8601String(),
    'lastLogin': lastLogin?.toIso8601String(),
  };
}

class UserService {
  final List<User> _users = [];
  final _uuid = const Uuid();
  
  Future<User> createUser({
    required String email,
    required String phone,
    required String fullName,
    String? password,
    String role = 'client',
  }) async {
    final user = User(
      id: _uuid.v4(),
      email: email,
      phone: phone,
      fullName: fullName,
      passwordHash: password != null ? BCrypt.hashpw(password, BCrypt.gensalt()) : null,
      role: role,
      createdAt: DateTime.now(),
    );
    
    _users.add(user);
    return user;
  }
  
  Future<User?> findByEmail(String email) async {
    try {
      return _users.firstWhere((u) => u.email == email);
    } catch (e) {
      return null;
    }
  }
  
  Future<User?> findByPhone(String phone) async {
    try {
      return _users.firstWhere((u) => u.phone == phone);
    } catch (e) {
      return null;
    }
  }
  
  Future<User?> getUser(String id) async {
    try {
      return _users.firstWhere((u) => u.id == id);
    } catch (e) {
      return null;
    }
  }
  
  Future<User?> getUserByEmailOrPhone(String identifier) async {
    User? user = await findByEmail(identifier);
    if (user == null) {
      user = await findByPhone(identifier);
    }
    return user;
  }
  
  Future<User?> updateUser(String id, Map<String, dynamic> data) async {
    final index = _users.indexWhere((u) => u.id == id);
    if (index == -1) return null;
    
    final oldUser = _users[index];
    final updatedUser = User(
      id: oldUser.id,
      email: data['email'] ?? oldUser.email,
      phone: data['phone'] ?? oldUser.phone,
      fullName: data['fullName'] ?? oldUser.fullName,
      passwordHash: data['password'] != null 
          ? BCrypt.hashpw(data['password'], BCrypt.gensalt())
          : oldUser.passwordHash,
      role: data['role'] ?? oldUser.role,
      garageId: data['garageId'] ?? oldUser.garageId,
      isEmailVerified: data['isEmailVerified'] ?? oldUser.isEmailVerified,
      isPhoneVerified: data['isPhoneVerified'] ?? oldUser.isPhoneVerified,
      createdAt: oldUser.createdAt,
      lastLogin: DateTime.now(),
    );
    
    _users[index] = updatedUser;
    return updatedUser;
  }
  
  Future<void> updateLastLogin(String userId) async {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      _users[index] = User(
        id: _users[index].id,
        email: _users[index].email,
        phone: _users[index].phone,
        fullName: _users[index].fullName,
        passwordHash: _users[index].passwordHash,
        role: _users[index].role,
        garageId: _users[index].garageId,
        isEmailVerified: _users[index].isEmailVerified,
        isPhoneVerified: _users[index].isPhoneVerified,
        createdAt: _users[index].createdAt,
        lastLogin: DateTime.now(),
      );
    }
  }
  
  Future<Map<String, dynamic>> getAllUsers({
    int page = 1,
    int limit = 20,
    String? role,
    String? status,
    String? search,
  }) async {
    List<User> filtered = List.from(_users);
    
    if (role != null) {
      filtered = filtered.where((u) => u.role == role).toList();
    }
    
    if (search != null) {
      filtered = filtered.where((u) => 
        u.fullName.toLowerCase().contains(search.toLowerCase()) ||
        u.email.toLowerCase().contains(search.toLowerCase()) ||
        u.phone.contains(search)
      ).toList();
    }
    
    final total = filtered.length;
    final pages = (total / limit).ceil();
    final start = (page - 1) * limit;
    final end = start + limit;
    final paginated = filtered.sublist(start, end > total ? total : end);
    
    return {
      'users': paginated.map((u) => u.toJson()).toList(),
      'total': total,
      'pages': pages,
    };
  }
  
  Future<User?> updateUserRole(String id, String newRole) async {
    return await updateUser(id, {'role': newRole});
  }
  
  Future<bool> deleteUser(String id) async {
    final index = _users.indexWhere((u) => u.id == id);
    if (index == -1) return false;
    _users.removeAt(index);
    return true;
  }
  
  Future<void> invalidateTokens(String userId) async {
    // Dans une implémentation réelle, on invaliderait les tokens dans Redis/DB
  }
  
  Future<bool> verifyPassword(String email, String password) async {
    final user = await findByEmail(email);
    if (user == null || user.passwordHash == null) return false;
    return BCrypt.checkpw(password, user.passwordHash!);
  }
}
