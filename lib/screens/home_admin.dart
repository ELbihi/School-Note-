import 'package:flutter/material.dart';
import 'profs/gestion_prof.dart';
import 'profs/add_edit_prof.dart';
import 'students/gestion_etudiant.dart';
import 'students/add_edit_etudiant.dart';
import '../services/db_service.dart';
import 'modules/gestion_module.dart';
import 'modules/add_edit_module_page.dart';
import 'note_etudiant.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  late DBService dbService;
  bool isLoading = true;

  // Statistiques uniquement
  int totalTeachers = 0;
  int totalStudents = 0;
  int totalModules = 0;
  int totalFilieres = 0;

  @override
  void initState() {
    super.initState();
    dbService = DBService.instance;
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => isLoading = true);

    // Appel au service simplifié
    final stats = await dbService.getAdminStats();

    if (mounted) {
      setState(() {
        totalTeachers = stats['teachers'] ?? 0;
        totalStudents = stats['students'] ?? 0;
        totalModules = stats['modules'] ?? 0;
        totalFilieres = stats['filieres'] ?? 0;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Icon(Icons.school),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: _buildDrawer(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Statistiques Générales'),
                    _buildStatsGrid(),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Actions Rapides'),
                    _buildQuickActionsGrid(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildStatCard('Professeurs', totalTeachers.toString(), Icons.people,
            Colors.green),
        _buildStatCard(
            'Étudiants', totalStudents.toString(), Icons.school, Colors.blue),
        _buildStatCard('Modules', totalModules.toString(), Icons.library_books,
            Colors.orange),
        _buildStatCard('Filières', totalFilieres.toString(), Icons.category,
            Colors.purple),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border(left: BorderSide(color: color, width: 5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            FittedBox(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildActionBtn(Icons.library_add, 'Nouv. Module', Colors.orange,
            () => _navTo(const ModuleFormPage())),
        _buildActionBtn(Icons.person_add, 'Nouv. Prof', Colors.green,
            () => _navTo(const ProfesseurFormPage())),
        _buildActionBtn(Icons.group_add, 'Nouv. Étudiant', Colors.blue,
            () => _navTo(const EtudiantFormPage())),
        _buildActionBtn(
            Icons.refresh, 'Actualiser', Colors.purple, _loadStatistics),
      ],
    );
  }

  Widget _buildActionBtn(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- DRAWER ---
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.blueAccent,
      child: Column(
        children: [
          _buildDrawerHeader(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const Divider(color: Colors.white24),
                _buildDrawerItem(Icons.dashboard, 'Tableau de bord',
                    () => Navigator.pop(context),
                    isSelected: true),
                _buildDrawerItem(Icons.library_books, 'Gestion Modules',
                    () => _navTo(const ModuleListPage())),
                _buildDrawerItem(Icons.people, 'Gestion Professeurs',
                    () => _navTo(const ManageProfessorsPage())),
                _buildDrawerItem(Icons.school, 'Gestion Étudiants',
                    () => _navTo(const ManageStudentsPage())),
                _buildDrawerItem(Icons.assessment, 'Bulletins & Notes',
                    () => _navTo(const NotesReportPage())),
                const Divider(color: Colors.white24),
                _buildDrawerItem(Icons.logout, 'Déconnexion', () {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/login', (route) => false);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return const UserAccountsDrawerHeader(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
        ),
      ),
      currentAccountPicture: CircleAvatar(
        backgroundColor: Colors.white,
        child: Icon(Icons.school, color: Colors.blue, size: 40),
      ),
      accountName: Text('Administrateur',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      accountEmail:
          Text('admin@ump.ac.ma', style: TextStyle(color: Colors.white70)),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap,
      {bool isSelected = false}) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.white : Colors.white70),
      title: Text(title,
          style: TextStyle(
              color: Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      onTap: onTap,
      selected: isSelected,
      selectedTileColor: Colors.white.withOpacity(0.1),
    );
  }

  void _navTo(Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (context) => page))
        .then((_) => _loadStatistics());
  }
}
