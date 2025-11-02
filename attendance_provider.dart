import 'package:flutter/material.dart';
import '../models/attendance.dart';
import '../services/attendance_service.dart';

class AttendanceProvider with ChangeNotifier {
  final AttendanceService _service = AttendanceService();

  List<Attendance> _attendances = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Attendance> get attendances => _attendances;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Charger les présences
  Future<void> loadAttendances({String? employeeId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _attendances = await _service.fetchAttendances(employeeId: employeeId);
    } catch (e) {
      _errorMessage = e.toString();
      // Charger depuis cache en cas d'erreur
      _attendances = await _service.getLocalAttendances(employeeId: employeeId);
    }

    _isLoading = false;
    notifyListeners();
  }

  // Rafraîchir
  Future<void> refresh({String? employeeId}) async {
    await loadAttendances(employeeId: employeeId);
  }

  // Statistiques de la semaine
  Map<String, int> getWeeklyStats() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    final stats = <String, int>{};
    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      final dayKey = _getWeekdayName(day.weekday);
      stats[dayKey] = 0;
    }

    for (var attendance in _attendances) {
      if (attendance.timestamp.isAfter(startOfWeek)) {
        final dayKey = _getWeekdayName(attendance.timestamp.weekday);
        stats[dayKey] = (stats[dayKey] ?? 0) + 1;
      }
    }

    return stats;
  }

  String _getWeekdayName(int weekday) {
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return days[weekday - 1];
  }
}