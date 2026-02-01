import 'package:flutter/material.dart';
import 'package:note_school_ssbm/services/db_service.dart';
import 'package:note_school_ssbm/services/import_service.dart';
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

  // --- VARIABLES DE FILTRAGE CORRIGÉES ---
  String _searchQuery = '';
  int? _selectedFiliere;
  String?
      _selectedNiveau; // Changé de int? à String? pour supporter CP1, CI1, etc.

  // Liste exhaustive de vos niveaux
  final List<String> _niveauxScolaires = ['CP1', 'CP2', 'CI1', 'CI2', 'CI3'];

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
      final filieres =
          await dbService.getAll('FILIERE', orderBy: 'nom_filiere');

      setState(() {
        _etudiants = etudiants;
        _filieres = filieres;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LOGIQUE DE FILTRAGE MISE À JOUR ---
  List<Map<String, dynamic>> get _filteredEtudiants {
    return _etudiants.where((etud) {
      // 1. Recherche Textuelle
      final nomComplet = '${etud['nom']} ${etud['prenom']}'.toLowerCase();
      final massar = (etud['massar'] ?? '').toString().toLowerCase();
      final searchLower = _searchQuery.toLowerCase();
      final matchesSearch =
          nomComplet.contains(searchLower) || massar.contains(searchLower);

      // 2. Filtre Filière
      final matchesFiliere =
          _selectedFiliere == null || etud['id_filiere'] == _selectedFiliere;

      // 3. Filtre Niveau (Comparaison de chaînes)
      final matchesNiveau = _selectedNiveau == null ||
          etud['niveau'].toString() == _selectedNiveau;

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
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Importer JSON',
            onPressed: () async {
              String message = await ImportService.pickAndImport('STUDENT');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor:
                        message.contains('Erreur') ? Colors.red : Colors.green,
                  ),
                );
                _loadData();
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  // --- DROPDOWN FILIÈRE ---
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
                              child: Text(f['nom_filiere'] ?? '',
                                  overflow: TextOverflow.ellipsis),
                            )),
                      ],
                      onChanged: (val) =>
                          setState(() => _selectedFiliere = val),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // --- DROPDOWN NIVEAU (CP1, CI1...) ---
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: _selectedNiveau,
                      decoration: const InputDecoration(
                          labelText: 'Niveau', border: OutlineInputBorder()),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('Tous')),
                        ..._niveauxScolaires.map((niv) => DropdownMenuItem(
                              value: niv,
                              child: Text(niv),
                            )),
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
              backgroundColor: Colors.blueAccent,
              child: Text(
                etud['nom'] != null && etud['nom'].toString().isNotEmpty
                    ? etud['nom'][0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text('${etud['nom']} ${etud['prenom']}'),
            subtitle: Text(
                '${etud['nom_filiere'] ?? 'N/A'} - Niveau: ${etud['niveau']}'),
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
