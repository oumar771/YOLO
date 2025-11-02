import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('face_recognition.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textTypeNullable = 'TEXT';
    const integerType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    // Table users (pour le cache utilisateur)
    await db.execute('''
      CREATE TABLE users (
        id $idType,
        name $textType,
        email $textType,
        employee_id $textType,
        department $textTypeNullable,
        photo_url $textTypeNullable,
        created_at $textType,
        updated_at $textType
      )
    ''');

    // Table attendances (présences en cache)
    await db.execute('''
      CREATE TABLE attendances (
        id $idType,
        server_id $integerType DEFAULT 0,
        employee_id $textType,
        employee_name $textType,
        timestamp $textType,
        confidence $realType,
        photo_url $textTypeNullable,
        is_synced $integerType DEFAULT 0,
        synced_at $textTypeNullable,
        created_at $textType
      )
    ''');

    // Table unknown_faces (visages inconnus en cache)
    await db.execute('''
      CREATE TABLE unknown_faces (
        id $idType,
        server_id $integerType DEFAULT 0,
        timestamp $textType,
        photo_url $textTypeNullable,
        confidence $realType,
        is_notified $integerType DEFAULT 0,
        notes $textTypeNullable,
        is_synced $integerType DEFAULT 0,
        created_at $textType
      )
    ''');

    // Table sync_queue (file d'attente synchronisation)
    await db.execute('''
      CREATE TABLE sync_queue (
        id $idType,
        table_name $textType,
        action $textType,
        data $textType,
        retry_count $integerType DEFAULT 0,
        last_error $textTypeNullable,
        created_at $textType
      )
    ''');

    print('✅ Base de données SQLite créée avec succès');
  }

  // Fermer la base
  Future close() async {
    final db = await instance.database;
    db.close();
  }

  // Supprimer la base (pour debug)
  Future deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'face_recognition.db');
    await databaseFactory.deleteDatabase(path);
    print('🗑️ Base de données supprimée');
  }
}