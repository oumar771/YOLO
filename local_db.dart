import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/attendance.dart';

class LocalDatabase {
  static final LocalDatabase _instance = LocalDatabase._internal();
  factory LocalDatabase() => _instance;
  LocalDatabase._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'face_attendance.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE attendances(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id TEXT NOT NULL,
        employee_name TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        confidence REAL NOT NULL,
        photo_url TEXT,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  // Insérer une présence en cache
  Future<int> insertAttendance(Attendance attendance) async {
    final db = await database;
    return await db.insert(
      'attendances',
      attendance.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Récupérer toutes les présences en cache
  Future<List<Attendance>> getAttendances({String? employeeId}) async {
    final db = await database;

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
      return Attendance.fromMap(maps[i]);
    });
  }

  // Supprimer toutes les présences
  Future<void> clearAttendances() async {
    final db = await database;
    await db.delete('attendances');
  }

  // Marquer comme synchronisé
  Future<void> markAsSynced(int id) async {
    final db = await database;
    await db.update(
      'attendances',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}