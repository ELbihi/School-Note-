// lib/screens/admin_home_page.dart
import 'package:flutter/material.dart';

import 'profs/gestion_prof.dart';
import 'students/gestion_etudiant.dart';
import 'profil.dart';
import '../services/db_service.dart';
import 'modules/gestion_module.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  late DBService dbService;
  int totalTeachers = 0;
  int totalStudents = 0;
  int totalModules = 0;
  int totalFilieres = 0;
  List<Map<String, dynamic>> studentDistribution = [];
  List<Map<String, dynamic>> filiereStats = [];

  @override
  void initState() {
    super.initState();
    dbService = DBService.instance;
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    final db = await dbService.database;

    // Compter les professeurs
    final teachersResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM PROF',
    );
    final teachersCount = teachersResult.first['count'] as int;

    // Compter les étudiants
    final studentsResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM STUDENT',
    );
    final studentsCount = studentsResult.first['count'] as int;

    // Compter les modules
    final modulesResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM MODULE',
    );
    final modulesCount = modulesResult.first['count'] as int;

    // Compter les filières
    final filieresResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM FILIERE',
    );
    final filieresCount = filieresResult.first['count'] as int;

    // Distribution par niveau
    final distributionResult = await db.rawQuery('''
      SELECT niveau, COUNT(*) as count 
      FROM STUDENT 
      GROUP BY niveau 
      ORDER BY niveau
    ''');

    // Statistiques par filière
    final filiereStatsResult = await db.rawQuery('''
      SELECT 
        f.nom_filiere,
        COUNT(s.id_student) as etudiants,
        COUNT(DISTINCT m.id_module) as modules
      FROM FILIERE f
      LEFT JOIN STUDENT s ON f.id_filiere = s.id_filiere
      LEFT JOIN MODULE m ON f.id_filiere = m.id_filiere
      GROUP BY f.id_filiere
      ORDER BY f.nom_filiere
    ''');

    setState(() {
      totalTeachers = teachersCount;
      totalStudents = studentsCount;
      totalModules = modulesCount;
      totalFilieres = filieresCount;
      studentDistribution = List<Map<String, dynamic>>.from(distributionResult);
      filiereStats = List<Map<String, dynamic>>.from(filiereStatsResult);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Icon(Icons.school),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        elevation: 4,
      ),
      drawer: _buildDrawer(),
      body: _buildBody(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(),
          _buildDrawerItem(
            icon: Icons.dashboard,
            title: 'dashboard',
            onTap: () {
              Navigator.pop(context);
            },
            isSelected: true,
          ),
          _buildDrawerItem(
            icon: Icons.school,
            title: 'Modules',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ModuleListPage(),
                ),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.people,
            title: 'Professeurs',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageProfessorsPage(),
                ),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.people_outline,
            title: 'Étudiants',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageStudentsPage(),
                ),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.person,
            title: 'Profil',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfilePage(),
                ),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.settings,
            title: 'Paramètres',
            onTap: () {
              Navigator.pop(context);
              // Navigation vers les paramètres
            },
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.exit_to_app,
            title: 'Déconnexion',
            onTap: () {
              Navigator.pop(context);
              // Logout logic
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return DrawerHeader(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.admin_panel_settings,
              size: 40,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Administrateur',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'admin@ac.ump.ma',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.blue : Colors.grey[700]),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.blue : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: onTap,
      tileColor: isSelected ? Colors.blue[50] : null,
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _loadStatistics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildStatisticsSection(),
            const SizedBox(height: 20),
            _buildStudentDistribution(),
            const SizedBox(height: 20),
            _buildFiliereStats(),
            const SizedBox(height: 20),
            _buildQuickActions(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistiques Générales',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _buildStatCard(
              title: 'Total Professeurs',
              value: totalTeachers.toString(),
              icon: Icons.people,
              color: Colors.green,
            ),
            _buildStatCard(
              title: 'Total Étudiants',
              value: totalStudents.toString(),
              icon: Icons.school,
              color: Colors.blue,
            ),
            _buildStatCard(
              title: 'Total Modules',
              value: totalModules.toString(),
              icon: Icons.library_books,
              color: Colors.orange,
            ),
            _buildStatCard(
              title: 'Filières',
              value: totalFilieres.toString(),
              icon: Icons.category,
              color: Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentDistribution() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bar_chart, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Distribution des Étudiants par Niveau',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 15),
            if (studentDistribution.isEmpty)
              const Center(
                child: Text(
                  'Chargement des données...',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Column(
                children: studentDistribution.map((data) {
                  final niveau = data['niveau'];
                  final count = data['count'];
                  final percentage =
                      (count / totalStudents * 100).toStringAsFixed(1);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Année $niveau',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '$count étudiants ($percentage%)',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: count / totalStudents,
                          backgroundColor: Colors.grey[200],
                          color: _getColorForLevel(niveau),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiliereStats() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.pie_chart, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Statistiques par Filière',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 15),
            if (filiereStats.isEmpty)
              const Center(
                child: Text(
                  'Chargement des données...',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(1.5),
                  2: FlexColumnWidth(1.5),
                },
                children: [
                  const TableRow(
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey)),
                    ),
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: Text(
                          'Filière',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: Text(
                          'Étudiants',
                          style: TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: Text(
                          'Modules',
                          style: TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  ...filiereStats.map((data) {
                    return TableRow(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey, width: 0.5),
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(data['nom_filiere']?.toString() ?? ''),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            data['etudiants'].toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            data['modules'].toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions Rapides',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _buildQuickActionCard(
              icon: Icons.add_circle,
              title: 'Ajouter Module',
              subtitle: 'Créer un nouveau module',
              color: Colors.blue,
              onTap: () => _navigateToAddModule(),
            ),
            _buildQuickActionCard(
              icon: Icons.person_add,
              title: 'Ajouter Prof',
              subtitle: 'Ajouter un professeur',
              color: Colors.green,
              onTap: () => _navigateToAddProfessor(),
            ),
            _buildQuickActionCard(
              icon: Icons.person_add_alt_1,
              title: 'Ajouter Étudiant',
              subtitle: 'Inscrire un nouvel étudiant',
              color: Colors.orange,
              onTap: () => _navigateToAddStudent(),
            ),
            _buildQuickActionCard(
              icon: Icons.add_chart,
              title: 'Rapports',
              subtitle: 'Générer des rapports',
              color: Colors.purple,
              onTap: () => _navigateToReports(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorForLevel(int level) {
    switch (level) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.green;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.purple;
      case 5:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _navigateToAddModule() {
    // Navigation vers l'ajout de module
    // TODO: Implémenter la navigation
  }

  void _navigateToAddProfessor() {
    // Navigation vers l'ajout de professeur
    // TODO: Implémenter la navigation
  }

  void _navigateToAddStudent() {
    // Navigation vers l'ajout d'étudiant
    // TODO: Implémenter la navigation
  }

  void _navigateToReports() {
    // Navigation vers les rapports
    // TODO: Implémenter la navigation
  }
}
