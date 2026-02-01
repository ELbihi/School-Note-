import 'dart:io'; // Nécessaire pour manipuler le fichier
import 'package:flutter/material.dart';
import 'package:csv/csv.dart'; // Pour transformer les données en CSV
import 'package:path_provider/path_provider.dart'; // Pour accéder au stockage temporaire
import 'package:share_plus/share_plus.dart'; // Pour ouvrir le menu de partage (WhatsApp, Email, etc.)
import 'noteform.dart';
import '/services/db_service.dart';
import 'dart:convert'; // INDISPENSABLE pour utf8.encode

class AddGradePage extends StatefulWidget {
  final Map<String, dynamic> moduleData;

  const AddGradePage({super.key, required this.moduleData});

  @override
  State<AddGradePage> createState() => _AddGradePageState();
}

class _AddGradePageState extends State<AddGradePage> {
  final Color royalBlue = const Color(0xFF0056D2);
  List<Map<String, dynamic>> studentsGrades = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    String annee = (widget.moduleData['annee'] ?? 1).toString();
    final data = await DBService.instance.getGradesForModule(
        widget.moduleData['id_module'], widget.moduleData['id_filiere'], annee);

    if (mounted) {
      setState(() {
        studentsGrades = data;
        isLoading = false;
      });
    }
  }

  // --- LOGIQUE DE CALCUL DE LA MOYENNE ---
  double _calculateMoyenne(Map<String, dynamic> student) {
    double ctl = double.tryParse(student['controle']?.toString() ?? '0') ?? 0.0;
    double tp = double.tryParse(student['tp']?.toString() ?? '0') ?? 0.0;
    double projet =
        double.tryParse(student['projet']?.toString() ?? '0') ?? 0.0;
    double exam = double.tryParse(student['examen']?.toString() ?? '0') ?? 0.0;

    return (ctl * 0.15) + (tp * 0.15) + (projet * 0.20) + (exam * 0.50);
  }

  // --- LOGIQUE DE VALIDATION ---
  Map<String, dynamic> _getValidation(double moyenne) {
    if (moyenne >= 12) {
      return {'text': 'Validé', 'color': Colors.green};
    } else if (moyenne >= 6) {
      return {'text': 'Ratt', 'color': Colors.orange};
    } else {
      return {'text': 'Non Valide', 'color': Colors.red};
    }
  }

  Future<void> _exportToCSV() async {
    if (studentsGrades.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aucune donnée à exporter")),
      );
      return;
    }

    List<List<dynamic>> rows = [];

    // 1. En-têtes
    rows.add([
      "Nom",
      "Prénom",
      "Contrôle",
      "TP",
      "Projet",
      "Examen",
      "Moyenne",
      "Résultat"
    ]);

    // 2. Données
    for (var student in studentsGrades) {
      double moyenne = _calculateMoyenne(student);
      String result = _getValidation(moyenne)['text'];

      rows.add([
        student['nom'],
        student['prenom'],
        student['controle'] ?? "-",
        student['tp'] ?? "-",
        student['projet'] ?? "-",
        student['examen'] ?? "-",
        moyenne.toStringAsFixed(2).replaceAll(
            '.', ','), // Remplace le point par une virgule pour Excel
        result
      ]);
    }

    // 3. ICI LA MODIFICATION : On utilise le point-virgule ';' comme séparateur
    // C'est ce qui force Excel et les lecteurs mobiles à créer des colonnes propres.
    String csvData =
        const ListToCsvConverter(fieldDelimiter: ';').convert(rows);

    try {
      final directory = await getTemporaryDirectory();
      final String path =
          "${directory.path}/Notes_${widget.moduleData['nom_module']}.csv";
      final File file = File(path);

      // On ajoute un marqueur UTF-8 (BOM) pour que les accents s'affichent bien
      await file.writeAsBytes([0xEF, 0xBB, 0xBF, ...utf8.encode(csvData)]);

      await Share.shareXFiles(
        [XFile(path)],
        text: 'Export des notes : ${widget.moduleData['nom_module']}',
      );
    } catch (e) {
      debugPrint("Erreur : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    String titre = widget.moduleData['nom_module'] ?? "Module";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Notes : $titre"),
        backgroundColor: royalBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
            color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        actions: [
          // NOUVEAU BOUTON D'EXPORT DANS L'APPBAR
          IconButton(
            icon: const Icon(Icons.file_download, color: Colors.white),
            onPressed: _exportToCSV,
            tooltip: "Exporter en CSV",
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGrades,
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : studentsGrades.isEmpty
              ? const Center(child: Text("Aucun étudiant trouvé."))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: DataTable(
                        border: TableBorder.all(
                            color: Colors.grey.shade300, width: 1),
                        headingRowColor:
                            WidgetStateProperty.all(Colors.grey.shade100),
                        columnSpacing: 12,
                        columns: const [
                          DataColumn(
                              label: Text("Étudiant",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text("Ctl",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text("TP",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text("Proj",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text("Exam",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text("Moy",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue))),
                          DataColumn(
                              label: Text("Résultat",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text("Edit",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: studentsGrades.map((student) {
                          double moyenne = _calculateMoyenne(student);
                          Map<String, dynamic> status = _getValidation(moyenne);

                          return DataRow(
                            cells: [
                              DataCell(SizedBox(
                                width: 120,
                                child: Text(
                                    "${student['nom']} ${student['prenom']}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                    overflow: TextOverflow.ellipsis),
                              )),
                              _buildGradeCell(student['controle']),
                              _buildGradeCell(student['tp']),
                              _buildGradeCell(student['projet']),
                              _buildGradeCell(student['examen']),

                              // Cellule Moyenne
                              DataCell(Center(
                                  child: Text(moyenne.toStringAsFixed(2),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)))),

                              // CELLULE VALIDATION (Résultat)
                              DataCell(
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: (status['color'] as Color)
                                            .withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                            color: status['color'] as Color,
                                            width: 0.5)),
                                    child: Text(
                                      status['text'],
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: status['color'] as Color,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              DataCell(
                                Center(
                                  child: IconButton(
                                    icon: const Icon(Icons.edit_note,
                                        color: Colors.blue),
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => NoteFormPage(
                                            studentData: student,
                                            moduleId:
                                                widget.moduleData['id_module'],
                                          ),
                                        ),
                                      );
                                      _loadGrades();
                                    },
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
    );
  }

  DataCell _buildGradeCell(dynamic grade) {
    return DataCell(
      Center(
        child: Text(
          grade != null ? grade.toString() : "-",
          style: TextStyle(
              color: grade == null ? Colors.grey : Colors.black87,
              fontSize: 13),
        ),
      ),
    );
  }
}
