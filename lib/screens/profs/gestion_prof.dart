import 'package:flutter/material.dart';
import 'package:note_school_ssbm/services/db_service.dart';
import 'add_edit_prof.dart';
import 'package:note_school_ssbm/services/import_service.dart';

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

  // Charger les professeurs depuis la DB
  Future<void> _loadProfesseurs() async {
    setState(() => _isLoading = true);
    try {
      final db = await dbService.database;
      final result = await db.query('PROF', orderBy: 'nom');
      setState(() {
        _professeurs = result;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement: $e');
      setState(() => _isLoading = false);
    }
  }

  // Supprimer un professeur
  void _deleteProfesseur(int id) async {
    final confirmed = await showDialog<bool>(
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
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final db = await dbService.database;
      await db.delete('PROF', where: 'id_prof = ?', whereArgs: [id]);
      _loadProfesseurs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Professeur supprimé")),
        );
      }
    }
  }

  // Filtrer la liste selon la recherche
  List<Map<String, dynamic>> get _filteredProfesseurs {
    if (_searchQuery.isEmpty) return _professeurs;
    return _professeurs.where((prof) {
      final nom = prof['nom']?.toString().toLowerCase() ?? '';
      final prenom = prof['prenom']?.toString().toLowerCase() ?? '';
      final email = prof['email']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return nom.contains(query) ||
          prenom.contains(query) ||
          email.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestion des Professeurs"),
        actions: [
          // --- BOUTON IMPORTATION JSON ---
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: "Importer des professeurs (JSON)",
            onPressed: () async {
              // Affiche un indicateur de chargement pendant l'import
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
              );

              String message = await ImportService.pickAndImport('PROF');

              if (mounted) {
                Navigator.pop(context); // Fermer le loader
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor:
                        message.contains('Erreur') ? Colors.red : Colors.green,
                  ),
                );
                _loadProfesseurs(); // Actualiser la liste
              }
            },
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
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Liste des professeurs
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProfesseurs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline,
                                size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            const Text(
                              'Aucun professeur trouvé',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey),
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
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade100,
                                child: Text(prof['nom'][0].toUpperCase(),
                                    style: const TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold)),
                              ),
                              title: Text(
                                '${prof['prenom']} ${prof['nom']}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(prof['email']?.toString() ?? ''),
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
                                              ProfesseurFormPage(
                                            professeur: prof,
                                            onSaved: _loadProfesseurs,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _deleteProfesseur(
                                        prof['id_prof'] as int),
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
}
