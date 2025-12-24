import 'package:flutter/material.dart';
import 'package:note_school_ssbm/services/db_service.dart';

class ModuleFormPage extends StatefulWidget {
  final Map<String, dynamic>? module;

  const ModuleFormPage({super.key, this.module});

  @override
  State<ModuleFormPage> createState() => _ModuleFormPageState();
}

class _ModuleFormPageState extends State<ModuleFormPage> {
  final _formKey = GlobalKey<FormState>();
  final dbService = DBService.instance;

  final TextEditingController _nomModuleController = TextEditingController();
  final TextEditingController _coefficientController = TextEditingController();

  List<Map<String, dynamic>> filieres = [];
  List<Map<String, dynamic>> profs = [];
  List<Map<String, dynamic>> semestresFiltres = [];

  int? selectedFiliereId;
  int? selectedSemestreId;
  int? selectedProfId;

  bool isEditMode = false;
  bool isLoading = false;
  bool isDataLoading = true;

  @override
  void initState() {
    super.initState();
    isEditMode = widget.module != null;

    if (isEditMode) {
      _nomModuleController.text =
          widget.module!['nom_module']?.toString() ?? '';
      _coefficientController.text =
          widget.module!['coefficient']?.toString() ?? '1.0';
      selectedFiliereId = widget.module!['id_filiere'];
      selectedSemestreId = widget.module!['id_semestre'];
      selectedProfId = widget.module!['id_prof'];
    }

    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final db = await dbService.database;

      // 1. Charger les filières
      filieres = await db.query('FILIERE');
      print('✅ Filières chargées: ${filieres.length}');

      // 2. Charger les professeurs
      profs = await db.query('PROF');
      print('✅ Profs chargés: ${profs.length}');

      // Sélections par défaut
      if (!isEditMode) {
        if (filieres.isNotEmpty)
          selectedFiliereId = filieres.first['id_filiere'];
        if (profs.isNotEmpty) selectedProfId = profs.first['id_prof'];
      }

      // Charger les semestres pour la filière sélectionnée
      await _loadSemestresPourFiliere();
    } catch (e) {
      print('❌ Erreur: $e');

      // Données de test
      filieres = [
        {'id_filiere': 1, 'nom_filiere': 'Tronc Commun'},
        {'id_filiere': 2, 'nom_filiere': 'AI'},
        {'id_filiere': 3, 'nom_filiere': 'ROC'},
        {'id_filiere': 4, 'nom_filiere': 'IRSI'},
        {'id_filiere': 5, 'nom_filiere': 'GINF'},
      ];

      profs = [
        {'id_prof': 1, 'nom': 'Boudchich', 'prenom': 'Mohamed'},
      ];

      if (!isEditMode) {
        if (filieres.isNotEmpty)
          selectedFiliereId = filieres.first['id_filiere'];
        if (profs.isNotEmpty) selectedProfId = profs.first['id_prof'];
      }

      // Simuler le chargement des semestres pour Tronc Commun
      semestresFiltres = [
        {'id_semestre': 1, 'nom_semestre': 'S1', 'annee': '1ère année'},
        {'id_semestre': 2, 'nom_semestre': 'S2', 'annee': '1ère année'},
        {'id_semestre': 3, 'nom_semestre': 'S3', 'annee': '2ème année'},
        {'id_semestre': 4, 'nom_semestre': 'S4', 'annee': '2ème année'},
      ];

      if (!isEditMode && semestresFiltres.isNotEmpty) {
        selectedSemestreId = semestresFiltres.first['id_semestre'];
      }
    }

