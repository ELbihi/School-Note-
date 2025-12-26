import 'dart:io';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBService {
  static final DBService instance = DBService._init();
  static Database? _database;

  DBService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('school.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    bool exists = await databaseExists(path);

    if (!exists) {
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}
      ByteData data = await rootBundle.load(join("assets", "school.db"));
      List<int> bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes, flush: true);
    }
    return await openDatabase(path);
  }

  // ==========================================
  // --- MÉTHODES GÉNÉRIQUES (UTILES) ---
  // ==========================================

  Future<List<Map<String, dynamic>>> getAll(String table,
      {String? orderBy}) async {
    final db = await database;
    return await db.query(table, orderBy: orderBy);
  }

  // ==========================================
  // --- MÉTHODES SQL POUR PROFESSEURS ---
  // ==========================================

  Future<int> addProf(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('PROF', data);
  }

  Future<int> updateProf(int id, Map<String, dynamic> data) async {
    final db = await database;
    return await db.update('PROF', data, where: 'id_prof = ?', whereArgs: [id]);
  }

  Future<int> deleteProf(int id) async {
    final db = await database;
    return await db.delete('PROF', where: 'id_prof = ?', whereArgs: [id]);
  }

  // ==========================================
  // --- MÉTHODES SQL POUR ÉTUDIANTS ---
  // ==========================================

  // Récupère les étudiants avec le NOM de la filière (pour l'affichage)
  Future<List<Map<String, dynamic>>> getStudentsWithFiliere() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT s.*, f.nom_filiere 
      FROM STUDENT s 
      LEFT JOIN FILIERE f ON s.id_filiere = f.id_filiere 
      ORDER BY s.nom ASC
    ''');
  }

  Future<int> addStudent(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('STUDENT', data);
  }

  Future<int> updateStudent(int id, Map<String, dynamic> data) async {
    final db = await database;
    return await db
        .update('STUDENT', data, where: 'id_student = ?', whereArgs: [id]);
  }

  Future<int> deleteStudent(int id) async {
    final db = await database;
    return await db.delete('STUDENT', where: 'id_student = ?', whereArgs: [id]);
  }

  // ==========================================
  // --- MÉTHODES SQL POUR MODULES ---
  // ==========================================

  Future<List<Map<String, dynamic>>> getModulesWithDetails() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT m.*, f.nom_filiere, s.nom_semestre, p.nom || ' ' || p.prenom as prof_nom
      FROM MODULE m
      JOIN FILIERE f ON m.id_filiere = f.id_filiere
      JOIN SEMESTRE s ON m.id_semestre = s.id_semestre
      JOIN PROF p ON m.id_prof = p.id_prof
    ''');
  }

  Future<int> addModule(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('MODULE', data);
  }

  Future<int> updateModule(int id, Map<String, dynamic> data) async {
    final db = await database;
    return await db
        .update('MODULE', data, where: 'id_module = ?', whereArgs: [id]);
  }

  // ==========================================
  // --- MÉTHODES POUR DROPDOWNS ---
  // ==========================================

  Future<List<Map<String, dynamic>>> getAllFilieres() async {
    final db = await database;
    return await db.query('FILIERE', orderBy: 'nom_filiere');
  }

  Future<List<Map<String, dynamic>>> getSemestres() async {
    final db = await database;
    return await db.query('SEMESTRE');
  }

// Dans db_service.dart
  Future<Map<String, dynamic>?> checkLogin(
      String email, String password) async {
    final db = await database;

    // On cherche dans la table PROF si l'email et le mot de passe correspondent
    final List<Map<String, dynamic>> result = await db.query(
      'PROF',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (result.isNotEmpty) {
      return result.first; // Retourne les données du prof trouvé
    }
    return null; // Retourne null si rien n'est trouvé
  }
  // ==========================================
  // --- STATISTIQUES (POUR HOME ADMIN) ---
  // ==========================================

  Future<Map<String, dynamic>> getAdminStats() async {
    final db = await database;

    final teachers =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM PROF')) ??
            0;
    final students = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM STUDENT')) ??
        0;
    final modules = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM MODULE')) ??
        0;
    final filieres = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM FILIERE')) ??
        0;

    return {
      'teachers': teachers,
      'students': students,
      'modules': modules,
      'filieres': filieres,
    };
  }
  // Dans votre classe DBService
Future<void> importJsonData(String tableName, List<dynamic> jsonList) async {
  final db = await database;
  
  // Utilisation d'une transaction pour que tout soit importé ou rien (si erreur)
  await db.transaction((txn) async {
    for (var item in jsonList) {
      // On utilise 'insert' simplement. 
      // Si vous voulez éviter les erreurs de doublons sur l'ID, 
      // utilisez conflictAlgorithm: ConflictAlgorithm.ignore
      await txn.insert(
        tableName, 
        item as Map<String, dynamic>,
        conflictAlgorithm: ConflictAlgorithm.ignore, 
      );
    }
  });
}
}
