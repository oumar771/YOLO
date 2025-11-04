import 'dart:convert';
import '../core/http_client.dart';
import '../core/env.dart';
import '../models/attendance.dart';
import 'local_db.dart';

class AttendanceService {
  final HttpClient _httpClient = HttpClient();
  final LocalDatabase _localDb = LocalDatabase();

  // Récupérer les présences depuis l'API
  Future<List<Attendance>> fetchAttendances({String? employeeId}) async {
    try {
      String endpoint = Environment.ATTENDANCES_ENDPOINT;
      if (employeeId != null) {
        endpoint += '?employee_id=$employeeId';
      }

      final response = await _httpClient.get(endpoint);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final attendances = data.map((json) => Attendance.fromJson(json)).toList();

        // Mettre à jour le cache local
        for (var attendance in attendances) {
          await _localDb.insertAttendance(attendance);
        }

        return attendances;
      } else {
        throw Exception('Erreur lors du chargement des présences');
      }
    } catch (e) {
      // Si erreur réseau, charger depuis cache local
      print('Erreur réseau, chargement depuis cache: $e');
      return await _localDb.getAttendances(employeeId: employeeId);
    }
  }

  // Récupérer depuis cache local uniquement
  Future<List<Attendance>> getLocalAttendances({String? employeeId}) async {
    return await _localDb.getAttendances(employeeId: employeeId);
  }

  // Vider le cache
  Future<void> clearCache() async {
    await _localDb.clearAttendances();
  }

  // Créer une nouvelle présence sur le serveur
  Future<Attendance?> createAttendance({
    required String employeeId,
    required String employeeName,
    required DateTime timestamp,
    required double confidence,
    String? photoUrl,
  }) async {
    try {
      final body = {
        'employee_id': employeeId,
        'employee_name': employeeName,
        'timestamp': timestamp.toIso8601String(),
        'confidence': confidence,
        if (photoUrl != null) 'photo_url': photoUrl,
      };

      final response = await _httpClient.post(
        Environment.ATTENDANCES_ENDPOINT,
        body,
        needsAuth: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final attendance = Attendance.fromJson(data);

        // Sauvegarder dans le cache local
        await _localDb.insertAttendance(attendance);

        print('✅ Présence créée avec succès: ID ${attendance.id}');
        return attendance;
      } else {
        print('❌ Erreur lors de la création: ${response.statusCode} - ${response.body}');
        throw Exception('Erreur lors de la création de la présence: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur réseau lors de la création: $e');

      // En cas d'erreur, sauvegarder localement pour synchronisation ultérieure
      final localAttendance = Attendance(
        id: 0, // ID temporaire
        employeeId: employeeId,
        employeeName: employeeName,
        timestamp: timestamp,
        confidence: confidence,
        photoUrl: photoUrl,
        isSynced: false, // Marquer comme non synchronisé
      );

      await _localDb.insertAttendance(localAttendance);
      print('💾 Présence sauvegardée localement pour synchronisation future');

      return localAttendance;
    }
  }

  // Mettre à jour une présence existante
  Future<Attendance?> updateAttendance({
    required int id,
    String? employeeName,
    DateTime? timestamp,
    double? confidence,
    String? photoUrl,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (employeeName != null) body['employee_name'] = employeeName;
      if (timestamp != null) body['timestamp'] = timestamp.toIso8601String();
      if (confidence != null) body['confidence'] = confidence;
      if (photoUrl != null) body['photo_url'] = photoUrl;

      final response = await _httpClient.put(
        '${Environment.ATTENDANCES_ENDPOINT}/$id',
        body,
        needsAuth: true,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final attendance = Attendance.fromJson(data);

        // Mettre à jour le cache local
        await _localDb.insertAttendance(attendance);

        print('✅ Présence mise à jour avec succès: ID $id');
        return attendance;
      } else {
        print('❌ Erreur lors de la mise à jour: ${response.statusCode}');
        throw Exception('Erreur lors de la mise à jour de la présence');
      }
    } catch (e) {
      print('❌ Erreur réseau lors de la mise à jour: $e');
      rethrow;
    }
  }

  // Supprimer une présence
  Future<bool> deleteAttendance(int id) async {
    try {
      final response = await _httpClient.delete(
        '${Environment.ATTENDANCES_ENDPOINT}/$id',
        needsAuth: true,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ Présence supprimée avec succès: ID $id');
        return true;
      } else {
        print('❌ Erreur lors de la suppression: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Erreur réseau lors de la suppression: $e');
      return false;
    }
  }

  // Créer une présence en mode hors ligne (sera synchronisée plus tard)
  Future<Attendance> createOfflineAttendance({
    required String employeeId,
    required String employeeName,
    required DateTime timestamp,
    required double confidence,
    String? photoUrl,
  }) async {
    final attendance = Attendance(
      id: 0, // ID temporaire
      employeeId: employeeId,
      employeeName: employeeName,
      timestamp: timestamp,
      confidence: confidence,
      photoUrl: photoUrl,
      isSynced: false, // Non synchronisé
    );

    await _localDb.insertAttendance(attendance);
    print('💾 Présence sauvegardée en mode hors ligne');

    return attendance;
  }
}