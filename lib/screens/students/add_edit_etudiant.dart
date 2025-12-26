import 'package:flutter/material.dart';
import 'package:note_school_ssbm/services/db_service.dart';

class EtudiantFormPage extends StatefulWidget {
  final Map<String, dynamic>? etudiant;
  final VoidCallback? onSaved;

  const EtudiantFormPage({
    super.key,
    this.etudiant,
    this.onSaved,
  });

  @override
  State<EtudiantFormPage> createState() => _EtudiantFormPageState();
}

class _EtudiantFormPageState extends State<EtudiantFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _massarController = TextEditingController();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _groupeController = TextEditingController();

  late DBService dbService;
  List<Map<String, dynamic>> _filieres = [];
  int? _selectedFiliere;
  int? _selectedNiveau;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;

  @override
void initState() {
  super.initState();
  dbService = DBService.instance;
  _isEditing = widget.etudiant != null;
  _loadFilieres();

  if (_isEditing) {
    final etud = widget.etudiant!;
    _massarController.text = etud['massar']?.toString() ?? '';
    _nomController.text = etud['nom']?.toString() ?? '';
    _prenomController.text = etud['prenom']?.toString() ?? '';
    _emailController.text = etud['email']?.toString() ?? '';
    _groupeController.text = etud['groupe']?.toString() ?? '';

    // CORRECTION ICI : Utiliser int.tryParse pour éviter le crash de cast
    _selectedFiliere = int.tryParse(etud['id_filiere'].toString());
    _selectedNiveau = int.tryParse(etud['niveau'].toString());
  }
}

  Future<void> _loadFilieres() async {
    try {
      // Utilisation de la méthode générique que nous avons créée dans DBService
      final filieres =
          await dbService.getAll('FILIERE', orderBy: 'nom_filiere');
      setState(() {
        _filieres = filieres;

        // Sécurité : Vérifier si la filière sélectionnée existe dans la liste
        if (_isEditing && _selectedFiliere != null) {
          if (!_filieres.any((f) => f['id_filiere'] == _selectedFiliere)) {
            _selectedFiliere = null;
          }
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur chargement filières: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveEtudiant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    // Préparation des données pour la base de données
    final data = {
      'massar': _massarController.text.trim(),
      'nom': _nomController.text.trim(),
      'prenom': _prenomController.text.trim(),
      'email': _emailController.text.trim(),
      'id_filiere': _selectedFiliere,
      'groupe': _groupeController.text.trim(),
      'niveau': _selectedNiveau,
    };

    // On n'ajoute le mot de passe que s'il est saisi (important pour la modification)
    if (_passwordController.text.isNotEmpty) {
      data['password'] = _passwordController.text;
    } else if (!_isEditing) {
      // Mot de passe par défaut si création et vide
      data['password'] = '123456';
    }

    try {
      if (_isEditing) {
        await dbService.updateStudent(widget.etudiant!['id_student'], data);
      } else {
        await dbService.addStudent(data);
      }

      if (widget.onSaved != null) widget.onSaved!();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Opération réussie"),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(_isEditing ? 'Modifier l\'Étudiant' : 'Ajouter un Étudiant'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(
                        _massarController, 'Code Massar *', Icons.badge),
                    const SizedBox(height: 15),
                    _buildTextField(
                        _nomController, 'Nom *', Icons.person_outline),
                    const SizedBox(height: 15),
                    _buildTextField(
                        _prenomController, 'Prénom *', Icons.person),
                    const SizedBox(height: 15),
                    _buildTextField(_emailController, 'Email *', Icons.email,
                        isEmail: true),
                    const SizedBox(height: 15),
                    _buildDropdownFiliere(),
                    const SizedBox(height: 15),
                    _buildDropdownNiveau(),
                    const SizedBox(height: 15),
                    _buildTextField(_groupeController, 'Groupe', Icons.group),
                    const SizedBox(height: 15),
                    _buildTextField(
                        _passwordController,
                        _isEditing
                            ? 'Nouveau mot de passe (optionnel)'
                            : 'Mot de passe *',
                        Icons.lock,
                        isPassword: true),
                    const SizedBox(height: 30),
                    _buildSubmitButtons(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {bool isEmail = false, bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (!isPassword && (value == null || value.isEmpty))
          return 'Champ requis';
        if (isEmail && value != null && !value.contains('@'))
          return 'Email invalide';
        if (!isPassword && label.contains('Massar') && value!.length < 5)
          return 'Code trop court';
        return null;
      },
    );
  }

  Widget _buildDropdownFiliere() {
    return DropdownButtonFormField<int>(
      value: _selectedFiliere,
      decoration: InputDecoration(
        labelText: 'Filière *',
        prefixIcon: const Icon(Icons.school, color: Colors.blueAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: _filieres.map((f) {
        return DropdownMenuItem<int>(
          value: f['id_filiere'] as int,
          child: Text(f['nom_filiere'].toString()),
        );
      }).toList(),
      onChanged: (val) => setState(() => _selectedFiliere = val),
      validator: (val) => val == null ? 'Sélectionnez une filière' : null,
    );
  }

  Widget _buildDropdownNiveau() {
    return DropdownButtonFormField<int>(
      value: _selectedNiveau,
      decoration: InputDecoration(
        labelText: 'Niveau *',
        prefixIcon: const Icon(Icons.trending_up, color: Colors.blueAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: List.generate(5, (index) {
        return DropdownMenuItem<int>(
          value: index + 1,
          child: Text('Année ${index + 1}'),
        );
      }),
      onChanged: (val) => setState(() => _selectedNiveau = val),
      validator: (val) => val == null ? 'Sélectionnez un niveau' : null,
    );
  }

  Widget _buildSubmitButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveEtudiant,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text(_isEditing ? 'METTRE À JOUR' : 'AJOUTER'),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Colors.grey),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('ANNULER', style: TextStyle(color: Colors.grey)),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _massarController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _groupeController.dispose();
    super.dispose();
  }
}
