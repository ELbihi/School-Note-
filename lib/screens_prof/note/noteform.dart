import 'package:flutter/material.dart';
import '/services/db_service.dart';

class NoteFormPage extends StatefulWidget {
  final Map<String, dynamic> studentData;
  final int moduleId; // <--- C'est ça qui manquait dans ton fichier !

  const NoteFormPage({super.key, required this.studentData, required this.moduleId});

  @override
  State<NoteFormPage> createState() => _NoteFormPageState();
}

class _NoteFormPageState extends State<NoteFormPage> {
  final Color royalBlue = const Color(0xFF0056D2);
  late TextEditingController ctl, tp, prj, exam;

  @override
  void initState() {
    super.initState();
    ctl = TextEditingController(text: widget.studentData['controle']?.toString() ?? "");
    tp = TextEditingController(text: widget.studentData['tp']?.toString() ?? "");
    prj = TextEditingController(text: widget.studentData['projet']?.toString() ?? "");
    exam = TextEditingController(text: widget.studentData['examen']?.toString() ?? "");
  }

  Future<void> _save() async {
    await DBService.instance.saveGrade(
      widget.studentData['id_student'], 
      widget.moduleId,
      double.tryParse(ctl.text), 
      double.tryParse(tp.text),
      double.tryParse(prj.text), 
      double.tryParse(exam.text)
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enregistré !")));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Modifier Note"), backgroundColor: royalBlue, iconTheme: const IconThemeData(color: Colors.white), titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20)),
      
      body: ListView(
        padding: const EdgeInsets.all(24), 
        children: [
          Text("${widget.studentData['nom']} ${widget.studentData['prenom']}", style: TextStyle(fontSize: 20, color: royalBlue, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _field("Contrôle", ctl), 
          _field("TP", tp), 
          _field("Projet", prj), 
          _field("Examen", exam),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _save, 
            style: ElevatedButton.styleFrom(backgroundColor: royalBlue, padding: const EdgeInsets.all(15)), 
            child: const Text("ENREGISTRER", style: TextStyle(color: Colors.white))
          )
        ],
      ),
    );
  }
  Widget _field(String l, TextEditingController c) => Padding(padding: const EdgeInsets.only(bottom: 15), child: TextFormField(controller: c, decoration: InputDecoration(labelText: l, border: const OutlineInputBorder()), keyboardType: TextInputType.number));
}