import 'package:flutter/material.dart';
import 'package:note_school_ssbm/services/db_service.dart';
import 'package:note_school_ssbm/services/import_service.dart'; // Importation du service JSON
import 'add_edit_etudiant.dart';

class ManageStudentsPage extends StatefulWidget {
  const ManageStudentsPage({super.key});

  @override
  State<ManageStudentsPage> createState() => _ManageStudentsPageState();
}

class _ManageStudentsPageState extends State<ManageStudentsPage> {
  late DBService dbService;
  List<Map<String, dynamic>> _etudiants = [];
  List<Map<String, dynamic>> _filieres = [];
  bool _isLoading = true;

  // Variables de filtrage
  String _searchQuery = '';
  int? _selectedFiliere;
  int? _selectedNiveau;

  @override
  void initState() {
    super.initState();
    dbService = DBService.instance;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final etudiants = await dbService.getStudentsWithFiliere();
      final filieres = await dbService.getAllFilieres();

      setState(() {
        _etudiants = etudiants;
        _filieres = filieres;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement: $e');
      setState(() => _isLoading = false);
    }
  }

  // Getter pour le filtrage
  List<Map<String, dynamic>> get _filteredEtudiants {
    return _etudiants.where((etud) {
      final nomComplet = '${etud['nom']} ${etud['prenom']}'.toLowerCase();
      final massar = (etud['massar'] ?? '').toString().toLowerCase();
      final searchLower = _searchQuery.toLowerCase();

      final matchesSearch =
          nomComplet.contains(searchLower) || massar.contains(searchLower);
      final matchesFiliere =
          _selectedFiliere == null || etud['id_filiere'] == _selectedFiliere;
      final matchesNiveau =
          _selectedNiveau == null || etud['niveau'] == _selectedNiveau;

      return matchesSearch && matchesFiliere && matchesNiveau;
    }).toList();
  }

  void _deleteEtudiant(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Voulez-vous vraiment supprimer cet étudiant ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await dbService.deleteStudent(id);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Étudiants'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          // --- BOUTON IMPORTATION JSON ---
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Importer JSON',
            onPressed: () async {
              // Optionnel : Afficher un dialogue de chargement
              String message = await ImportService.pickAndImport('STUDENT');

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor:
                        message.contains('Erreur') ? Colors.red : Colors.green,
                  ),
                );
                _loadData(); // Très important pour rafraîchir l'affichage
              }
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildStudentList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => EtudiantFormPage(onSaved: _loadData)),
        ),
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher par nom ou Massar...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      value: _selectedFiliere,
                      decoration: const InputDecoration(
                          labelText: 'Filière', border: OutlineInputBorder()),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('Toutes')),
                        ..._filieres.map((f) => DropdownMenuItem(
                              value: f['id_filiere'] as int,
                              child: Text(f['nom_filiere'] ?? ''),
                            )),
                      ],
                      onChanged: (val) =>
                          setState(() => _selectedFiliere = val),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      value: _selectedNiveau,
                      decoration: const InputDecoration(
                          labelText: 'Niveau', border: OutlineInputBorder()),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('Tous')),
                        ...List.generate(
                            5,
                            (i) => DropdownMenuItem(
                                value: i + 1, child: Text('Année ${i + 1}'))),
                      ],
                      onChanged: (val) => setState(() => _selectedNiveau = val),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentList() {
    final filtered = _filteredEtudiants;
    if (filtered.isEmpty) {
      return const Center(child: Text('Aucun étudiant trouvé.'));
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final etud = filtered[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: Text(etud['nom'][0],
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            title: Text('${etud['nom']} ${etud['prenom']}'),
            subtitle: Text(
                '${etud['nom_filiere'] ?? 'N/A'} - Année ${etud['niveau']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EtudiantFormPage(etudiant: etud, onSaved: _loadData),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteEtudiant(etud['id_student']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
