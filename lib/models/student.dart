class Student {
  final int? id;
  final String massar;
  final String firstName;
  final String lastName;
  final String filiere;
  final String groupName;
  final String niveau;
  final String? email;

  Student({
    this.id,
    required this.massar,
    required this.firstName,
    required this.lastName,
    required this.filiere,
    required this.groupName,
    required this.niveau,
    required this.email,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'massar': massar,
    'firstName': firstName,
    'lastName': lastName,
    'filiere': filiere,
    'groupName': groupName,
    'niveau': niveau,
    'email': email,
  };

  factory Student.fromMap(Map<String, dynamic> map) => Student(
    id: map['id'],
    massar: map['massar'],
    firstName: map['firstName'],
    lastName: map['lastName'],
    filiere: map['filiere'],
    groupName: map['groupName'],
    niveau: map['niveau'],
    email: map['email'],
  );
}
