import 'dart:io';

import 'package:dotenv/dotenv.dart' show DotEnv;

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
    _instance ??= DatabaseConfig._internal();
    await _instance!._loadConfig();
    return _instance!;
  }

  Future<void> _loadConfig() async {
    // Variables d'environnement Render
    final envHost = Platform.environment['DB_HOST'];
    final envPort = Platform.environment['DB_PORT'];
    final envDatabase =
        Platform.environment['DB_DATABASE'] ??
        Platform.environment['DB_NAME'];
    final envUsername =
        Platform.environment['DB_USERNAME'] ??
        Platform.environment['DB_USER'];
    final envPassword = Platform.environment['DB_PASSWORD'];

    if (envHost != null && envHost.isNotEmpty) {
      print('🌍 Configuration Supabase depuis Render');

      host = envHost;
      port = int.tryParse(envPort ?? '5432') ?? 5432;
      database = envDatabase ?? 'postgres';
      username = envUsername ?? 'postgres';
      password = envPassword ?? '';
      useSsl = true;

      _printConfig();
      return;
    }

    // Développement local (.env)
    final env = DotEnv(includePlatformEnvironment: false);

    try {
      env.load();
      print('🏠 Configuration locale (.env)');
    } catch (_) {
      print('⚠️ Aucun fichier .env trouvé');
    }

    host = env['DB_HOST'] ?? 'localhost';
    port = int.tryParse(env['DB_PORT'] ?? '5432') ?? 5432;
    database = env['DB_DATABASE'] ?? env['DB_NAME'] ?? 'postgres';
    username = env['DB_USERNAME'] ?? env['DB_USER'] ?? 'postgres';
    password = env['DB_PASSWORD'] ?? '';

    // SSL obligatoire pour Supabase
    useSsl = host.contains('supabase.co') ||
        (host != 'localhost' && host != '127.0.0.1');

    _printConfig();
  }

  void _printConfig() {
    print('📋 Database Config');
    print('Host: $host');
    print('Port: $port');
    print('Database: $database');
    print('Username: $username');
    print('SSL: $useSsl');
  }
}