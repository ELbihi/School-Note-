class Module {
  final int? idModule;
  final String nomModule;
  final double coefficient;
  final int idFiliere;
  final int idSemestre;
  final int idProf;

  Module({
    this.idModule, required this.nomModule, required this.coefficient,
    required this.idFiliere, required this.idSemestre, required this.idProf
  });

  Map<String, dynamic> toMap() => {
    'id_module': idModule, 'nom_module': nomModule, 'coefficient': coefficient,
    'id_filiere': idFiliere, 'id_semestre': idSemestre, 'id_prof': idProf,
  };

  factory Module.fromMap(Map<String, dynamic> map) => Module(
    idModule: map['id_module'], nomModule: map['nom_module'], coefficient: map['coefficient'],
    idFiliere: map['id_filiere'], idSemestre: map['id_semestre'], idProf: map['id_prof'],
  );
}