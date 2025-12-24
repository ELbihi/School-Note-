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
      _selectedFiliere = etud['id_filiere'] as int?;
      _selectedNiveau = etud['niveau'] as int?;
    }
  }

  Future<void> _loadFilieres() async {
    try {
      final db = await dbService.database;
      final filieres = await db.query('FILIERE');
      setState(() {
        _filieres = filieres;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveEtudiant() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFiliere == null || _selectedNiveau == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une filière et un niveau'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final db = await dbService.database;
      final data = {
        'massar': _massarController.text.trim(),
        'nom': _nomController.text.trim(),
        'prenom': _prenomController.text.trim(),
        'email': _emailController.text.trim(),
        'groupe': _groupeController.text.trim(),
        'niveau': _selectedNiveau,
        'id_filiere': _selectedFiliere,
      };

      // Ajouter le mot de passe seulement si modifié/nouveau
      if (_passwordController.text.isNotEmpty || !_isEditing) {
        data['password'] = _passwordController.text.isEmpty
            ? '123456'
            : _passwordController.text;
      }

      if (_isEditing) {
        await db.update(
          'STUDENT',
          data,
          where: 'id_student = ?',
          whereArgs: [widget.etudiant!['id_student']],
        );
      } else {
        await db.insert('STUDENT', data);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? 'Étudiant modifié avec succès'
              : 'Étudiant ajouté avec succès'),
          backgroundColor: Colors.green,
        ),
      );

      widget.onSaved?.call();

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(_isEditing ? 'Modifier l\'Étudiant' : 'Ajouter un Étudiant'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildWelcomeSection(),
                  const SizedBox(height: 30),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _massarController,
                          decoration: const InputDecoration(
                            labelText: 'Code Massar *',
                            prefixIcon: Icon(Icons.badge, color: Colors.blue),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12)),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer le code Massar';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _nomController,
                          decoration: const InputDecoration(
                            labelText: 'Nom *',
                            prefixIcon:
                                Icon(Icons.person_outline, color: Colors.blue),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12)),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer le nom';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _prenomController,
                          decoration: const InputDecoration(
                            labelText: 'Prénom *',
                            prefixIcon: Icon(Icons.person, color: Colors.blue),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12)),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer le prénom';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email *',
                            prefixIcon: Icon(Icons.email, color: Colors.blue),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12)),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer l\'email';
                            }
                            if (!value.contains('@')) {
                              return 'Email invalide';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int?>(
                                value: _selectedFiliere,
                                decoration: const InputDecoration(
                                  labelText: 'Filière *',
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(12)),
                                  ),
                                  contentPadding:
                                      EdgeInsets.symmetric(horizontal: 12),
                                ),
                                items: [
                                  const DropdownMenuItem(
                                      value: null, child: Text('Sélectionner')),
                                  ..._filieres.map((filiere) {
                                    return DropdownMenuItem<int?>(
                                      value: filiere['id_filiere'] as int,
                                      child: Text(
                                          filiere['nom_filiere']?.toString() ??
                                              ''),
                                    );
                                  }),
                                ],
                                onChanged: (value) =>
                                    setState(() => _selectedFiliere = value),
                                validator: (value) => value == null
                                    ? 'Sélectionnez une filière'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: DropdownButtonFormField<int?>(
                                value: _selectedNiveau,
                                decoration: const InputDecoration(
                                  labelText: 'Niveau *',
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(12)),
                                  ),
                                  contentPadding:
                                      EdgeInsets.symmetric(horizontal: 12),
                                ),
                                items: [
                                  const DropdownMenuItem(
                                      value: null, child: Text('Sélectionner')),
                                  for (int i = 1; i <= 5; i++)
                                    DropdownMenuItem(
                                        value: i, child: Text('Année $i')),
                                ],
                                onChanged: (value) =>
                                    setState(() => _selectedNiveau = value),
                                validator: (value) => value == null
                                    ? 'Sélectionnez un niveau'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _groupeController,
                          decoration: const InputDecoration(
                            labelText: 'Groupe',
                            prefixIcon: Icon(Icons.group, color: Colors.blue),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: _isEditing
                                ? 'Mot de passe (laisser vide pour ne pas changer)'
                                : 'Mot de passe *',
                            prefixIcon:
                                const Icon(Icons.lock, color: Colors.blue),
                            border: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12)),
                            ),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (!_isEditing &&
                                (value == null || value.isEmpty)) {
                              return 'Veuillez entrer le mot de passe';
                            }
                            if (value != null &&
                                value.isNotEmpty &&
                                value.length < 6) {
                              return 'Minimum 6 caractères';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  if (_isEditing && widget.etudiant != null)
                    Card(
                      margin: const EdgeInsets.only(top: 20),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Informations système',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Text('ID: '),
                                Text(
                                  widget.etudiant!['id_student'].toString(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveEtudiant,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                      color: Colors.white),
                                )
                              : Text(
                                  _isEditing
                                      ? 'Mettre à jour'
                                      : 'Ajouter l\'Étudiant',
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.white),
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSaving
                              ? null
                              : () {
                                  if (Navigator.canPop(context)) {
                                    Navigator.pop(context);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Annuler',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade50, Colors.blue.shade100],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            _isEditing ? Icons.edit : Icons.person_add_alt_1,
            size: 50,
            color: Colors.blue.shade800,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Modifier l\'Étudiant' : 'Ajouter un Étudiant',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 3, 58, 104),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isEditing
                      ? 'Modifiez les informations de l\'étudiant'
                      : 'Remplissez les informations de l\'étudiant',
                  style: TextStyle(fontSize: 16, color: Colors.blue.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
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
