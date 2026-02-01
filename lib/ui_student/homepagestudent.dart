import 'package:flutter/material.dart';
import 'package:note_school_ssbm/models/student.dart';
import 'package:note_school_ssbm/services/settingsprovider.dart';
import 'package:provider/provider.dart';
import 'drawerstudent.dart';
import 'package:note_school_ssbm/services/db_service.dart';

class Homepagestudent extends StatefulWidget {
  final int studentId;
  const Homepagestudent({Key? key, required this.studentId}) : super(key: key);

  @override
  _HomepagestudentState createState() => _HomepagestudentState();
}

class _HomepagestudentState extends State<Homepagestudent> {
  Map<Student, dynamic>? _studentData;
  List<Map<String, dynamic>> _allModules = [];
  List<Map<String, dynamic>> _allNotes = [];
  List<Map<String, dynamic>> _modules = [];
  List<Map<String, dynamic>> _notes = [];
  bool _isLoading = true;
  bool _showAllModules = false;

  String? _selectedSemestre;
  List<String> _semestres = [];

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final dbService = DBService.instance;
      final studentInfo = await dbService.getStudentInfo(widget.studentId);
      final modules = await dbService.getStudentModules(widget.studentId);
      final notes = await dbService.getStudentNotesWithModules(widget.studentId);

      final semestresSet = <String>{};
      for (var module in modules) {
        String semestre = "${module['nom_semestre'] ?? ''} ${module['annee'] ?? ''}";
        if (semestre.trim().isNotEmpty) semestresSet.add(semestre);
      }

      if (mounted) {
        setState(() {
          _studentData = studentInfo?.cast<Student, dynamic>();
          _allModules = modules;
          _allNotes = notes;
          _semestres = semestresSet.toList()..sort();
          _selectedSemestre = null;
          _isLoading = false;
          _applySemestreFilter();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applySemestreFilter() {
    if (_selectedSemestre == null) {
      setState(() {
        _modules = List.from(_allModules);
        _notes = List.from(_allNotes);
      });
    } else {
      setState(() {
        _modules = _allModules
            .where((m) => "${m['nom_semestre']} ${m['annee']}" == _selectedSemestre)
            .toList();
        _notes = _allNotes
            .where((n) => "${n['nom_semestre']} ${n['annee']}" == _selectedSemestre)
            .toList();
      });
    }
  }

  // --- AFFICHAGE DES DÉTAILS DE LA BASE DE DONNÉES ---
  void _showNoteDetails(Map<String, dynamic> note, ThemeData theme, SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                note['nom_module'] ?? '',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.primaryColor),
              ),
              const Divider(height: 30),
              
              _buildDetailRow(settings.translate("Examen", "Exam"), note['note_examen'], theme),
              _buildDetailRow(settings.translate("Contrôle Continu", "CC"), note['note_cc'], theme),
              _buildDetailRow(settings.translate("TP / Projet", "TP / Project"), note['note_tp'], theme),
              
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(settings.translate("Moyenne Finale", "Final Average"),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      "${note['moyenne']?.toStringAsFixed(2) ?? '-'} / 20",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.primaryColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, dynamic value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value != null ? "${value.toString()} / 20" : "-- / 20",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.segment_rounded, color: Colors.white, size: 32),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text("No9taty", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      drawer: StudentDrawer(
          studentData: (_studentData ?? {}),
          studentId: widget.studentId),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStudentData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStudentHeader(theme, settings, isDark),
                    const SizedBox(height: 20),
                    _buildSemestreFilter(theme, settings),
                    _buildModulesSection(theme, settings, isDark),
                    const SizedBox(height: 20),
                    _buildNotesSection(theme, settings, isDark),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStudentHeader(ThemeData theme, SettingsProvider settings, bool isDark) {
    if (_studentData == null) return Container();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${_studentData!['prenom']} ${_studentData!['nom']}".toUpperCase(),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                  ),
                  Text(_studentData!['massar']?.toString() ?? '', style: const TextStyle(color: Colors.grey)),
                ],
              ),
              Icon(Icons.school, color: theme.primaryColor, size: 40),
            ],
          ),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _infoTile(settings.translate("Niveau", "Level"), _studentData!['niveau']?.toString() ?? 'N/A', theme),
              _infoTile(settings.translate("Groupe", "Group"), _studentData!['groupe']?.toString() ?? 'N/A', theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.primaryColor)),
      ],
    );
  }

  Widget _buildSemestreFilter(ThemeData theme, SettingsProvider settings) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        filled: true,
        fillColor: theme.cardColor,
        labelText: settings.translate("Filtrer par semestre", "Filter by semester"),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      value: _selectedSemestre,
      items: [
        DropdownMenuItem(value: null, child: Text(settings.translate("Tous les semestres", "All Semesters"))),
        ..._semestres.map((s) => DropdownMenuItem(value: s, child: Text(s))),
      ],
      onChanged: (val) {
        setState(() {
          _selectedSemestre = val;
          _applySemestreFilter();
        });
      },
    );
  }

  Widget _buildModulesSection(ThemeData theme, SettingsProvider settings, bool isDark) {
    final displayed = _showAllModules ? _modules : _modules.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(settings.translate("Mes Modules", "My Modules"),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        const SizedBox(height: 10),
        ...displayed.map((m) => Card(
              color: theme.cardColor,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(m['nom_module'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${m['prof_prenom'] ?? ''} ${m['prof_nom'] ?? ''}"),
                trailing: Text("Coef: ${m['coefficient']}", style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)),
              ),
            )),
        if (_modules.length > 3)
          Center(
            child: TextButton(
              onPressed: () => setState(() => _showAllModules = !_showAllModules),
              child: Text(_showAllModules ? settings.translate("Voir moins", "Show less") : settings.translate("Voir plus", "Show more")),
            ),
          )
      ],
    );
  }

  Widget _buildNotesSection(ThemeData theme, SettingsProvider settings, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(settings.translate("Mes Notes", "My Grades"),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(10)),
            child: DataTable(
              columnSpacing: 20,
              columns: [
                DataColumn(label: Text(settings.translate("Module", "Module"))),
                DataColumn(label: Text(settings.translate("Moyenne", "Average"))),
                DataColumn(label: Text(settings.translate("Résultat", "Result"))),
              ],
              rows: _notes.map((n) {
                final isValide = n['resultat'] == 'Valide';
                return DataRow(cells: [
                  DataCell(
                    InkWell(
                      onTap: () => _showNoteDetails(n, theme, settings),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            n['nom_module'] ?? '',
                            style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.info_outline, size: 14, color: theme.primaryColor),
                        ],
                      ),
                    ),
                  ),
                  DataCell(Text(n['moyenne']?.toStringAsFixed(2) ?? '-')),
                  DataCell(Text(
                    n['resultat'] ?? '-',
                    style: TextStyle(color: isValide ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                  )),
                ]);
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}