import 'package:flutter/material.dart';
import 'package:note_school_ssbm/services/settingsprovider.dart';
import 'package:provider/provider.dart'; // Import indispensable
import 'package:note_school_ssbm/screens/home_admin.dart';
import 'package:note_school_ssbm/ui_student/homepagestudent.dart';
import '/screens_prof/home_prof.dart';
import 'package:note_school_ssbm/services/db_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  // Méthode de login mise à jour avec traductions
  Future<void> _login(SettingsProvider settings) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar(
        settings.translate("Veuillez remplir tous les champs", "Please fill all fields"), 
        Colors.orange
      );
      return;
    }

    final user = await DBService.instance.loginUser(email, password);

    if (user == null) {
      _showSnackBar(
        settings.translate("Email ou mot de passe incorrect", "Invalid email or password"), 
        Colors.red
      );
      return;
    }

    if (!mounted) return;

    final role = user['role'];
    String welcome = settings.translate("Bienvenue ", "Welcome ");
    
    // Logique de message de bienvenue traduite
    if (role == 'ADMIN') welcome += "Admin";
    else welcome += "${user['prenom']} ${user['nom']}";

    _showSnackBar(welcome, Colors.green);

    // Navigation (inchangée)
    switch (role) {
      case 'ADMIN':
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminHomePage()));
        break;
      case 'PROF':
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TeacherDashboard(profData: user)));
        break;
      case 'STUDENT':
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Homepagestudent(studentId: user['id_student'])));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Appel du Provider
    final settings = Provider.of<SettingsProvider>(context);
    // 2. Utilisation des couleurs du thème
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      // S'adapte automatiquement au mode sombre
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildLogo(theme),
                const SizedBox(height: 40),
                _buildTextField(
                  controller: _emailController,
                  label: settings.translate("Email", "Email"),
                  icon: Icons.email_outlined,
                  theme: theme,
                ),
                const SizedBox(height: 20),
                _buildPasswordField(settings, theme),
                const SizedBox(height: 30),
                SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () => _login(settings),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      settings.translate("Connexion", "Login"),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  settings.translate(
                    "Utilisez vos identifiants uniques pour vous connecter",
                    "Use your unique credentials to log in"
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(ThemeData theme) {
    return Column(
      children: [
        SizedBox(height: 150, width: 150, child: Image.asset('assets/y.png')),
        Text(
          "NO9TATY",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: theme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ThemeData theme,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: theme.primaryColor),
        filled: true,
        fillColor: theme.cardColor, // Utilise la couleur de carte du thème
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildPasswordField(SettingsProvider settings, ThemeData theme) {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        labelText: settings.translate("Mot de passe", "Password"),
        prefixIcon: Icon(Icons.lock_outline, color: theme.primaryColor),
        suffixIcon: IconButton(
          icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),
        filled: true,
        fillColor: theme.cardColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }
}