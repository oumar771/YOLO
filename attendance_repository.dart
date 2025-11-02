import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../models/attendance.dart';

class AttendanceRepository {
  final database_helper _dbHelper = database_helper.instance;

  // Insérer ou mettre à jour une présence
  Future<int> insertOrUpdate(Attendance attendance) async {
    final db = await _dbHelper.database;

    final map = {
      'server_id': attendance.id,
      'employee_id': attendance.employeeId,
      'employee_name': attendance.employeeName,
      'timestamp': attendance.timestamp.toIso8601String(),
      'confidence': attendance.confidence,
      'photo_url': attendance.photoUrl,
      'is_synced': attendance.isSynced ? 1 : 0,
      'synced_at': attendance.isSynced
          ? DateTime.now().toIso8601String()
          : null,
      'created_at': DateTime.now().toIso8601String(),
    };

    // Vérifier si existe déjà (par server_id)
    if (attendance.id > 0) {
      final existing = await db.query(
        'attendances',
        where: 'server_id = ?',
        whereArgs: [attendance.id],
      );

      if (existing.isNotEmpty) {
        // Mettre à jour
        return await db.update(
          'attendances',
          map,
          where: 'server_id = ?',
          whereArgs: [attendance.id],
        );
      }
    }

    // Insérer nouveau
    return await db.insert('attendances', map);
  }

  // Récupérer toutes les présences
  Future<List<Attendance>> getAll({String? employeeId}) async {
    final db = await _dbHelper.database;

    List<Map<String, dynamic>> maps;

    if (employeeId != null) {
      maps = await db.query(
        'attendances',
        where: 'employee_id = ?',
        whereArgs: [employeeId],
        orderBy: 'timestamp DESC',
      );
    } else {
      maps = await db.query(
        'attendances',
        orderBy: 'timestamp DESC',
      );
    }

    return List.generate(maps.length, (i) {
      return Attendance(
        id: maps[i]['server_id'] as int,
        employeeId: maps[i]['employee_id'] as String,
        employeeName: maps[i]['employee_name'] as String,
        timestamp: DateTime.parse(maps[i]['timestamp'] as String),
        confidence: maps[i]['confidence'] as double,
        photoUrl: maps[i]['photo_url'] as String?,
        isSynced: (maps[i]['is_synced'] as int) == 1,
      );
    });
  }

  // Récupérer présences non synchronisées
  Future<List<Attendance>> getUnsyncedAttendances() async {
    final db = await _dbHelper.database;

    final maps = await db.query(
      'attendances',
      where: 'is_synced = ?',
      whereArgs: [0],
      orderBy: 'created_at ASC',
    );

    return List.generate(maps.length, (i) {
      return Attendance(
        id: maps[i]['server_id'] as int,
        employeeId: maps[i]['employee_id'] as String,
        employeeName: maps[i]['employee_name'] as String,
        timestamp: DateTime.parse(maps[i]['timestamp'] as String),
        confidence: maps[i]['confidence'] as double,
        photoUrl: maps[i]['photo_url'] as String?,
        isSynced: false,
      );
    });
  }

  // Marquer comme synchronisé
  Future<void> markAsSynced(int localId) async {
    final db = await _dbHelper.database;

    await db.update(
      'attendances',
      {
        'is_synced': 1,
        'synced_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  // Vider le cache (pour tests)
  Future<void> clearAll() async {
    final db = await _dbHelper.database;
    await db.delete('attendances');
    print('🗑️ Cache présences vidé');
  }

  // Compter les présences
  Future<int> count() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM attendances');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}