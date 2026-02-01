import 'package:flutter/material.dart';
import 'package:note_school_ssbm/services/db_service.dart';
import '../module/ajouter_etudiant.dart';

class StudentListPage extends StatefulWidget {
  final Map<String, dynamic> moduleData;
  final Map<String, dynamic>? profData;

  const StudentListPage({super.key, required this.moduleData, this.profData});

  @override
  State<StudentListPage> createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  final Color royalBlue = const Color(0xFF0056D2);
  List<Map<String, dynamic>> allStudents = [];
  bool isLoading = true;

  // --- NOUVELLES VARIABLES POUR LE FILTRAGE ---
  String _searchQuery = "";
  String? _selectedGroupe; // null signifie "Tous les groupes"
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    int idFiliere = widget.moduleData['id_filiere'];
    // Vérifiez si votre moduleData utilise 'annee' ou 'niveau'
    String annee =
        (widget.moduleData['annee'] ?? widget.moduleData['niveau']).toString();

    final students =
        await DBService.instance.getStudentsForModuleSmart(idFiliere, annee);

    if (mounted) {
      setState(() {
        allStudents = students;
        isLoading = false;
      });
    }
  }

  // --- LOGIQUE DE FILTRAGE ---
  List<Map<String, dynamic>> get _filteredStudents {
    return allStudents.where((student) {
      final name = "${student['nom']} ${student['prenom']}".toLowerCase();
      final massar = (student['code_massar'] ?? student['massar'] ?? "")
          .toString()
          .toLowerCase();
      final groupe = (student['groupe'] ?? "").toString();

      final matchesSearch = name.contains(_searchQuery.toLowerCase()) ||
          massar.contains(_searchQuery.toLowerCase());

      final matchesGroupe =
          _selectedGroupe == null || groupe == _selectedGroupe;

      return matchesSearch && matchesGroupe;
    }).toList();
  }

  // Récupérer la liste unique des groupes présents
  List<String> _getUniqueGroupes() {
    final groupes = allStudents
        .map((e) => (e['groupe'] ?? "").toString())
        .where((g) => g.isNotEmpty)
        .toSet()
        .toList();
    groupes.sort();
    return groupes;
  }

  void _refreshList() {
    setState(() {
      isLoading = true;
      _selectedGroupe = null; // Reset filtre
    });
    _loadStudents();
  }

  @override
  Widget build(BuildContext context) {
    String moduleName = widget.moduleData['nom_module'] ?? "Module";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: royalBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        // --- TITRE DYNAMIQUE (BARRE DE RECHERCHE) ---
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Rechercher un étudiant...",
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              )
            : Text("Étudiants - $moduleName",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
        actions: [
          // Bouton Recherche
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = "";
                  _searchController.clear();
                }
              });
            },
          ),

          // --- FILTRE PAR GROUPE ---
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            tooltip: "Filtrer par groupe",
            onSelected: (String? groupe) {
              setState(() => _selectedGroupe = groupe);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text("Tous les groupes")),
              ..._getUniqueGroupes().map((g) => PopupMenuItem(
                    value: g,
                    child: Text("Groupe $g"),
                  )),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshList,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AjouterEtudiantPage(
                moduleData: widget.moduleData,
                profData: widget.profData,
              ),
            ),
          );
          if (result == true) _refreshList();
        },
        backgroundColor: royalBlue,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Petit indicateur si un filtre est actif
          if (_selectedGroupe != null)
            Container(
              color: royalBlue.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.group, size: 16, color: royalBlue),
                  const SizedBox(width: 8),
                  Text("Filtre actif : Groupe $_selectedGroupe",
                      style: TextStyle(
                          color: royalBlue, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _selectedGroupe = null),
                    child: Text("Effacer",
                        style: TextStyle(
                            color: Colors.red.shade700, fontSize: 12)),
                  )
                ],
              ),
            ),

          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF0056D2)))
                : _filteredStudents.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadStudents,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student = _filteredStudents[index];
                            return _buildStudentCard(student);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(_searchQuery.isEmpty
              ? "Aucun étudiant dans ce module"
              : "Aucun résultat pour '$_searchQuery'"),
          if (_selectedGroupe != null) Text("dans le groupe $_selectedGroupe"),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    String groupe = (student['groupe'] ?? "N/A").toString();
    String massar =
        (student['code_massar'] ?? student['massar'] ?? student['cin'] ?? "")
            .toString();

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: royalBlue.withOpacity(0.1),
          child: Text(
            groupe,
            style: TextStyle(
                color: royalBlue, fontWeight: FontWeight.bold, fontSize: 10),
          ),
        ),
        title: Text(
          "${student['nom']} ${student['prenom']}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(student['email'] ?? massar),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(5)),
          child: Text(
            massar,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
          ),
        ),
      ),
    );
  }
}
