class Note {
  final int? id;
  final int studentId;
  final int moduleId;
  final double controle;
  final double tp;
  final double examen;
  final double? project;
  final double average;
  final String result;

  Note({
    this.id,
    required this.studentId,
    required this.moduleId,
    required this.controle,
    required this.tp,
    required this.examen,
    this.project,
    required this.average,
    required this.result,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'studentId': studentId,
    'moduleId': moduleId,
    'controle': controle,
    'tp': tp,
    'examen': examen,
    'project': project,
    'average': average,
    'result': result,
  };

  factory Note.fromMap(Map<String, dynamic> map) => Note(
    id: map['id'],
    studentId: map['studentId'],
    moduleId: map['moduleId'],
    controle: map['controle'],
    tp: map['tp'],
    examen: map['examen'],
    project: map['project'],
    average: map['average'],
    result: map['result'],
  );
}
