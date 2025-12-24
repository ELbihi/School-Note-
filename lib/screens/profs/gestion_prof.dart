import 'package:flutter/material.dart';
import 'package:note_school_ssbm/services/db_service.dart';
import 'add_edit_prof.dart'; // Page d'ajout/modification

class ManageProfessorsPage extends StatefulWidget {
  const ManageProfessorsPage({super.key});

  @override
  State<ManageProfessorsPage> createState() => _ManageProfessorsPageState();
}

class _ManageProfessorsPageState extends State<ManageProfessorsPage> {
  late DBService dbService;
  List<Map<String, dynamic>> _professeurs = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    dbService = DBService.instance;
    _loadProfesseurs();
  }

  Future<void> _loadProfesseurs() async {
    try {
      final db = await dbService.database;
      final result = await db.query('PROF', orderBy: 'nom');
      setState(() {
        _professeurs = result;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur: $e');
      setState(() => _isLoading = false);
    }
  }

  void _deleteProfesseur(int id) async {
    final confirmed = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer'),
        content: const Text('Supprimer ce professeur ?'),
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
      await db.delete('PROF', where: 'id_prof = ?', whereArgs: [id]);
      _loadProfesseurs();
    }
  }

  List<Map<String, dynamic>> get _filteredProfesseurs {
    if (_searchQuery.isEmpty) return _professeurs;
    return _professeurs.where((prof) {
      final nom = prof['nom']?.toString().toLowerCase() ?? '';
      final prenom = prof['prenom']?.toString().toLowerCase() ?? '';
      final email = prof['email']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return nom.contains(query) || prenom.contains(query) || email.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Professeurs'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProfesseurs,
          ),
        ],
      ),
      body: Column(
        children: [
          // Section recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un professeur...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          
          // Section statistiques
          _buildStatsSection(),
          
          // Liste des professeurs
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProfesseurs.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Aucun professeur trouvé',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: _filteredProfesseurs.length,
                        itemBuilder: (ctx, index) {
                          final prof = _filteredProfesseurs[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade100,
                                child: const Icon(Icons.person, color: Colors.blue),
                              ),
                              title: Text(
                                '${prof['prenom']} ${prof['nom']}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(prof['email']?.toString() ?? ''),
                                  Text(
                                    'ID: ${prof['id_prof']}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProfesseurFormPage(
                                            professeur: prof,
                                            onSaved: _loadProfesseurs,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteProfesseur(prof['id_prof'] as int),
                                  ),
                                ],
                              ),
                              onTap: () {
                                // Option: Voir les détails
                              },
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
              builder: (context) => ProfesseurFormPage(
                onSaved: _loadProfesseurs,
              ),
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
            icon: Icons.people,
            value: _professeurs.length.toString(),
            label: 'Total',
            color: Colors.blue,
          ),
          _buildStatItem(
            icon: Icons.check_circle,
            value: '${(_professeurs.length * 0.8).toInt()}',
            label: 'Actifs',
            color: Colors.green,
          ),
          _buildStatItem(
            icon: Icons.school,
            value: '${(_professeurs.length * 0.6).toInt()}',
            label: 'Modules',
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
}