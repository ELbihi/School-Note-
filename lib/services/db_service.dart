import 'dart:math';
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
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('CREATE TABLE FILIERE (id_filiere INTEGER PRIMARY KEY AUTOINCREMENT, nom_filiere TEXT, description TEXT)');
    await db.execute('CREATE TABLE PROF (id_prof INTEGER PRIMARY KEY AUTOINCREMENT, nom TEXT, prenom TEXT, email TEXT, password TEXT)');
    await db.execute('CREATE TABLE SEMESTRE (id_semestre INTEGER PRIMARY KEY AUTOINCREMENT, nom_semestre TEXT, annee TEXT)');
    
    await db.execute('''CREATE TABLE STUDENT (
      id_student INTEGER PRIMARY KEY AUTOINCREMENT, massar TEXT UNIQUE, nom TEXT, prenom TEXT, 
      email TEXT, password TEXT, groupe TEXT, niveau INTEGER, id_filiere INTEGER,
      FOREIGN KEY (id_filiere) REFERENCES FILIERE (id_filiere))''');

    await db.execute('''CREATE TABLE MODULE (
      id_module INTEGER PRIMARY KEY AUTOINCREMENT, nom_module TEXT, coefficient REAL,
      id_filiere INTEGER, id_semestre INTEGER, id_prof INTEGER,
      FOREIGN KEY (id_filiere) REFERENCES FILIERE (id_filiere),
      FOREIGN KEY (id_semestre) REFERENCES SEMESTRE (id_semestre),
      FOREIGN KEY (id_prof) REFERENCES PROF (id_prof))''');

    await db.execute('''CREATE TABLE NOTE (
      id_note INTEGER PRIMARY KEY AUTOINCREMENT, controle REAL, tp REAL, examen REAL, 
      projet REAL, moyenne REAL, resultat TEXT, id_student INTEGER, id_module INTEGER,
      FOREIGN KEY (id_student) REFERENCES STUDENT (id_student),
      FOREIGN KEY (id_module) REFERENCES MODULE (id_module))''');

    await _seedData(db);
  }

  Future<void> _seedData(Database db) async {
    // 1. Filières
    final filieres = ['Tronc Commun', 'AI', 'GINF', 'IRSI', 'ROC'];
    for (var f in filieres) await db.insert('FILIERE', {'nom_filiere': f, 'description': 'Cycle $f'});

    int sCount = 0;
    // 2. Cycle Préparatoire (Année 1 & 2) - 200/an
    List<String> pGroups = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
    for (int y = 1; y <= 2; y++) {
      for (int i = 0; i < 200; i++) {
        sCount++;
        await db.insert('STUDENT', _buildStudentMap(sCount, y, 1, pGroups[i % 6]));
      }
    }

    // 3. Cycle Ingénieur (Année 3, 4, 5) - 4 Filières
    List<String> iGroups = ['A', 'B'];
    for (int y = 3; y <= 5; y++) {
      for (int f = 2; f <= 5; f++) {
        int limit = 40 + Random().nextInt(21);
        for (int i = 0; i < limit; i++) {
          sCount++;
          await db.insert('STUDENT', _buildStudentMap(sCount, y, f, iGroups[i % 2]));
        }
      }
    }
  }

  Map<String, dynamic> _buildStudentMap(int id, int nv, int fil, String grp) {
    return {
      'massar': 'K${13000 + id}',
      'nom': 'ALAMI${id}', // Pour l'ordre alphabétique simulé
      'prenom': 'Ahmed${id}',
      'email': 's$id@ecole.ma',
      'password': '123',
      'groupe': grp,
      'niveau': nv,
      'id_filiere': fil
    };
  }

  // --- CRUD POUR LES NOTES ---
  Future<int> insertNote(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('NOTE', row);
  }
}