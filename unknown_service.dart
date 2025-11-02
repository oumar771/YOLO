import 'dart:convert';
import '../core/http_client.dart';
import '../core/env.dart';
import '../models/unknown_face.dart';

class UnknownService {
  final HttpClient _httpClient = HttpClient();

  // Récupérer les visages inconnus
  Future<List<UnknownFace>> fetchUnknownFaces() async {
    try {
      final response = await _httpClient.get(Environment.UNKNOWN_FACES_ENDPOINT);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => UnknownFace.fromJson(json)).toList();
      } else {
        throw Exception('Erreur lors du chargement des visages inconnus');
      }
    } catch (e) {
      throw Exception('Impossible de charger les visages inconnus: $e');
    }
  }

  // Marquer un visage comme traité
  Future<void> markAsProcessed(int id, String notes) async {
    try {
      final response = await _httpClient.put(
        '${Environment.UNKNOWN_FACES_ENDPOINT}/$id',
        {'notes': notes, 'is_notified': true},
      );

      if (response.statusCode != 200) {
        throw Exception('Erreur lors de la mise à jour');
      }
    } catch (e) {
      throw Exception('Impossible de mettre à jour: $e');
    }
  }
}