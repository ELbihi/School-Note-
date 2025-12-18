class Module {
  final int? id;
  final String name;
  final int coefficient;
  final String semester;
  final int profId;

  Module({
    this.id,
    required this.name,
    required this.coefficient,
    required this.semester,
    required this.profId,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'coefficient': coefficient,
    'semester': semester,
    'profId': profId,
  };

  factory Module.fromMap(Map<String, dynamic> map) => Module(
    id: map['id'],
    name: map['name'],
    coefficient: map['coefficient'],
    semester: map['semester'],
    profId: map['profId'],
  );
}
