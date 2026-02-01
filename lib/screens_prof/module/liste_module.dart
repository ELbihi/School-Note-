
import 'package:flutter/material.dart';
import '/screens_prof/module/liste_etudiant_selon_module.dart'; 
import '/screens_prof/drawer_widget.dart';
import '/services/db_service.dart';
class ModuleListPage extends StatefulWidget {
  final Map<String, dynamic>? profData;
  const ModuleListPage({super.key, this.profData});

  @override
  State<ModuleListPage> createState() => _ModuleListPageState();
}

class _ModuleListPageState extends State<ModuleListPage> {
  final Color royalBlue = const Color(0xFF0056D2);
  // Variable pour stocker le futur résultat de la DB
  late Future<List<Map<String, dynamic>>> _modulesFuture;

  @override
  void initState() {
    super.initState();
    // Au démarrage de la page, on lance la récupération des modules
    if (widget.profData != null) {
      int idProf = widget.profData!['id_prof'];
      _modulesFuture = DBService.instance.getModulesByProf(idProf);
    } else {
      _modulesFuture = Future.value([]); // Sécurité si pas connecté
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar:  AppBar(
        title: const Text("Mes Modules"),
        backgroundColor: royalBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Retour à la page Home (TeacherDashboard)
            Navigator.pop(context);
          },
        ),
      ),
      drawer: AppDrawer(profData: widget.profData), 
      
      // FutureBuilder gère l'état : Chargement -> Données ou Erreur
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _modulesFuture,
        builder: (context, snapshot) {
          // 1. Cas : Chargement en cours
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 2. Cas : Erreur ou liste vide
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_off, size: 50, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  const Text("Aucun module assigné à ce professeur."),
                ],
              ),
            );
          }

          // 3. Cas : On a des données !
          final modules = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: modules.length,
            itemBuilder: (context, index) {
              final module = modules[index];
              
              // On prépare les textes (si null, on met un texte par défaut)
              String nomModule = module['nom_module'] ?? "Sans nom";
              String filiere = module['nom_filiere'] ?? "Commun"; // Pour les CP
              String semestre = module['nom_semestre'] ?? "";
              String annee = module['annee'] != null ? "${module['annee']}ème année" : "";

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: royalBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.book, color: royalBlue),
                  ),
                  title: Text(nomModule, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      "$annee \n$filiere • $semestre",
                      style: TextStyle(color: Colors.grey.shade700, height: 1.3),
                    ),
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onTap: () {
                    // IMPORTANT : On envoie les vraies données à la page suivante
                    // ET ON TRANSMET AUSSI LE profData
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudentListPage(
                          moduleData: module,
                          profData: widget.profData, // <-- TRANSMISSION DU profData
                        ),
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
