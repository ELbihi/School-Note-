import 'package:flutter/material.dart';
import 'package:note_school_ssbm/services/db_service.dart';
import 'add_edit_etudiant.dart'; // Page d'ajout/modification

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
    try {
      final db = await dbService.database;
      final etudiants = await db.rawQuery('''
        SELECT s.*, f.nom_filiere 
        FROM STUDENT s 
        LEFT JOIN FILIERE f ON s.id_filiere = f.id_filiere 
        ORDER BY s.nom
      ''');
      final filieres = await db.query('FILIERE');

      setState(() {
        _etudiants = etudiants;
        _filieres = filieres;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredEtudiants {
    var filtered = _etudiants;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((etud) {
        final nom = etud['nom']?.toString().toLowerCase() ?? '';
        final prenom = etud['prenom']?.toString().toLowerCase() ?? '';
        final massar = etud['massar']?.toString().toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        return nom.contains(query) ||
            prenom.contains(query) ||
            massar.contains(query);
      }).toList();
    }

    if (_selectedFiliere != null) {
      filtered = filtered
          .where((etud) => etud['id_filiere'] == _selectedFiliere)
          .toList();
    }

    if (_selectedNiveau != null) {
      filtered =
          filtered.where((etud) => etud['niveau'] == _selectedNiveau).toList();
    }

    return filtered;
  }

  void _deleteEtudiant(int id) async {
    final confirmed = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer'),
        content: const Text('Supprimer cet étudiant ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final db = await dbService.database;
      await db.delete('STUDENT', where: 'id_student = ?', whereArgs: [id]);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Étudiants'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Section filtres
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Recherche
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher étudiant...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                const SizedBox(height: 12),

                // Filtres
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        value: _selectedFiliere,
                        decoration: InputDecoration(
                          labelText: 'Filière',
                          border: const OutlineInputBorder(),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('Toutes les filières')),
                          ..._filieres.map((filiere) {
                            return DropdownMenuItem<int?>(
                              value: filiere['id_filiere'] as int,
                              child: Text(
                                  filiere['nom_filiere']?.toString() ?? ''),
                            );
                          }),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedFiliere = value),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        value: _selectedNiveau,
                        decoration: InputDecoration(
                          labelText: 'Niveau',
                          border: const OutlineInputBorder(),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('Tous les niveaux')),
                          for (int i = 1; i <= 5; i++)
                            DropdownMenuItem(value: i, child: Text('Année $i')),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedNiveau = value),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Statistiques
          _buildStatsSection(),

          // Liste des étudiants
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredEtudiants.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.school_outlined,
                                size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Aucun étudiant trouvé',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: _filteredEtudiants.length,
                        itemBuilder: (ctx, index) {
                          final etud = _filteredEtudiants[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green.shade100,
                                child: const Icon(Icons.school,
                                    color: Colors.green),
                              ),
                              title: Text(
                                '${etud['prenom']} ${etud['nom']}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Massar: ${etud['massar']}'),
                                  Text('Email: ${etud['email']}'),
                                  Row(
                                    children: [
                                      Chip(
                                        label: Text(
                                          'Année ${etud['niveau']}',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white),
                                        ),
                                        backgroundColor: Colors.blue,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                      ),
                                      const SizedBox(width: 8),
                                      Chip(
                                        label: Text(
                                          etud['nom_filiere']?.toString() ?? '',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white),
                                        ),
                                        backgroundColor: Colors.green,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              EtudiantFormPage(
                                            etudiant: etud,
                                            onSaved: _loadData,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _deleteEtudiant(
                                        etud['id_student'] as int),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EtudiantFormPage(onSaved: _loadData),
            ),
          );
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.blue[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.school,
            value: _etudiants.length.toString(),
            label: 'Total Étudiants',
            color: Colors.blue,
          ),
          _buildStatItem(
            icon: Icons.group,
            value: '${_getUniqueGroups()}',
            label: 'Groupes',
            color: Colors.green,
          ),
          _buildStatItem(
            icon: Icons.bar_chart,
            value: '${_getAverageByFiliere()}',
            label: 'Moy/Filière',
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  int _getUniqueGroups() {
    final groups = _etudiants
        .map((e) => e['groupe']?.toString())
        .where((g) => g != null)
        .toSet();
    return groups.length;
  }

  String _getAverageByFiliere() {
    if (_filieres.isEmpty) return '0';
    return (_etudiants.length / _filieres.length).toStringAsFixed(1);
  }
}
