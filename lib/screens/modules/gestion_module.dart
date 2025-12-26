// lib/screens/module_list_page.dart
import 'package:flutter/material.dart';
import 'package:note_school_ssbm/services/db_service.dart';
import 'package:note_school_ssbm/screens/modules/add_edit_module_page.dart';

class ModuleListPage extends StatefulWidget {
  const ModuleListPage({super.key});

  @override
  _ModuleListPageState createState() => _ModuleListPageState();
}

class _ModuleListPageState extends State<ModuleListPage> {
  late DBService dbService;
  List<Map<String, dynamic>> _modules = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    dbService = DBService.instance;
    _loadModules();
  }

  Future<void> _loadModules() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final db = await dbService.database;

      final result = await db.rawQuery('''
        SELECT 
          m.id_module,
          m.nom_module,
          m.coefficient,
          f.nom_filiere,
          s.nom_semestre,
          p.nom || ' ' || p.prenom as prof_nom,
          m.id_filiere,
          m.id_semestre,
          m.id_prof
        FROM MODULE m
        LEFT JOIN FILIERE f ON m.id_filiere = f.id_filiere
        LEFT JOIN SEMESTRE s ON m.id_semestre = s.id_semestre
        LEFT JOIN PROF p ON m.id_prof = p.id_prof
        ORDER BY m.nom_module
      ''');

      setState(() {
        _modules = List<Map<String, dynamic>>.from(result);
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des modules: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteModule(int id, String moduleName) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
            'Êtes-vous sûr de vouloir supprimer le module "$moduleName" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final db = await dbService.database;
        await db.delete(
          'MODULE',
          where: 'id_module = ?',
          whereArgs: [id],
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Module "$moduleName" supprimé avec succès'),
            backgroundColor: Colors.green,
          ),
        );

        await _loadModules();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToAddModule() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ModuleFormPage(),
      ),
    ).then((value) {
      if (value == true) {
        _loadModules();
      }
    });
  }

  void _navigateToEditModule(Map<String, dynamic> module) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModuleFormPage(module: module),
      ),
    ).then((value) {
      if (value == true) {
        _loadModules();
      }
    });
  }

  List<Map<String, dynamic>> get _filteredModules {
    if (_searchQuery.isEmpty) return _modules;

    return _modules.where((module) {
      final nomModule = module['nom_module']?.toString().toLowerCase() ?? '';
      final nomFiliere = module['nom_filiere']?.toString().toLowerCase() ?? '';
      final nomProf = module['prof_nom']?.toString().toLowerCase() ?? '';

      return nomModule.contains(_searchQuery.toLowerCase()) ||
          nomFiliere.contains(_searchQuery.toLowerCase()) ||
          nomProf.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Modules'),
        centerTitle: true,
        elevation: 4,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Barre de recherche et statistiques
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Barre de recherche
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher un module...',
                    prefixIcon: const Icon(Icons.search, color: Colors.blue),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),

              

               
              ],
            ),
          ),

          // Tableau des modules
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredModules.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.library_books_outlined,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Aucun module disponible'
                                  : 'Aucun module trouvé',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (_searchQuery.isEmpty)
                              ElevatedButton(
                                onPressed: _navigateToAddModule,
                                child: const Text('Ajouter le premier module'),
                              ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            columnSpacing: 20,
                            horizontalMargin: 16,
                            columns: const [
                              DataColumn(
                                label: Text('ID',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                                numeric: true,
                              ),
                              DataColumn(
                                label: Text('Module',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                              ),
                              DataColumn(
                                label: Text('Coefficient',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                                numeric: true,
                              ),
                              DataColumn(
                                label: Text('Filière',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                              ),
                              DataColumn(
                                label: Text('Semestre',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                              ),
                              DataColumn(
                                label: Text('Professeur',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                              ),
                              DataColumn(
                                label: Text('Actions',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                              ),
                            ],
                            rows: _filteredModules.map((module) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '#${module['id_module']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      module['nom_module']?.toString() ?? 'N/A',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _getCoefficientColor(
                                            module['coefficient']),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        module['coefficient']?.toString() ??
                                            '0.0',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                            color: Colors.green.shade100,
                                            width: 1),
                                      ),
                                      child: Text(
                                        module['nom_filiere']?.toString() ??
                                            'N/A',
                                        style: TextStyle(
                                          color: Colors.green.shade800,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                            color: Colors.orange.shade100,
                                            width: 1),
                                      ),
                                      child: Text(
                                        module['nom_semestre']?.toString() ??
                                            'N/A',
                                        style: TextStyle(
                                          color: Colors.orange.shade800,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      module['prof_nom']?.toString() ?? 'N/A',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon:
                                              const Icon(Icons.edit, size: 20),
                                          color: Colors.blue,
                                          onPressed: () =>
                                              _navigateToEditModule(module),
                                          tooltip: 'Modifier',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              size: 20),
                                          color: Colors.red,
                                          onPressed: () => _deleteModule(
                                            module['id_module'],
                                            module['nom_module']?.toString() ??
                                                '',
                                          ),
                                          tooltip: 'Supprimer',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddModule,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau Module'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 20, color: Colors.blue),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  int _getUniqueCount(List<Map<String, dynamic>> list, String key) {
    final uniqueItems = <String>{};
    for (var item in list) {
      if (item[key] != null) {
        uniqueItems.add(item[key].toString());
      }
    }
    return uniqueItems.length;
  }

  Color _getCoefficientColor(dynamic coefficient) {
    try {
      double coeff = double.tryParse(coefficient.toString()) ?? 0.0;
      if (coeff >= 4.0) return Colors.red;
      if (coeff >= 3.0) return Colors.orange;
      if (coeff >= 2.0) return Colors.blue;
      return Colors.green;
    } catch (e) {
      return Colors.grey;
    }
  }
}
