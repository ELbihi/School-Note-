import 'package:flutter/material.dart';
import 'profs/gestion_prof.dart';
import 'profs/add_edit_prof.dart';
import 'students/gestion_etudiant.dart';
import 'students/add_edit_etudiant.dart';
import 'profil.dart';
import '../services/db_service.dart';
import 'modules/gestion_module.dart';
import 'modules/add_edit_module_page.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  late DBService dbService;
  bool isLoading = true;
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
    final stats = await dbService.getAdminStats();
    setState(() {
      totalTeachers = stats['teachers'];
      totalStudents = stats['students'];
      totalModules = stats['modules'];
      totalFilieres = stats['filieres'];
      isLoading = false;
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
                    const SizedBox(height: 24),
                    _buildStudentDistributionCard(),
                    const SizedBox(height: 24),
                    _buildFiliereStatsCard(),
                    const SizedBox(height: 24),
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
              // Empêche le texte de déborder si le chiffre est trop grand
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentDistributionCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.bar_chart, color: Colors.blue),
              SizedBox(width: 8),
              Text('Distribution par Niveau',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
            ]),
            const SizedBox(height: 16),
            if (studentDistribution.isEmpty)
              const Center(child: Text("Aucune donnée disponible")),
            ...studentDistribution.map((data) {
              final String niveau = data['niveau']?.toString() ?? '?';
              final int count = int.tryParse(data['count'].toString()) ?? 0;
              final double percent =
                  totalStudents > 0 ? count / totalStudents : 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Année $niveau',
                            style:
                                const TextStyle(fontWeight: FontWeight.w500)),
                        Text('$count (${(percent * 100).toStringAsFixed(1)}%)',
                            style: const TextStyle(
                                color: Colors.blueGrey,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: percent,
                      color: _getColorForLevel(int.tryParse(niveau) ?? 0),
                      backgroundColor: Colors.grey[200],
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFiliereStatsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Row(children: [
              Icon(Icons.table_chart, color: Colors.blue),
              SizedBox(width: 8),
              Text('Détails par Filière',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
            ]),
            const SizedBox(height: 10),
            // Utilisation d'un container avec largeur infinie pour le défilement horizontal
            SizedBox(
              width: double.infinity,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 20,
                  columns: const [
                    DataColumn(
                        label: Text('Filière',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('Étud.',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(
                        label: Text('Mod.',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: filiereStats
                      .map((data) => DataRow(cells: [
                            DataCell(Text(data['nom_filiere'].toString())),
                            DataCell(Text(data['etudiants'].toString())),
                            DataCell(Text(data['modules'].toString())),
                          ]))
                      .toList(),
                ),
              ),
            ),
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
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 4),
            Flexible(
              // Pour éviter le débordement du texte sur petit écran
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForLevel(int level) {
    List<Color> palette = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.cyan
    ];
    return palette[level % palette.length];
  }

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
                const Divider(),
                _buildDrawerItem(Icons.dashboard, 'Tableau de bord',
                    () => Navigator.pop(context),
                    isSelected: true),
                _buildDrawerItem(Icons.library_books, 'Gestion Modules',
                    () => _navTo(const ModuleListPage())),
                _buildDrawerItem(Icons.people, 'Gestion Professeurs',
                    () => _navTo(const ManageProfessorsPage())),
                _buildDrawerItem(Icons.school, 'Gestion Étudiants',
                    () => _navTo(const ManageStudentsPage())),
                _buildDrawerItem(Icons.person, 'Mon Profil',
                    () => _navTo(const ProfilePage())),
                const Divider(),
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
    return UserAccountsDrawerHeader(
      margin:
          EdgeInsets.zero, // Évite les espaces blancs parasites sur les côtés
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
        ),
      ),
      currentAccountPicture: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const CircleAvatar(
          child: Icon(
            Icons.school,
            color: Colors.blue,
          ),
        ),
      ),
      accountName: const Text(
        'Administrateur',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          letterSpacing: 0.5,
          color: Colors.white, // Toujours forcer le blanc sur fond bleu
        ),
      ),
      accountEmail: const Text(
        'admin@ump.ac.ma',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap,
      {bool isSelected = false}) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.blueAccent : Colors.white),
      title: Text(title,
          style: TextStyle(
              color: isSelected ? Colors.blueAccent : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      onTap: onTap,
      selected: isSelected,
      selectedTileColor: Colors.blue[50],
    );
  }

  void _navTo(Widget page) {
    Navigator.pop(context); // Ferme le drawer
    Navigator.push(context, MaterialPageRoute(builder: (context) => page))
        .then((_) => _loadStatistics());
  }
}
