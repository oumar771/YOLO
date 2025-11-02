import 'dart:convert';
import '../core/http_client.dart';
import '../core/env.dart';
import '../models/auth.dart';
import 'storage_service.dart';

class AuthService {
  final HttpClient _httpClient = HttpClient();
  final StorageService _storage = StorageService();

  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _httpClient.post(
        Environment.LOGIN_ENDPOINT,
        {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(json.decode(response.body));

        // Sauvegarder le token et l'utilisateur
        await _storage.saveToken(authResponse.accessToken);
        await _storage.saveUser(authResponse.user);

        // Configurer le token pour les futures requêtes
        _httpClient.setToken(authResponse.accessToken);

        return authResponse;
      } else if (response.statusCode == 401) {
        throw Exception('Email ou mot de passe incorrect');
      } else {
        throw Exception('Erreur lors de la connexion: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Impossible de se connecter: $e');
    }
  }

  Future<void> logout() async {
    await _storage.clearAll();
    _httpClient.setToken(null);
  }

  Future<User?> getCurrentUser() async {
    return await _storage.getUser();
  }

  Future<bool> isLoggedIn() async {
    return await _storage.isLoggedIn();
  }

  Future<void> initToken() async {
    final token = await _storage.getToken();
    if (token != null) {
      _httpClient.setToken(token);
    }
  }
}