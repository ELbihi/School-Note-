class Note {
  final int? idNote;
  final double controle;
  final double tp;
  final double examen;
  final double projet;
  final double moyenne;
  final String resultat;
  final int idStudent;
  final int idModule;

  Note({
    this.idNote, required this.controle, required this.tp, required this.examen,
    required this.projet, required this.moyenne, required this.resultat,
    required this.idStudent, required this.idModule
  });

  Map<String, dynamic> toMap() => {
    'id_note': idNote, 'controle': controle, 'tp': tp, 'examen': examen,
    'projet': projet, 'moyenne': moyenne, 'resultat': resultat,
    'id_student': idStudent, 'id_module': idModule,
  };

  factory Note.fromMap(Map<String, dynamic> map) => Note(
    idNote: map['id_note'], controle: map['controle'], tp: map['tp'],
    examen: map['examen'], projet: map['projet'], moyenne: map['moyenne'],
    resultat: map['resultat'], idStudent: map['id_student'], idModule: map['id_module'],
  );
}