import 'package:flutter/material.dart';
import '../screens_prof/drawer_widget.dart';
import '../services/db_service.dart';

class TeacherDashboard extends StatefulWidget {
  final Map<String, dynamic> profData;

  const TeacherDashboard({super.key, required this.profData});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final Color royalBlue = const Color(0xFF0056D2);
  final Color deepNavy = const Color(0xFF002B5C);
  
  // Variables pour les statistiques
  int _moduleCount = 0;
  int _studentCount = 0;
  int _filiereCount = 0;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }
  
  Future<void> _loadStatistics() async {
    if (widget.profData == null || widget.profData['id_prof'] == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
    try {
      final stats = await DBService.instance.getProfStatistics(widget.profData['id_prof']);
      
      setState(() {
        _moduleCount = stats['module_count'] ?? 0;
        _filiereCount = stats['filiere_count'] ?? 0;
        _studentCount = stats['student_count'] ?? 0;
        _isLoading = false;
      });
      
    } catch (e) {
      print("Erreur lors du chargement des statistiques: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String prenom = widget.profData['prenom'] ?? "Professeur";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: royalBlue,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.segment_rounded, color: Colors.white, size: 32),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text("School Notes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      
      drawer: AppDrawer(profData: widget.profData), 

      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0056D2)))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête de bienvenue
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: royalBlue,
                              child: Icon(Icons.person, size: 35, color: Colors.white),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Bienvenue, $prenom",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: deepNavy,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.profData['email'] ?? "",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Titre des statistiques
                    Text(
                      "Statistiques Générales",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: deepNavy,
                      ),
                    ),
                    
                    const SizedBox(height: 5),
                    Text(
                      "Vue d'ensemble de vos activités d'enseignement",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Cartes de statistiques (3 cartes seulement)
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.7,
                      children: [
                        _buildStatCard(
                          value: _moduleCount.toString(),
                          label: "Modules",
                          icon: Icons.book,
                          color: Colors.blue,
                        ),
                        _buildStatCard(
                          value: _studentCount.toString(),
                          label: "Étudiants",
                          icon: Icons.school,
                          color: Colors.green,
                        ),
                        _buildStatCard(
                          value: _filiereCount.toString(),
                          label: "Filières",
                          icon: Icons.architecture,
                          color: Colors.orange,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Bouton de rafraîchissement
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _loadStatistics,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: royalBlue,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        label: const Text(
                          "Actualiser les statistiques",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      child: Container(
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(
          minHeight: 120,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}