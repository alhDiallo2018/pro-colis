import 'dart:io';

import 'package:dotenv/dotenv.dart';

class DatabaseConfig {
  static DatabaseConfig? _instance;

  late final String host;
  late final int port;
  late final String database;
  late final String username;
  late final String password;
  late final bool useSsl;

  DatabaseConfig._internal();

  static Future<DatabaseConfig> getInstance() async {
    if (_instance == null) {
      _instance = DatabaseConfig._internal();
      await _instance!._loadConfig();
    }

    return _instance!;
  }

  Future<void> _loadConfig() async {
    // PRIORITÉ ABSOLUE: Variables d'environnement du système (Render)
    // AVANT de charger .env
    
    String? envHost = Platform.environment['DB_HOST'];
    String? envPort = Platform.environment['DB_PORT'];
    String? envName = Platform.environment['DB_NAME'];
    String? envUser = Platform.environment['DB_USER'];
    String? envPassword = Platform.environment['DB_PASSWORD'];
    
    // Si on est sur Render (DB_HOST existe)
    if (envHost != null && envHost.isNotEmpty) {
      print('🌍 Mode Render détecté - Utilisation variables env système');
      
      host = envHost;
      port = int.parse(envPort ?? '5432');
      database = envName ?? 'procolis_db';
      username = envUser ?? 'procolis_user';
      password = envPassword ?? '';
      useSsl = true; // Render nécessite SSL
      
      print('📋 Database Config Loaded (Render)');
      print('Host: $host');
      print('Port: $port');
      print('Database: $database');
      print('User: $username');
      print('SSL: $useSsl');
      return;
    }
    
    // Fallback: Mode local avec fichier .env
    print('🏠 Mode Local - Chargement depuis .env');
    
    final env = DotEnv(includePlatformEnvironment: false);
    
    try {
      env.load();
      print('✅ Fichier .env chargé');
    } catch (e) {
      print('⚠️ Aucun fichier .env trouvé, utilisation valeurs par défaut');
    }

    host = env['DB_HOST'] ?? 'localhost';
    port = int.parse(env['DB_PORT'] ?? '5432');
    database = env['DB_NAME'] ?? 'procolis_db';
    username = env['DB_USER'] ?? 'postgres';
    password = env['DB_PASSWORD'] ?? '';
    useSsl = host != 'localhost' && host != '127.0.0.1';

    print('📋 Database Config Loaded (Local)');
    print('Host: $host');
    print('Port: $port');
    print('Database: $database');
    print('User: $username');
    print('SSL: $useSsl');
  }
}