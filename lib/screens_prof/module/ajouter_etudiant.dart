import 'package:flutter/material.dart';
import 'package:note_school_ssbm/services/db_service.dart'; // Vérifiez le chemin de votre projet

class AjouterEtudiantPage extends StatefulWidget {
  final Map<String, dynamic> moduleData;
  final Map<String, dynamic>? profData;
  final VoidCallback? onSaved;

  const AjouterEtudiantPage({
    super.key,
    required this.moduleData,
    this.profData,
    this.onSaved,
  });

  @override
  State<AjouterEtudiantPage> createState() => _AjouterEtudiantPageState();
}

class _AjouterEtudiantPageState extends State<AjouterEtudiantPage> {
  final Color royalBlue = const Color(0xFF0056D2);
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs
  final TextEditingController _codeMassarController = TextEditingController();
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _groupeController = TextEditingController();

  String? _selectedFiliere;
  String? _selectedNiveau;
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  final List<String> _niveaux = ['CP1', 'CP2', 'CI1', 'CI2', 'CI3'];
  List<String> _filieres = [];

  @override
  void initState() {
    super.initState();
    _loadFilieres();
    _genererMotDePasse();
    _groupeController.text = "G1";
  }

  Future<void> _loadFilieres() async {
    try {
      final db = await DBService.instance.database;
      final result = await db.query('FILIERE', where: 'is_deleted = 0');

      List<String> filiereNames =
          result.map((row) => row['nom_filiere'] as String).toList();

      setState(() {
        _filieres = filiereNames;
        if (_filieres.isNotEmpty) {
          // Priorité à la filière du module passé en paramètre
          if (widget.moduleData['nom_filiere'] != null &&
              _filieres.contains(widget.moduleData['nom_filiere'])) {
            _selectedFiliere = widget.moduleData['nom_filiere'];
          } else {
            _selectedFiliere = _filieres.first;
          }
        }
      });
    } catch (e) {
      print("Erreur chargement filières: $e");
    }
  }

  void _genererMotDePasse() {
    String password = 'etud${DateTime.now().millisecond % 1000}';
    _passwordController.text = password;
  }

  @override
  void dispose() {
    _codeMassarController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _groupeController.dispose();
    super.dispose();
  }

  // MÉTHODE CORRIGÉE AVEC DOUBLE INSERTION (STUDENT + USER)
  Future<void> _ajouterEtudiant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final db = await DBService.instance.database;

      await db.transaction((txn) async {
        // 1. Vérifier si l'email existe dans la table USER
        final existingUser = await txn.query(
          'USER',
          where: 'email = ? AND is_deleted = 0',
          whereArgs: [_emailController.text.trim()],
        );
        if (existingUser.isNotEmpty) throw "Cet email est déjà utilisé.";

        // 2. Vérifier si le Code Massar existe
        final existingmassar = await txn.query(
          'STUDENT',
          where: 'massar = ? AND is_deleted = 0',
          whereArgs: [_codeMassarController.text.trim()],
        );
        if (existingmassar.isNotEmpty) throw "Ce Code Massar/CNE existe déjà.";

        // 3. Récupérer l'ID de la filière
        final filiereRes = await txn.query(
          'FILIERE',
          where: 'nom_filiere = ?',
          whereArgs: [_selectedFiliere],
        );
        int? idFiliere = filiereRes.isNotEmpty
            ? filiereRes.first['id_filiere'] as int
            : null;

        // 4. Insertion dans STUDENT
        int newStudentId = await txn.insert('STUDENT', {
          'massar': _codeMassarController.text.trim(),
          'nom': _nomController.text.trim().toUpperCase(),
          'prenom': _prenomController.text.trim(),
          'email': _emailController.text.trim(),
          'id_filiere': idFiliere,
          'niveau': _selectedNiveau,
          'groupe': _groupeController.text.trim(),
          'is_deleted': 0,
          'sync_status': 'pending',
          'updated_at': DateTime.now().toIso8601String(),
        });

        // 5. Insertion dans USER (pour permettre la connexion)
        await txn.insert('USER', {
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
          'role': 'STUDENT',
          'ref_id': newStudentId, // Lien crucial
          'is_deleted': 0,
          'sync_status': 'pending',
          'updated_at': DateTime.now().toIso8601String(),
        });
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Étudiant ajouté avec succès !"),
            backgroundColor: Colors.green),
      );

      Navigator.pop(context);
      if (widget.onSaved != null) widget.onSaved!();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String moduleName = widget.moduleData['nom_module'] ?? "Module";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ajouter un Étudiant"),
        backgroundColor: royalBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
            color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  "Nouvel Étudiant",
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: royalBlue),
                ),
              ),
              const SizedBox(height: 5),
              Center(
                  child: Text("Module: $moduleName",
                      style: TextStyle(color: Colors.grey.shade600))),
              const SizedBox(height: 25),

              // --- CHAMPS DU FORMULAIRE ---
              _buildTextField(_codeMassarController, "Code Massar / CNE *",
                  Icons.confirmation_number),
              const SizedBox(height: 15),
              _buildTextField(_nomController, "Nom *", Icons.person),
              const SizedBox(height: 15),
              _buildTextField(
                  _prenomController, "Prénom *", Icons.person_outline),
              const SizedBox(height: 15),
              _buildTextField(_emailController, "Email *", Icons.email,
                  isEmail: true),
              const SizedBox(height: 15),

              // Dropdown Filière
              DropdownButtonFormField<String>(
                value: _selectedFiliere,
                decoration: _inputDecoration("Filière *", Icons.school),
                items: _filieres
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedFiliere = val),
                validator: (val) => val == null ? "Champ obligatoire" : null,
              ),
              const SizedBox(height: 15),

              // Dropdown Niveau
              DropdownButtonFormField<String>(
                value: _selectedNiveau,
                decoration: _inputDecoration("Niveau *", Icons.leaderboard),
                items: _niveaux
                    .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedNiveau = val),
                validator: (val) => val == null ? "Champ obligatoire" : null,
              ),
              const SizedBox(height: 15),

              _buildTextField(_groupeController, "Groupe", Icons.group),
              const SizedBox(height: 15),

              // Mot de passe
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration:
                    _inputDecoration("Mot de passe *", Icons.lock).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: royalBlue),
                    onPressed: () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible),
                  ),
                ),
                validator: (val) =>
                    (val == null || val.length < 4) ? "Trop court" : null,
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _genererMotDePasse,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text("Régénérer"),
                ),
              ),

              const SizedBox(height: 20),

              // --- BOUTONS ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _ajouterEtudiant,
                  style: ElevatedButton.styleFrom(backgroundColor: royalBlue),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("ENREGISTRER",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("ANNULER"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper pour le design des inputs
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {bool isEmail = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      decoration: _inputDecoration(label, icon),
      validator: (val) =>
          (val == null || val.isEmpty) ? "Champ obligatoire" : null,
    );
  }
}
