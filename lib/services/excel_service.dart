import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExcelService {
  // Correction : On définit une méthode qui accepte les données
  static Future<void> exportToExcel(List<Map<String, dynamic>> data) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Bulletin'];

    // Entêtes avec CellValue pour éviter les erreurs de compilation
    sheet.appendRow([
      TextCellValue('CNE'),
      TextCellValue('Nom'),
      TextCellValue('Prénom'),
      TextCellValue('Module'),
      TextCellValue('Note'),
    ]);

    for (var row in data) {
      sheet.appendRow([
        TextCellValue(row['cne']?.toString() ?? ''),
        TextCellValue(row['nom']?.toString() ?? ''),
        TextCellValue(row['prenom']?.toString() ?? ''),
        TextCellValue(row['nom_module']?.toString() ?? ''),
        TextCellValue(row['note']?.toString() ?? 'N/A'),
      ]);
    }

    final directory = await getTemporaryDirectory();
    final path =
        "${directory.path}/Bulletin_Notes_${DateTime.now().millisecondsSinceEpoch}.xlsx";
    final file = File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(excel.save()!);

    await Share.shareXFiles([XFile(path)], text: 'Export des notes');
  }
}
