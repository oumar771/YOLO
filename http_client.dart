import 'dart:convert';
import 'package:http/http.dart' as http;
import 'env.dart';

class HttpClient {
  final http.Client _client = http.Client();
  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> _getHeaders({bool needsAuth = false}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (needsAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    return headers;
  }

  Future<http.Response> get(String endpoint, {bool needsAuth = true}) async {
    try {
      final url = Uri.parse('${Environment.BASE_URL}$endpoint');
      final response = await _client
          .get(url, headers: _getHeaders(needsAuth: needsAuth))
          .timeout(Environment.TIMEOUT);
      return response;
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  Future<http.Response> post(
      String endpoint,
      dynamic body, {
        bool needsAuth = false,
      }) async {
    try {
      final url = Uri.parse('${Environment.BASE_URL}$endpoint');
      final response = await _client
          .post(
        url,
        headers: _getHeaders(needsAuth: needsAuth),
        body: json.encode(body),
      )
          .timeout(Environment.TIMEOUT);
      return response;
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  Future<http.Response> put(
      String endpoint,
      dynamic body, {
        bool needsAuth = true,
      }) async {
    try {
      final url = Uri.parse('${Environment.BASE_URL}$endpoint');
      final response = await _client
          .put(
        url,
        headers: _getHeaders(needsAuth: needsAuth),
        body: json.encode(body),
      )
          .timeout(Environment.TIMEOUT);
      return response;
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  Future<http.Response> delete(String endpoint, {bool needsAuth = true}) async {
    try {
      final url = Uri.parse('${Environment.BASE_URL}$endpoint');
      final response = await _client
          .delete(url, headers: _getHeaders(needsAuth: needsAuth))
          .timeout(Environment.TIMEOUT);
      return response;
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}