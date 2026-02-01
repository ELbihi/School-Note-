import 'package:flutter/material.dart';
import '../services/db_service.dart';
import 'pdf_service.dart';


class StudentResultPage extends StatefulWidget {
  final Map<String, dynamic> student;

  const StudentResultPage({Key? key, required this.student}) : super(key: key);

  @override
  State<StudentResultPage> createState() => _StudentResultPageState();
}

class _StudentResultPageState extends State<StudentResultPage> {
  late Future<List<Map<String, dynamic>>> _gradesFuture;

  @override
  void initState() {
    super.initState();
    _gradesFuture = DBService.instance
        .getStudentFullGrades(widget.student['id_student']);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.student;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulletin de notes'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text('Exporter'),
        onPressed:  () async {
  final grades = await DBService.instance
      .getStudentFullGrades(widget.student['id_student']);

  await PdfService.generateStudentBulletin(
    student: widget.student,
    grades: grades,
  );
        },
      ),
      body: Column(
        children: [
          _studentHeader(s),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _gradesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('Aucune note trouvée'));
                }

                final grades = snapshot.data!;

                return ListView.builder(
                  itemCount: grades.length,
                  itemBuilder: (context, index) {
                    final g = grades[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(g['nom_module']),
                        subtitle: Text(
                          'Semestre: ${g['nom_semestre']}',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              (g['moyenne'] ?? 0)
                                  .toStringAsFixed(2),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: (g['moyenne'] ?? 0) >= 10
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            Text(
                              g['resultat'] ?? '',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        onTap: () {
                          _showDetails(context, g);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _studentHeader(Map<String, dynamic> s) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${s['nom']} ${s['prenom']}',
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('Massar: ${s['massar']}'),
          Text('Niveau: ${s['niveau']}'),
          Text('Filière: ${s['nom_filiere'] ?? '—'}'),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context, Map<String, dynamic> g) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(g['nom_module']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _line('Contrôle', g['controle']),
            _line('TP', g['tp']),
            _line('Projet', g['projet']),
            _line('Examen', g['examen']),
            const Divider(),
            _line('Moyenne', g['moyenne']),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _line(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value?.toString() ?? '—'),
        ],
      ),
    );
  }
}
