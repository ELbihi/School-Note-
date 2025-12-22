class Student {
  final int? idStudent;
  final String massar;
  final String nom;
  final String prenom;
  final String email;
  final String password;
  final String groupe;
  final int niveau;
  final int idFiliere;

  Student({
    this.idStudent, required this.massar, required this.nom, 
    required this.prenom, required this.email, required this.password,
    required this.groupe, required this.niveau, required this.idFiliere
  });

  Map<String, dynamic> toMap() => {
    'id_student': idStudent,
    'massar': massar,
    'nom': nom,
    'prenom': prenom,
    'email': email,
    'password': password,
    'groupe': groupe,
    'niveau': niveau,
    'id_filiere': idFiliere,
  };

  factory Student.fromMap(Map<String, dynamic> map) => Student(
    idStudent: map['id_student'],
    massar: map['massar'],
    nom: map['nom'],
    prenom: map['prenom'],
    email: map['email'],
    password: map['password'],
    groupe: map['groupe'],
    niveau: map['niveau'],
    idFiliere: map['id_filiere'],
  );
}