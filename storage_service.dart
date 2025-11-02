import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../models/auth.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final _storage = const FlutterSecureStorage();

  // Sauvegarder le token
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  // Récupérer le token
  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  // Sauvegarder l'utilisateur
  Future<void> saveUser(User user) async {
    final userJson = json.encode(user.toJson());
    await _storage.write(key: 'user_data', value: userJson);
  }

  // Récupérer l'utilisateur
  Future<User?> getUser() async {
    final userJson = await _storage.read(key: 'user_data');
    if (userJson != null) {
      return User.fromJson(json.decode(userJson));
    }
    return null;
  }

  // Supprimer toutes les données (logout)
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // Vérifier si connecté
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}