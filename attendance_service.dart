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
}