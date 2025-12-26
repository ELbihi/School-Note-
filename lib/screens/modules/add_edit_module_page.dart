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
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      // Utilisation des méthodes centralisées de DBService
      final results = await Future.wait([
        dbService.getAll('FILIERE', orderBy: 'nom_filiere'),
        dbService.getAll('PROF', orderBy: 'nom'),
        dbService.getAll('SEMESTRE'), // Charger tous les semestres au début
      ]);

      setState(() {
        filieres = results[0];
        profs = results[1];
        semestresFiltres = results[2];
      });

      // Vérification de sécurité pour le Dropdown Semestre en mode édition
      if (isEditMode && selectedSemestreId != null) {
        bool exists =
            semestresFiltres.any((s) => s['id_semestre'] == selectedSemestreId);
        if (!exists) selectedSemestreId = null;
      }
    } catch (e) {
      debugPrint('Erreur initialisation données: $e');
    } finally {
      if (mounted) setState(() => isDataLoading = false);
    }
  }

  // Cette méthode est appelée quand on change de filière
  Future<void> _refreshSemestres() async {
    // Si votre logique dépend de la filière, filtrez ici.
    // Sinon, on recharge simplement la liste.
    final data = await dbService.getAll('SEMESTRE');

    setState(() {
      semestresFiltres = data;
      // CRUCIAL : On vérifie si le semestre sélectionné est toujours valide
      if (selectedSemestreId != null) {
        bool stillExists =
            semestresFiltres.any((s) => s['id_semestre'] == selectedSemestreId);
        if (!stillExists) {
          selectedSemestreId = null;
        }
      }
    });
  }

  Future<void> _saveModule() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    try {
      final data = {
        'nom_module': _nomModuleController.text.trim(),
        'coefficient': double.tryParse(_coefficientController.text) ?? 1.0,
        'id_filiere': selectedFiliereId,
        'id_semestre': selectedSemestreId,
        'id_prof': selectedProfId,
      };

      int result;
      if (isEditMode) {
        result =
            await dbService.updateModule(widget.module!['id_module'], data);
      } else {
        result = await dbService.addModule(data);
      }

      if (result > 0) {
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Erreur lors de l'enregistrement: $e"),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Modifier Module' : 'Nouveau Module'),
        backgroundColor: Colors.blueAccent,
      ),
      body: isDataLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(
                        _nomModuleController, 'Nom du module', Icons.book),
                    const SizedBox(height: 15),
                    _buildTextField(
                        _coefficientController, 'Coefficient', Icons.calculate,
                        isNumber: true),
                    const SizedBox(height: 15),
                    _buildDropdownFiliere(),
                    const SizedBox(height: 15),
                    _buildDropdownSemestre(),
                    const SizedBox(height: 15),
                    _buildDropdownProf(),
                    const SizedBox(height: 30),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'Ce champ est requis' : null,
    );
  }

  Widget _buildDropdownFiliere() {
    return DropdownButtonFormField<int>(
      value: selectedFiliereId,
      decoration: const InputDecoration(
          labelText: 'Filière',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.school)),
      items: filieres.map((f) {
        return DropdownMenuItem<int>(
          value: f['id_filiere'] as int,
          child: Text(f['nom_filiere'].toString()),
        );
      }).toList(),
      onChanged: (val) {
        setState(() => selectedFiliereId = val);
        _refreshSemestres();
      },
      validator: (val) => val == null ? 'Sélectionnez une filière' : null,
    );
  }

  Widget _buildDropdownSemestre() {
    return DropdownButtonFormField<int>(
      value: selectedSemestreId,
      decoration: const InputDecoration(
          labelText: 'Semestre',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.timer)),
      items: semestresFiltres.map((s) {
        return DropdownMenuItem<int>(
          value: s['id_semestre'] as int,
          child: Text(s['nom_semestre'].toString()),
        );
      }).toList(),
      onChanged: (val) => setState(() => selectedSemestreId = val),
      validator: (val) => val == null ? 'Sélectionnez un semestre' : null,
    );
  }

  Widget _buildDropdownProf() {
    return DropdownButtonFormField<int>(
      value: selectedProfId,
      decoration: const InputDecoration(
          labelText: 'Professeur',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.person)),
      items: profs.map((p) {
        return DropdownMenuItem<int>(
          value: p['id_prof'] as int,
          child: Text("${p['nom']} ${p['prenom']}"),
        );
      }).toList(),
      onChanged: (val) => setState(() => selectedProfId = val),
      validator: (val) => val == null ? 'Sélectionnez un professeur' : null,
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10))),
        onPressed: isLoading ? null : _saveModule,
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(isEditMode ? 'METTRE À JOUR' : 'ENREGISTRER',
                style: const TextStyle(fontSize: 16, color: Colors.white)),
      ),
    );
  }
}
