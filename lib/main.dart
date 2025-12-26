import 'package:flutter/material.dart';
import 'screens/home_admin.dart';
import 'screens/login_admin.dart'; // Vérifiez bien ce nom de fichier

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'School Notes Admin',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,

      // CORRECTION 1: Retirez l'espace après /login
      initialRoute: '/login',

      routes: {
        // La route par défaut '/' peut rester vers AdminHomePage
        '/home_admin': (context) => const AdminHomePage(),

        // CORRECTION 2: Assurez-vous que la clé correspond exactement à initialRoute
        '/login': (context) => const LoginPage(),
      },
    );
  }
}