    setState(() => isDataLoading = false);
  }

  Future<void> _loadSemestresPourFiliere() async {
    if (selectedFiliereId == null) {
      semestresFiltres = [];
      selectedSemestreId = null;
      setState(() {});
      return;
    }

    try {
      final db = await dbService.database;

      // Charger les semestres pour CETTE filière
      semestresFiltres = await db.query(
        'SEMESTRE',
        where: 'id_filiere = ?',
        whereArgs: [selectedFiliereId],
      );

      print(
          '✅ Semestres pour filière $selectedFiliereId: ${semestresFiltres.length}');

      // DEBUG: Afficher ce qui est chargé
      for (var s in semestresFiltres) {
        print('  - ${s['id_semestre']}: ${s['nom_semestre']} (${s['annee']})');
      }

      // Sélectionner un semestre
      if (semestresFiltres.isNotEmpty) {
        if (isEditMode && selectedSemestreId != null) {
          // Vérifier si le semestre en édition existe encore
          bool exists = semestresFiltres
              .any((s) => s['id_semestre'] == selectedSemestreId);
          if (!exists) {
            selectedSemestreId = semestresFiltres.first['id_semestre'];
          }
        } else {
          selectedSemestreId = semestresFiltres.first['id_semestre'];
        }
      } else {
        selectedSemestreId = null;
        print('⚠️ Aucun semestre trouvé pour filière $selectedFiliereId');
      }

      setState(() {});
    } catch (e) {
      print('❌ Erreur chargement semestres: $e');
      semestresFiltres = [];
      selectedSemestreId = null;
      setState(() {});
    }
  }

  void _onFiliereChanged(int? newFiliereId) {
    setState(() {
      selectedFiliereId = newFiliereId;
      selectedSemestreId = null;
      semestresFiltres = [];
    });

    if (newFiliereId != null) {
      _loadSemestresPourFiliere();
    }
  }

  Future<void> _saveModule() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedFiliereId == null ||
        selectedSemestreId == null ||
        selectedProfId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final db = await dbService.database;

      final data = {
        'nom_module': _nomModuleController.text,
        'coefficient': double.parse(_coefficientController.text),
        'id_filiere': selectedFiliereId,
        'id_semestre': selectedSemestreId,
        'id_prof': selectedProfId,
      };

      if (isEditMode) {
        await db.update('MODULE', data,
            where: 'id_module = ?', whereArgs: [widget.module!['id_module']]);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ Module modifié'), backgroundColor: Colors.green),
        );
      } else {
        await db.insert('MODULE', data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ Module ajouté'), backgroundColor: Colors.green),
        );
      }

      Navigator.pop(context, true);
    } catch (e) {
      print('❌ Erreur sauvegarde: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erreur: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Modifier Module' : 'Ajouter Module'),
        backgroundColor: isEditMode ? Colors.orange : Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: isDataLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // NOM DU MODULE
                    TextFormField(
                      controller: _nomModuleController,
                      decoration:
                          _inputDecoration('Nom du module *', Icons.book),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Obligatoire' : null,
                    ),
                    const SizedBox(height: 16),

                    // COEFFICIENT
                    TextFormField(
                      controller: _coefficientController,
                      keyboardType: TextInputType.number,
                      decoration:
                          _inputDecoration('Coefficient *', Icons.scale),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Obligatoire';
                        final val = double.tryParse(v);
                        return val == null || val <= 0 ? 'Nombre > 0' : null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // FILIÈRE
                    DropdownButtonFormField<int?>(
                      value: selectedFiliereId,
                      decoration: _inputDecoration('Filière *', Icons.school),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Sélectionner une filière'),
                        ),
                        ...filieres.map((f) => DropdownMenuItem<int?>(
                              value: f['id_filiere'] as int?,
                              child: Text(f['nom_filiere'].toString()),
                            )),
                      ],
                      onChanged: _onFiliereChanged,
                      validator: (v) =>
                          v == null ? 'Sélectionnez une filière' : null,
                    ),
                    const SizedBox(height: 16),

                    // SEMESTRE
                    DropdownButtonFormField<int?>(
                      value: selectedSemestreId,
                      decoration:
                          _inputDecoration('Semestre *', Icons.calendar_month),
                      items: [
                        if (semestresFiltres.isEmpty)
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Aucun semestre disponible'),
                          ),
                        ...semestresFiltres.map((s) => DropdownMenuItem<int?>(
                              value: s['id_semestre'] as int?,
                              child:
                                  Text('${s['nom_semestre']} (${s['annee']})'),
                            )),
                      ],
                      onChanged: semestresFiltres.isEmpty
                          ? null
                          : (v) {
                              setState(() => selectedSemestreId = v);
                            },
                      validator: (v) =>
                          v == null ? 'Sélectionnez un semestre' : null,
                    ),

                    // MESSAGE SI AUCUN SEMESTRE
                    if (semestresFiltres.isEmpty && selectedFiliereId != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '⚠️ Aucun semestre trouvé pour cette filière.\nVeuillez d\'abord créer des semestres.',
                          style: TextStyle(
                              color: Colors.orange.shade700, fontSize: 12),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // PROFESSEUR
                    DropdownButtonFormField<int?>(
                      value: selectedProfId,
                      decoration:
                          _inputDecoration('Professeur *', Icons.person),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Sélectionner un professeur'),
                        ),
                        ...profs.map((p) => DropdownMenuItem<int?>(
                              value: p['id_prof'] as int?,
                              child: Text('${p['nom']} ${p['prenom']}'),
                            )),
                      ],
                      onChanged: (v) => setState(() => selectedProfId = v),
                      validator: (v) =>
                          v == null ? 'Sélectionnez un professeur' : null,
                    ),
                    const SizedBox(height: 30),

                    // APERÇU
                    if (selectedFiliereId != null ||
                        selectedSemestreId != null ||
                        selectedProfId != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Aperçu:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isEditMode ? Colors.orange : Colors.blue,
                                )),
                            const SizedBox(height: 8),
                            Text(
                                'Module: ${_nomModuleController.text.isNotEmpty ? _nomModuleController.text : '...'}'),
                            Text(
                                'Coefficient: ${_coefficientController.text.isNotEmpty ? _coefficientController.text : '...'}'),
                            if (selectedFiliereId != null)
                              Text(
                                  'Filière: ${filieres.firstWhere((f) => f['id_filiere'] == selectedFiliereId, orElse: () => {
                                        'nom_filiere': '...'
                                      })['nom_filiere']}'),
                            if (selectedSemestreId != null &&
                                semestresFiltres.isNotEmpty)
                              Text('Semestre: ${semestresFiltres.firstWhere((s) => s['id_semestre'] == selectedSemestreId, orElse: () => {
                                    'nom_semestre': '...',
                                    'annee': '...'
                                  })['nom_semestre']} (${semestresFiltres.firstWhere((s) => s['id_semestre'] == selectedSemestreId, orElse: () => {'annee': '...'})['annee']})'),
                            if (selectedProfId != null)
                              Text(
                                  'Professeur: ${profs.firstWhere((p) => p['id_prof'] == selectedProfId, orElse: () => {
                                        'nom': '...',
                                        'prenom': ''
                                      })['nom']}'),
                          ],
                        ),
                      ),

                    const SizedBox(height: 30),

                    // BOUTONS
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _saveModule,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isEditMode ? Colors.orange : Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(isEditMode ? 'Enregistrer' : 'Ajouter',
                                    style: const TextStyle(fontSize: 16)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Annuler',
                                style: TextStyle(fontSize: 16)),
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

  @override
  void dispose() {
    _nomModuleController.dispose();
    _coefficientController.dispose();
    super.dispose();
  }
}
