import 'package:flutter/material.dart';
import '../drawer_widget.dart';
import 'gestion_note.dart';
import '/services/db_service.dart';
import '../home_prof.dart';

class ModuleListForGradesPage extends StatefulWidget {
  final Map<String, dynamic>? profData;
  const ModuleListForGradesPage({super.key, this.profData});

  @override
  State<ModuleListForGradesPage> createState() =>
      _ModuleListForGradesPageState();
}

class _ModuleListForGradesPageState extends State<ModuleListForGradesPage> {
  final Color royalBlue = const Color(0xFF0056D2);
  late Future<List<Map<String, dynamic>>> _modulesFuture;

  @override
  void initState() {
    super.initState();
    // On charge les modules du prof connecté depuis la base de données
    if (widget.profData != null) {
      _modulesFuture =
          DBService.instance.getModulesByProf(widget.profData!['id_prof']);
    } else {
      _modulesFuture = Future.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Saisir les Notes"),
        backgroundColor: royalBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        titleTextStyle: const TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        elevation: 0,
      ),
      drawer: AppDrawer(profData: widget.profData),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _modulesFuture,
        builder: (context, snapshot) {
          // 1. Chargement
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 2. Pas de données ou erreur
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Aucun module trouvé."));
          }

          final modules = snapshot.data!;

          // 3. Affichage de la liste
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: modules.length,
            itemBuilder: (context, index) {
              final module = modules[index];

              // Gestion de l'affichage (Année et Filière)
              String annee =
                  module['annee'] != null ? "${module['annee']}ème année" : "";
              String filiere = module['nom_filiere'] ?? "Commun";

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.edit_note, color: Colors.orange.shade800),
                  ),
                  title: Text(module['nom_module'],
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("$annee • $filiere"),
                  trailing: const Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey),
                  onTap: () {
                    // Navigation vers la page de notes
                    // On envoie 'module' qui contient {id_module, id_filiere, annee...}
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddGradePage(moduleData: module),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
