import 'package:flutter/material.dart';
import 'package:note_school_ssbm/services/settingsprovider.dart';
import 'package:provider/provider.dart';
import 'package:note_school_ssbm/models/student.dart';
import 'package:note_school_ssbm/ui_student/parametre.dart';
import 'package:note_school_ssbm/ui_student/profil.dart';
import 'homepagestudent.dart';

class StudentDrawer extends StatelessWidget {
  final Map<Student, dynamic> studentData;
  final int studentId;


  const StudentDrawer({
    Key? key,
    required this.studentData,
    required this.studentId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
        final Color royalBlue = const Color(0xFF0056D2);
    // 1. Récupérer le provider
    final settings = Provider.of<SettingsProvider>(context);
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor, // Thème dynamique
      child: Column(
        children: [
          // En-tête (on passe le thème et settings)
          _buildDrawerHeader(theme, settings),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.home,
                  title: settings.translate("Accueil", "Home"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            Homepagestudent(studentId: studentId),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.person,
                  title: settings.translate("Mon Profil", "My Profile"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ProfilePage(
                                studentId: studentId,
                                initialData:
                                    studentData.cast<String, dynamic>())));
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.assignment,
                  title: settings.translate("Mes Notes", "My Grades"),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToGrades(context, settings);
                  },
                ),
                const Divider(),
                _buildDrawerItem(
                  context,
                  icon: Icons.settings,
                  title: settings.translate("Paramètres", "Settings"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SettingsPage()));
                  },
                ),
                const Divider(),
                _buildDrawerItem(
                  context,
                  icon: Icons.logout,
                  title: settings.translate("Déconnexion", "Logout"),
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    _showLogoutDialog(context, settings);
                  },
                ),
              ],
            ),
          ),
          _buildAppVersion(settings),
        ],
      ),
    );
  }

  // Header avec couleur primaire du thème
  Widget _buildDrawerHeader(ThemeData theme, SettingsProvider settings) {
    return Container(
      width: double.infinity,
      color: theme.primaryColor, // Utilise la couleur du thème (Bleu ou autre)
      padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
      child: Column(
        children: [
          // Photo de profil
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white24,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: studentData['photo'] != null
                ? CircleAvatar(
                    backgroundImage: NetworkImage(studentData['photo']))
                : const Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            "${studentData['prenom'] ?? ''} ${studentData['nom'] ?? ''}",
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            studentData['email'] ?? '',
            style:
                TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    Color? color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(icon, color: color ?? Theme.of(context).primaryColor),
      title: Text(
        title,
        style: TextStyle(
          color: color ??
              (isDark
                  ? Colors.white
                  : Colors.black87), // Texte blanc en mode sombre
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }

  Widget _buildAppVersion(SettingsProvider settings) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        "${settings.translate("Version", "Version")} 1.0.0",
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
    );
  }

  void _navigateToGrades(BuildContext context, SettingsProvider settings) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(settings.translate("Page Mes Notes - À implémenter",
              "Grades Page - To be implemented"))),
    );
  }

  void _showLogoutDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(settings.translate("Déconnexion", "Logout")),
          content: Text(settings.translate("Êtes-vous sûr ?", "Are you sure?")),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(settings.translate("Annuler", "Cancel")),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (route) => false);
              },
              child: Text(settings.translate("Déconnexion", "Logout"),
                  style: const TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
