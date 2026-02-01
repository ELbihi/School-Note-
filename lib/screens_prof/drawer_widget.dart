import 'package:flutter/material.dart';
import '../services/login.dart';
import '../screens_prof/module/liste_module.dart';
import '../screens_prof/note/g_note_selon_module.dart';
import 'home_prof.dart'; // ASSUREZ-VOUS DE CET IMPORT

class AppDrawer extends StatelessWidget {
  final Map<String, dynamic>? profData;

  const AppDrawer({super.key, this.profData});

  @override
  Widget build(BuildContext context) {
    final Color royalBlue = const Color(0xFF0056D2);

    String nom = profData?['nom'] ?? "Enseignant";
    String prenom = profData?['prenom'] ?? "";
    String email = profData?['email'] ?? "email@school.ma";
    String nomComplet = "$prenom $nom";

    return Drawer(
      backgroundColor: royalBlue,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: Colors.white24, width: 1)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child:
                        Icon(Icons.person, size: 35, color: Color(0xFF0056D2)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    nomComplet,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(email,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // --- NOUVEL ÉLÉMENT : RETOUR À L'ACCUEIL ---
                _buildDrawerItem(Icons.home_rounded, "Tableau de bord",
                    onTap: () {
                  Navigator.pop(context); // Fermer le drawer
                  // Utilisation de pushAndRemoveUntil pour éviter d'empiler inutilement les pages
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            TeacherDashboard(profData: profData ?? {})),
                    (route) => false, // Nettoie l'historique de navigation
                  );
                }),

                _buildDrawerItem(Icons.class_rounded, "Modules", onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              ModuleListPage(profData: profData)));
                }),

                _buildDrawerItem(Icons.assessment_rounded, "Gestion des Notes",
                    onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              ModuleListForGradesPage(profData: profData)));
                }),

                const Divider(color: Colors.white24), // Séparateur visuel

                _buildDrawerItem(Icons.settings, "Paramètres", onTap: () {
                  Navigator.pop(context);
                  // Implémentation future
                }),

                _buildDrawerItem(Icons.logout_rounded, "Déconnexion",
                    onTap: () {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginPage()),
                      (route) => false);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title,
          style: const TextStyle(color: Colors.white, fontSize: 16)),
      onTap: onTap,
    );
  }
}
