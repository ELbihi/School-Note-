import 'package:flutter/material.dart';
import 'package:note_school_ssbm/services/settingsprovider.dart';
import 'package:provider/provider.dart';
import 'package:note_school_ssbm/services/db_service.dart';

class ProfilePage extends StatefulWidget {
  final int studentId;
  final Map<String, dynamic> initialData;

  const ProfilePage({
    Key? key,
    required this.studentId,
    required this.initialData,
  }) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _studentData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _studentData = widget.initialData;
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    setState(() => _isLoading = true);
    try {
      final dbService = DBService.instance;
      final studentInfo = await dbService.getStudentInfo(widget.studentId);
      if (studentInfo != null && mounted) {
        setState(() => _studentData = studentInfo);
      }
    } catch (e) {
      debugPrint("Erreur chargement profil: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(settings.translate('Mon Profil', 'My Profile')),
        backgroundColor: theme.primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildProfileHeader(theme, isDark),
                  const SizedBox(height: 24),
                  _buildSectionTitle(settings.translate("Informations personnelles", "Personal Information"), theme),
                  const SizedBox(height: 12),
                  _buildInfoCard([
                    _buildInfoTile(Icons.email, settings.translate("Email", "Email"), _studentData?['email'], settings, theme),
                    _buildInfoTile(Icons.phone, settings.translate("Téléphone", "Phone"), _studentData?['telephone'], settings, theme),
                    _buildInfoTile(Icons.location_on, settings.translate("Adresse", "Address"), _studentData?['adresse'], settings, theme),
                  ], theme),
                  const SizedBox(height: 24),
                  _buildSectionTitle(settings.translate("Informations académiques", "Academic Information"), theme),
                  const SizedBox(height: 12),
                  _buildInfoCard([
                    _buildInfoTile(Icons.class_, settings.translate("Filière", "Major"), _studentData?['nom_filiere'], settings, theme),
                    _buildInfoTile(Icons.layers, settings.translate("Niveau", "Level"), _studentData?['niveau']?.toString(), settings, theme),
                    _buildInfoTile(Icons.group, settings.translate("Groupe", "Group"), _studentData?['groupe'], settings, theme),
                    _buildInfoTile(Icons.calendar_today, settings.translate("Inscription", "Registration"), _studentData?['date_inscription'], settings, theme),
                  ], theme),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: theme.primaryColor.withOpacity(0.1),
            child: Icon(Icons.person, size: 50, color: theme.primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            "${_studentData?['prenom'] ?? ''} ${_studentData?['nom'] ?? ''}".toUpperCase(),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Chip(
            label: Text(_studentData?['massar']?.toString() ?? 'N/A'),
            backgroundColor: theme.primaryColor.withOpacity(0.1),
            labelStyle: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children, ThemeData theme) {
    List<Widget> dividedChildren = [];
    for (int i = 0; i < children.length; i++) {
      dividedChildren.add(children[i]);
      if (i < children.length - 1) {
        dividedChildren.add(Divider(height: 1, indent: 70, endIndent: 20, color: theme.dividerColor.withOpacity(0.5)));
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(children: dividedChildren),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String? value, SettingsProvider settings, ThemeData theme) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: theme.primaryColor, size: 20),
      ),
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(
        (value == null || value.isEmpty) ? settings.translate("Non renseigné", "Not provided") : value,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}