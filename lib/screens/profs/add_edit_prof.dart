import 'package:flutter/material.dart';
import 'package:note_school_ssbm/services/db_service.dart';

class ProfesseurFormPage extends StatefulWidget {
  final Map<String, dynamic>? professeur;
  final VoidCallback? onSaved;

  const ProfesseurFormPage({
    super.key,
    this.professeur,
    this.onSaved,
  });

  @override
  State<ProfesseurFormPage> createState() => _ProfesseurFormPageState();
}

class _ProfesseurFormPageState extends State<ProfesseurFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late DBService dbService;
  bool _isSaving = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    dbService = DBService.instance;
    _isEditing = widget.professeur != null;
    
    if (_isEditing) {
      final prof = widget.professeur!;
      _nomController.text = prof['nom']?.toString() ?? '';
      _prenomController.text = prof['prenom']?.toString() ?? '';
      _emailController.text = prof['email']?.toString() ?? '';
    }
  }

  Future<void> _saveProfesseur() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final db = await dbService.database;
      final data = {
        'nom': _nomController.text.trim(),
        'prenom': _prenomController.text.trim(),
        'email': _emailController.text.trim(),
      };

      // Ajouter le mot de passe seulement si modifié/nouveau
      if (_passwordController.text.isNotEmpty || !_isEditing) {
        data['password'] = _passwordController.text.isEmpty ? '123456' : _passwordController.text;
      }

      if (_isEditing) {
        await db.update(
          'PROF',
          data,
          where: 'id_prof = ?',
          whereArgs: [widget.professeur!['id_prof']],
        );
      } else {
        await db.insert('PROF', data);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing 
              ? 'Professeur modifié avec succès'
              : 'Professeur ajouté avec succès'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Callback pour rafraîchir la liste
      widget.onSaved?.call();
      
      // Retourner à la liste
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
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
        title: Text(_isEditing ? 'Modifier le Professeur' : 'Ajouter un Professeur'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // En-tête avec le design spécifié
            _buildWelcomeSection(),
            const SizedBox(height: 30),
            
            // Formulaire
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Champ Nom
                  TextFormField(
                    controller: _nomController,
                    decoration: const InputDecoration(
                      labelText: 'Nom *',
                      prefixIcon: Icon(Icons.person_outline, color: Colors.blue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                        borderRadius: BorderRadius.all(Radius.circular(12)),
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
                  
                  // Champ Prénom
                  TextFormField(
                    controller: _prenomController,
                    decoration: const InputDecoration(
                      labelText: 'Prénom *',
                      prefixIcon: Icon(Icons.person, color: Colors.blue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                        borderRadius: BorderRadius.all(Radius.circular(12)),
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
                  
                  // Champ Email
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      prefixIcon: Icon(Icons.email, color: Colors.blue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                        borderRadius: BorderRadius.all(Radius.circular(12)),
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
                  
                  // Champ Mot de passe
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: _isEditing 
                          ? 'Mot de passe (laisser vide pour ne pas changer)' 
                          : 'Mot de passe *',
                      prefixIcon: const Icon(Icons.lock, color: Colors.blue),
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (!_isEditing && (value == null || value.isEmpty)) {
                        return 'Veuillez entrer le mot de passe';
                      }
                      if (value != null && value.isNotEmpty && value.length < 6) {
                        return 'Minimum 6 caractères';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            
            // Section informations système (seulement en mode édition)
            if (_isEditing && widget.professeur != null)
              _buildSystemInfoSection(),
            
            const SizedBox(height: 40),
            
            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfesseur,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(color: Colors.white),
                          )
                        : Text(
                            _isEditing ? 'Mettre à jour' : 'Ajouter le Professeur',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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
                      elevation: 2,
                    ),
                    child: Text(
                      'Annuler',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
        border: Border.all(color: Colors.blue.shade200, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isEditing ? Icons.edit : Icons.person_add,
              size: 40,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Modifier le Professeur' : 'Ajouter un Professeur',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 3, 58, 104),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isEditing 
                      ? 'Modifiez les informations du professeur'
                      : 'Remplissez les informations du professeur',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations système',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                const Text('ID: ', style: TextStyle(color: Colors.grey)),
                Text(
                  widget.professeur!['id_prof'].toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (widget.professeur!['created_at'] != null)
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  const Text('Créé le: ', style: TextStyle(color: Colors.grey)),
                  Text(
                    widget.professeur!['created_at'].toString(),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}