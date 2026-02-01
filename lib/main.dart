import 'package:flutter/material.dart';
import 'package:note_school_ssbm/services/settingsprovider.dart';
import 'package:provider/provider.dart'; // Importez provider
import 'screens/home_admin.dart';
import 'services/login.dart';

// ... tes imports ...


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => SettingsProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // On récupère les réglages actuels
    final settings = Provider.of<SettingsProvider>(context);

    return MaterialApp(
      title: 'School Notes Admin',
      debugShowCheckedModeBanner: false,
      
      // GESTION DU THÈME SUR TOUTE L'APP
      themeMode: settings.themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
      ),

      initialRoute: '/login',
      routes: {
        '/home_admin': (context) => const AdminHomePage(),
        '/login': (context) => const LoginPage(),
      },
    );
  }
}