// main.dart - Version Android seulement
import 'package:flutter/material.dart';
import '/screens/home_admin.dart';
import 'services/db_service.dart';

void main() {
  // 🔴 FORCER LA RÉINITIALISATION DE LA BASE
  final dbService = DBService.instance;

  // Option 1: Utiliser forceReset si tu as ajouté la méthode

  // Sur Android, sqflite s'initialise TOUT SEUL
  // PAS besoin de sqfliteFfiInit()
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'School Notes Admin',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const AdminHomePage(),
    );
  }
}
