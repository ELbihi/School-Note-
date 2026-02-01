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

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    final db = await database;

    // Recherche dans la table USER
    final userResult = await db.query(
      'USER',
      where: 'email = ? AND password = ? AND is_deleted = 0',
      whereArgs: [email, password],
    );

    if (userResult.isEmpty) {
      return null;
    }

    final user = userResult.first;
    final role = user['role'] as String;
    final refId = user['ref_id'] as int?;

    if (refId == null) {
      return null;
    }

    // Récupérer les données spécifiques selon le rôle
    switch (role) {
      case 'ADMIN':
        final adminResult = await db.query(
          'ADMIN',
          where: 'id_admin = ? AND is_deleted = 0',
          whereArgs: [refId],
        );
        if (adminResult.isNotEmpty) {
          return {
            ...adminResult.first,
            'role': 'ADMIN',
            'user_id': user['id_user'],
          };
        }
        break;

      case 'PROF':
        final profResult = await db.query(
          'PROF',
          where: 'id_prof = ? AND is_deleted = 0',
          whereArgs: [refId],
        );
        if (profResult.isNotEmpty) {
          return {
            ...profResult.first,
            'role': 'PROF',
            'user_id': user['id_user'],
          };
        }
        break;

      case 'STUDENT':
        final studentResult = await db.query(
          'STUDENT',
          where: 'id_student = ? AND is_deleted = 0',
          whereArgs: [refId],
        );
        if (studentResult.isNotEmpty) {
          return {
            ...studentResult.first,
            'role': 'STUDENT',
            'user_id': user['id_user'],
          };
        }
        break;
    }

    return null;
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
  // --- MÉTHODES GÉNÉRIQUES ---
  // ==========================================

  Future<List<Map<String, dynamic>>> getAll(String table,
      {String? orderBy}) async {
    final db = await database;
    return await db.query(table, orderBy: orderBy);
  }

  Future<void> importJsonData(String tableName, List<dynamic> jsonList) async {
    final db = await database;
    await db.transaction((txn) async {
      for (var item in jsonList) {
        await txn.insert(
          tableName,
          item as Map<String, dynamic>,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    });
  }

  // ==========================================
  // --- AUTHENTIFICATION ---
  // ==========================================

  Future<Map<String, dynamic>?> checkLogin(
      String email, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'PROF',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // ==========================================
  // --- GESTION DES PROFESSEURS (ADMIN) ---
  // ==========================================
// Dans lib/services/db_service.dart

  Future<int> addProf(Map<String, dynamic> data) async {
    final db = await database;
    return await db.transaction((txn) async {
      // 1. Insérer dans la table PROF
      int profId = await txn.insert('PROF', {
        'nom': data['nom'],
        'prenom': data['prenom'],
        'email': data['email'],
        'is_deleted': 0,
        'sync_status': 'pending',
        'updated_at': DateTime.now().toIso8601String(),
      });

      // 2. Insérer dans la table USER pour permettre la connexion
      await txn.insert('USER', {
        'email': data['email'],
        'password': data['password'],
        'role': 'PROF',
        'ref_id': profId, // Lien vers l'ID du prof
        'is_deleted': 0,
        'sync_status': 'pending',
        'updated_at': DateTime.now().toIso8601String(),
      });

      return profId;
    });
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
  // --- GESTION DES ÉTUDIANTS (ADMIN & PROF) ---
  // ==========================================

  Future<List<Map<String, dynamic>>> getStudentsWithFiliere() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT s.*, f.nom_filiere 
      FROM STUDENT s 
      LEFT JOIN FILIERE f ON s.id_filiere = f.id_filiere 
      ORDER BY s.nom ASC
    ''');
  }

  // Dans lib/services/db_service.dart

  Future<int> addStudent(Map<String, dynamic> data) async {
    final db = await database;
    return await db.transaction((txn) async {
      // 1. Insertion dans la table STUDENT
      // Note : On retire 'password' des données de l'étudiant car il va dans USER
      int studentId = await txn.insert('STUDENT', {
        'massar': data['massar'],
        // Vérifiez si votre colonne s'appelle 'cne' ou 'massar'
        'nom': data['nom'],
        'prenom': data['prenom'],
        'email': data['email'],
        'id_filiere': data['id_filiere'],
        'niveau': data['niveau'],
        'groupe': data['groupe'],
        'is_deleted': 0,
        'sync_status': 'pending',
        'updated_at': DateTime.now().toIso8601String(),
      });

      // 2. Insertion dans la table USER pour l'authentification
      await txn.insert('USER', {
        'email': data['email'],
        'password': data['password'], // Le mot de passe saisi ou '123456'
        'role': 'STUDENT',
        'ref_id': studentId, // Lien vers l'ID de l'étudiant
        'is_deleted': 0,
        'sync_status': 'pending',
        'updated_at': DateTime.now().toIso8601String(),
      });

      return studentId;
    });
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

  Future<bool> emailExists(String email) async {
    final db = await database;
    var result =
        await db.query('STUDENT', where: 'email = ?', whereArgs: [email]);
    return result.isNotEmpty;
  }

  Future<bool> codeMassarExists(String codeMassar) async {
    final db = await database;
    var result =
        await db.query('STUDENT', where: 'massar = ?', whereArgs: [codeMassar]);
    return result.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getStudentsByFiliereAndNiveau(
      int idFiliere, int niveau) async {
    final db = await database;
    return await db.query('STUDENT',
        where: 'id_filiere = ? AND niveau = ?',
        whereArgs: [idFiliere, niveau],
        orderBy: 'nom ASC');
  }

  // ==========================================
  // --- GESTION DES MODULES & FILIÈRES ---
  // ==========================================

  // Dans db_service.dart, modifiez cette méthode pour inclure les IDs
  Future<List<Map<String, dynamic>>> getModulesWithDetails() async {
    final db = await database;
    return await db.rawQuery('''
    SELECT 
      m.id_module, 
      m.nom_module, 
      m.coefficient, 
      m.id_filiere, 
      m.id_semestre, 
      m.id_prof,
      f.nom_filiere, 
      s.nom_semestre, 
      p.nom || ' ' || p.prenom as prof_nom
    FROM MODULE m
    LEFT JOIN FILIERE f ON m.id_filiere = f.id_filiere
    LEFT JOIN SEMESTRE s ON m.id_semestre = s.id_semestre
    LEFT JOIN PROF p ON m.id_prof = p.id_prof
    ORDER BY m.nom_module
  ''');
  }

  Future<List<Map<String, dynamic>>> getModulesByProf(int profId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT m.id_module, m.nom_module, m.id_filiere, f.nom_filiere, s.nom_semestre, s.annee
      FROM MODULE m
      LEFT JOIN FILIERE f ON m.id_filiere = f.id_filiere
      LEFT JOIN SEMESTRE s ON m.id_semestre = s.id_semestre
      WHERE m.id_prof = ?
    ''', [profId]);
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

  Future<List<Map<String, dynamic>>> getAllFilieres() async {
    final db = await database;
    return await db.query('FILIERE', orderBy: 'nom_filiere ASC');
  }

  Future<Map<String, dynamic>?> getFiliereByName(String nomFiliere) async {
    final db = await database;
    var result = await db
        .query('FILIERE', where: 'nom_filiere = ?', whereArgs: [nomFiliere]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> createFiliere(String nomFiliere) async {
    final db = await database;
    return await db.insert('FILIERE', {'nom_filiere': nomFiliere});
  }

  Future<List<Map<String, dynamic>>> getSemestres() async {
    final db = await database;
    return await db.query('SEMESTRE');
  }

  // ==========================================
  // --- GESTION DES NOTES ---
  // ==========================================

  Future<List<Map<String, dynamic>>> getGradesForModule(
      int idModule, int idFiliere, String anneeModule) async {
    final db = await database;
    String niveauCible = "CP$anneeModule";
    return await db.rawQuery('''
      SELECT s.id_student, s.nom, s.prenom, s.groupe, n.controle, n.tp, n.examen, n.projet 
      FROM STUDENT s
      LEFT JOIN NOTE n ON s.id_student = n.id_student AND n.id_module = ?
      WHERE (s.id_filiere = ?) OR (s.id_filiere IS NULL AND s.niveau = ?)
      ORDER BY s.nom ASC
    ''', [idModule, idFiliere, niveauCible]);
  }

  Future<void> saveGrade(int idStudent, int idModule, double? controle,
      double? tp, double? projet, double? examen) async {
    final db = await database;
    var result = await db.query('NOTE',
        where: 'id_student = ? AND id_module = ?',
        whereArgs: [idStudent, idModule]);

    if (result.isNotEmpty) {
      await db.update('NOTE',
          {'controle': controle, 'tp': tp, 'projet': projet, 'examen': examen},
          where: 'id_student = ? AND id_module = ?',
          whereArgs: [idStudent, idModule]);
    } else {
      await db.insert('NOTE', {
        'id_student': idStudent,
        'id_module': idModule,
        'controle': controle,
        'tp': tp,
        'projet': projet,
        'examen': examen,
        'moyenne': 0.0,
        'resultat': 'NV'
      });
    }
  }

  Future<List<Map<String, dynamic>>> getAllGrades() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT s.nom, s.prenom, s.massar, m.nom_module, n.controle as note 
      FROM STUDENT s
      JOIN NOTE n ON s.id_student = n.id_student
      JOIN MODULE m ON n.id_module = m.id_module
      ORDER BY s.nom ASC
    ''');
  }

  // ==========================================
  // --- STATISTIQUES ---
  // ==========================================

  Future<Map<String, dynamic>> getAdminStats() async {
    final db = await instance.database;

    final results = await Future.wait([
      db.rawQuery('SELECT COUNT(*) as count FROM PROF'),
      db.rawQuery('SELECT COUNT(*) as count FROM STUDENT'),
      db.rawQuery('SELECT COUNT(*) as count FROM MODULE'),
      db.rawQuery('SELECT COUNT(*) as count FROM FILIERE'),
    ]);

    return {
      'teachers': Sqflite.firstIntValue(results[0]) ?? 0,
      'students': Sqflite.firstIntValue(results[1]) ?? 0,
      'modules': Sqflite.firstIntValue(results[2]) ?? 0,
      'filieres': Sqflite.firstIntValue(results[3]) ?? 0,
    };
  }

  Future<Map<String, dynamic>> getProfStatistics(int profId) async {
    final db = await database;
    Map<String, dynamic> stats = {
      'module_count': 0,
      'filiere_count': 0,
      'student_count': 0
    };
    try {
      var modRes = await db.rawQuery(
          'SELECT COUNT(*) as count FROM MODULE WHERE id_prof = ?', [profId]);
      stats['module_count'] = Sqflite.firstIntValue(modRes) ?? 0;

      var filRes = await db.rawQuery(
          'SELECT COUNT(DISTINCT id_filiere) FROM MODULE WHERE id_prof = ?',
          [profId]);
      stats['filiere_count'] = Sqflite.firstIntValue(filRes) ?? 0;

      var stuRes = await db.rawQuery('''
        SELECT COUNT(DISTINCT s.id_student) FROM STUDENT s
        JOIN MODULE m ON s.id_filiere = m.id_filiere WHERE m.id_prof = ?
      ''', [profId]);
      stats['student_count'] = Sqflite.firstIntValue(stuRes) ?? 0;
    } catch (e) {
      print(e);
    }
    return stats;
  }

  // À ajouter dans db_service.dart
  Future<List<Map<String, dynamic>>> getStudentsForModuleSmart(
      int idFiliere, String anneeModule) async {
    final db = await database;

    // Cette logique reprend celle de votre méthode getGradesForModule
    // Elle cherche les étudiants par filière OU par niveau (CP1, CP2...) si la filière est nulle
    String niveauCible = "CP$anneeModule";

    return await db.query('STUDENT',
        where: '(id_filiere = ?) OR (id_filiere IS NULL AND niveau = ?)',
        whereArgs: [idFiliere, niveauCible],
        orderBy: 'nom ASC');
  }

  // À ajouter dans db_service.dart
  // Future<List<Map<String, dynamic>>> getStudentFullGrades(
  //     int idEtudiant) async {
  //   final db = await instance.database;
  //   return await db.rawQuery('''
  //   SELECT
  //     m.nom_module,
  //     n.controle,
  //     n.tp,
  //     n.projet,
  //     n.examen,
  //     n.moyenne
  //   FROM notes n
  //   INNER JOIN modules m ON n.id_module = m.id_module
  //   WHERE n.id_etudiant = ?
  // ''', [idEtudiant]);
  // }
  Future<List<Map<String, dynamic>>> getStudentFullGrades(int idStudent) async {
    final db = await database;

    return await db.rawQuery('''
    SELECT 
      s.nom_semestre,
      m.nom_module,
      m.coefficient,
      n.controle,
      n.tp,
      n.projet,
      n.examen,
      n.moyenne,
      n.resultat
    FROM NOTE n
    JOIN MODULE m ON n.id_module = m.id_module
    JOIN SEMESTRE s ON m.id_semestre = s.id_semestre
    WHERE n.id_student = ?
      AND n.is_deleted = 0
    ORDER BY s.id_semestre, m.nom_module
  ''', [idStudent]);
  }

  // Future<List<Map<String, dynamic>>> getModulesAverages(int idProf) async {
  //   final db = await instance.database;

  //   // On utilise la même pondération que dans AddGradePage :
  //   // Ctl (15%) + TP (15%) + Proj (20%) + Exam (50%)
  //   return await db.rawQuery('''
  //   SELECT
  //     m.id_module,
  //     m.nom_module,
  //     f.nom_filiere,
  //     AVG(
  //       (COALESCE(n.controle, 0) * 0.15) +
  //       (COALESCE(n.tp, 0) * 0.15) +
  //       (COALESCE(n.projet, 0) * 0.20) +
  //       (COALESCE(n.examen, 0) * 0.50)
  //     ) as moyenne_generale
  //   FROM modules m
  //   INNER JOIN filieres f ON m.id_filiere = f.id_filiere
  //   LEFT JOIN notes n ON m.id_module = n.id_module
  //   WHERE m.id_prof = ?
  //   GROUP BY m.id_module, m.nom_module, f.nom_filiere
  // ''', [idProf]);
  // }

  Future<List<Map<String, dynamic>>> getModulesAverages(int idProf) async {
    final db = await database;

    return await db.rawQuery('''
    SELECT 
      m.id_module,
      m.nom_module,
      f.nom_filiere,
      AVG(
        (COALESCE(n.controle, 0) * 0.15) + 
        (COALESCE(n.tp, 0) * 0.15) + 
        (COALESCE(n.projet, 0) * 0.20) + 
        (COALESCE(n.examen, 0) * 0.50)
      ) AS moyenne_generale
    FROM MODULE m
    JOIN FILIERE f ON m.id_filiere = f.id_filiere
    LEFT JOIN NOTE n ON m.id_module = n.id_module
    WHERE m.id_prof = ?
    GROUP BY m.id_module, m.nom_module, f.nom_filiere
  ''', [idProf]);
  }

  // Dans votre DBService
  Future<List<Map<String, dynamic>>> getEtudiantsParFiliereEtNiveau(
      int idF, int niveau) async {
    final db = await instance.database;
    return await db.query(
      'STUDENT',
      where:
          'id_filiere = ? AND niveau = ?', // Utilisez bien 'id_filiere' et 'niveau'
      whereArgs: [idF, niveau],
    );
  }
  // pouuuuuuur student

  // ==========================================
// --- MÉTHODES POUR ÉTUDIANT ---
// ==========================================

// Méthode pour récupérer les informations complètes d'un étudiant
  Future<Map<String, dynamic>?> getStudentInfo(int studentId) async {
    final db = await database;
    final result = await db.rawQuery('''
    SELECT s.*, f.nom_filiere 
    FROM STUDENT s 
    LEFT JOIN FILIERE f ON s.id_filiere = f.id_filiere 
    WHERE s.id_student = ? AND s.is_deleted = 0
  ''', [studentId]);

    return result.isNotEmpty ? result.first : null;
  }

// Méthode pour récupérer les modules d'un étudiant
  Future<List<Map<String, dynamic>>> getStudentModules(int studentId) async {
    final db = await database;
    return await db.rawQuery('''
    SELECT 
      m.id_module,
      m.nom_module,
      m.coefficient,
      s.nom_semestre,
      s.annee,
      p.nom as prof_nom,
      p.prenom as prof_prenom
    FROM MODULE m
    INNER JOIN FILIERE f ON m.id_filiere = f.id_filiere
    INNER JOIN SEMESTRE s ON m.id_semestre = s.id_semestre
    LEFT JOIN PROF p ON m.id_prof = p.id_prof
    WHERE m.id_filiere = (
      SELECT id_filiere FROM STUDENT WHERE id_student = ?
    )
    AND m.is_deleted = 0
    ORDER BY s.annee DESC, s.nom_semestre
  ''', [studentId]);
  }

// Méthode pour récupérer les notes d'un étudiant par module
  Future<List<Map<String, dynamic>>> getStudentNotesWithModules(
      int studentId) async {
    final db = await database;
    return await db.rawQuery('''
    SELECT 
      m.nom_module,
      m.coefficient,
      n.controle,
      n.tp,
      n.projet,
      n.examen,
      n.moyenne,
      n.resultat,
      s.nom_semestre,
      s.annee
    FROM NOTE n
    INNER JOIN MODULE m ON n.id_module = m.id_module
    INNER JOIN SEMESTRE s ON m.id_semestre = s.id_semestre
    WHERE n.id_student = ? 
    AND n.is_deleted = 0
    ORDER BY s.annee DESC, s.nom_semestre, m.nom_module
  ''', [studentId]);
  }

// Méthode pour calculer les statistiques de l'étudiant
  Future<Map<String, dynamic>> getStudentStats(int studentId) async {
    final db = await database;

    final modulesResult = await db.rawQuery('''
    SELECT COUNT(DISTINCT m.id_module) as count
    FROM MODULE m
    WHERE m.id_filiere = (
      SELECT id_filiere FROM STUDENT WHERE id_student = ?
    )
  ''', [studentId]);

    final semestresResult = await db.rawQuery('''
    SELECT COUNT(DISTINCT s.id_semestre) as count
    FROM MODULE m
    INNER JOIN SEMESTRE s ON m.id_semestre = s.id_semestre
    WHERE m.id_filiere = (
      SELECT id_filiere FROM STUDENT WHERE id_student = ?
    )
  ''', [studentId]);

    final notesResult = await db.rawQuery('''
    SELECT 
      COUNT(*) as note_count,
      AVG(n.moyenne) as avg_moyenne,
      SUM(CASE WHEN n.resultat = 'V' THEN 1 ELSE 0 END) as passed_count
    FROM NOTE n
    WHERE n.id_student = ?
  ''', [studentId]);

    return {
      'module_count': Sqflite.firstIntValue(modulesResult) ?? 0,
      'semestre_count': Sqflite.firstIntValue(semestresResult) ?? 0,
      'note_count': Sqflite.firstIntValue(notesResult) ?? 0,
      'avg_moyenne': notesResult.isNotEmpty
          ? notesResult.first['avg_moyenne'] ?? 0.0
          : 0.0,
      'passed_count':
          notesResult.isNotEmpty ? notesResult.first['passed_count'] ?? 0 : 0,
    };
  }

// Méthode pour mettre à jour les informations de l'étudiant
  Future<int> updateStudentProfile(int id, Map<String, dynamic> data) async {
    final db = await database;

    // Préparer les données avec timestamp
    final updateData = {
      ...data,
      'updated_at': DateTime.now().toIso8601String(),
      'sync_status': 'pending',
    };

    return await db.update('STUDENT', updateData,
        where: 'id_student = ?', whereArgs: [id]);
  }
}
