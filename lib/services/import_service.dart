import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'db_service.dart';

class ImportService {
  static Future<String> pickAndImport(String tableName) async {
    try {
      // 1. Sélectionner le fichier
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        
        // 2. Décoder le JSON
        List<dynamic> data = jsonDecode(content);

        // 3. Envoyer à la base de données
        await DBService.instance.importJsonData(tableName, data);
        
        return "Importation réussie dans $tableName";
      }
      return "Aucun fichier sélectionné";
    } catch (e) {
      return "Erreur lors de l'import : $e";
    }
  }
}