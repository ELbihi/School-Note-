class Filiere {
  final int? idFiliere;
  final String nomFiliere;
  final String description;

  Filiere({this.idFiliere, required this.nomFiliere, required this.description});

  Map<String, dynamic> toMap() => {
    'id_filiere': idFiliere,
    'nom_filiere': nomFiliere,
    'description': description,
  };

  factory Filiere.fromMap(Map<String, dynamic> map) => Filiere(
    idFiliere: map['id_filiere'],
    nomFiliere: map['nom_filiere'],
    description: map['description'],
  );
}