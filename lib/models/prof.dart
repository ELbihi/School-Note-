class Prof {
  final int? idProf;
  final String nom;
  final String prenom;
  final String email;
  final String password;

  Prof({this.idProf, required this.nom, required this.prenom, required this.email, required this.password});

  Map<String, dynamic> toMap() => {
    'id_prof': idProf, 'nom': nom, 'prenom': prenom, 'email': email, 'password': password,
  };

  factory Prof.fromMap(Map<String, dynamic> map) => Prof(
    idProf: map['id_prof'], nom: map['nom'], prenom: map['prenom'], 
    email: map['email'], password: map['password'],
  );
}