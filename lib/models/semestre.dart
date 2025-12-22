class Semestre {
  final int? idSemestre;
  final String nomSemestre;
  final String annee;

  Semestre({this.idSemestre, required this.nomSemestre, required this.annee});

  Map<String, dynamic> toMap() => {
    'id_semestre': idSemestre, 'nom_semestre': nomSemestre, 'annee': annee,
  };

  factory Semestre.fromMap(Map<String, dynamic> map) => Semestre(
    idSemestre: map['id_semestre'], nomSemestre: map['nom_semestre'], annee: map['annee'],
  );
}