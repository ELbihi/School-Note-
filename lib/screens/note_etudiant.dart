// import 'package:flutter/material.dart';
// import '../services/db_service.dart';
// import 'student_result_page.dart';

// class NotesReportPage extends StatefulWidget {
//   const NotesReportPage({Key? key}) : super(key: key);

//   @override
//   State<NotesReportPage> createState() => _NotesReportPageState();
// }

// class _NotesReportPageState extends State<NotesReportPage> {
//   late Future<List<Map<String, dynamic>>> _studentsFuture;

//   @override
//   void initState() {
//     super.initState();
//     _studentsFuture = DBService.instance.getStudentsWithFiliere();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Notes & Bulletins'),
//         centerTitle: true,
//       ),
//       body: FutureBuilder<List<Map<String, dynamic>>>(
//         future: _studentsFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             return const Center(child: Text('Aucun étudiant trouvé'));
//           }

//           final students = snapshot.data!;

//           return ListView.builder(
//             itemCount: students.length,
//             itemBuilder: (context, index) {
//               final s = students[index];

//               return Card(
//                 margin: const EdgeInsets.symmetric(
//                     horizontal: 12, vertical: 6),
//                 child: ListTile(
//                   leading: const Icon(Icons.school),
//                   title: Text('${s['nom']} ${s['prenom']}'),
//                   subtitle: Text(
//                     'Filière: ${s['nom_filiere'] ?? '—'} | Niveau: ${s['niveau']}',
//                   ),
//                   trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => StudentResultPage(student: s),
//                       ),
//                     );
//                   },
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }



import 'package:flutter/material.dart';
import '../services/db_service.dart';
import 'student_result_page.dart';

class NotesReportPage extends StatefulWidget {
  const NotesReportPage({Key? key}) : super(key: key);

  @override
  State<NotesReportPage> createState() => _NotesReportPageState();
}

class _NotesReportPageState extends State<NotesReportPage> {
  final DBService db = DBService.instance;

  List<Map<String, dynamic>> allStudents = [];
  List<Map<String, dynamic>> filteredStudents = [];

  List<Map<String, dynamic>> filieres = [];

  String? selectedFiliere;
  String? selectedNiveau;
  String searchText = '';

  final List<String> niveaux = ['CI1', 'CI2', 'CI3', 'CP1', 'CP2'];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final students = await db.getStudentsWithFiliere();
    final filieresData = await db.getAllFilieres();

    setState(() {
      allStudents = students;
      filteredStudents = students;
      filieres = filieresData;
      loading = false;
    });
  }

  void _applyFilters() {
    setState(() {
      filteredStudents = allStudents.where((s) {
        final matchesFiliere =
            selectedFiliere == null ||
            s['nom_filiere'] == selectedFiliere;

        final matchesNiveau =
            selectedNiveau == null || s['niveau'] == selectedNiveau;

        final searchLower = searchText.toLowerCase();
        final matchesSearch =
            searchText.isEmpty ||
            s['nom'].toLowerCase().contains(searchLower) ||
            s['prenom'].toLowerCase().contains(searchLower) ||
            (s['massar'] ?? '').toLowerCase().contains(searchLower) ||
            (s['email'] ?? '').toLowerCase().contains(searchLower);

        return matchesFiliere && matchesNiveau && matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes & Bulletins'),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _filters(),
                const Divider(height: 1),
                Expanded(child: _studentsList()),
              ],
            ),
    );
  }

  // ================= FILTERS UI =================
  Widget _filters() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Search
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Search (Nom, Prénom, Massar, Email)',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              searchText = value;
              _applyFilters();
            },
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              // Filière filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedFiliere,
                  decoration: const InputDecoration(
                    labelText: 'Filière',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('Toutes')),
                    ...filieres.map(
                      (f) => DropdownMenuItem(
                        value: f['nom_filiere'],
                        child: Text(f['nom_filiere']),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    selectedFiliere = value;
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 10),

              // Niveau filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedNiveau,
                  decoration: const InputDecoration(
                    labelText: 'Niveau',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('Tous')),
                    ...niveaux.map(
                      (n) => DropdownMenuItem(
                        value: n,
                        child: Text(n),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    selectedNiveau = value;
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= STUDENT LIST =================
  Widget _studentsList() {
    if (filteredStudents.isEmpty) {
      return const Center(child: Text('Aucun étudiant trouvé'));
    }

    return ListView.builder(
      itemCount: filteredStudents.length,
      itemBuilder: (context, index) {
        final s = filteredStudents[index];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: const Icon(Icons.school),
            title: Text('${s['nom']} ${s['prenom']}'),
            subtitle: Text(
              'Filière: ${s['nom_filiere'] ?? '—'} | Niveau: ${s['niveau']}',
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudentResultPage(student: s),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
