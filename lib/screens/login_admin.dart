import 'package:flutter/material.dart';
import '../services/db_service.dart';
import '../services/admin_auth_config.dart';
// Importez vos pages réelles ici
import 'home_admin.dart';
// import 'teacher_dashboard.dart'; // Assurez-vous que ce fichier existe

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final Color royalBlue = const Color(0xFF0056D2);

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;

  void _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar("Veuillez remplir tous les champs", Colors.orange);
      return;
    }

    // 1. VÉRIFICATION ADMIN (Locale)
    if (AdminAuthConfig.isAdmin(email, password)) {
      if (!mounted) return;
      _showSnackBar("Bienvenue Administrateur !", Colors.blueAccent);

      // Correction Navigation : Si vous n'avez pas de routes nommées, utilisez MaterialPageRoute
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminHomePage()),
      );
      return;
    }

    // 2. VÉRIFICATION PROFESSEUR (Base de données)
    try {
      var prof = await DBService.instance.checkLogin(email, password);

      if (prof != null) {
        if (!mounted) return;
        _showSnackBar(
            "Bienvenue ${prof['prenom']} ${prof['nom']} !", Colors.green);

        // Décommentez ceci quand votre TeacherDashboard sera prêt
        /*
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TeacherDashboard(profData: prof), 
          ),
        );
        */
      } else {
        if (!mounted) return;
        _showSnackBar("Identifiants incorrects", Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("Erreur de base de données : $e", Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating, // Optionnel : plus moderne
      ),
    );
  }

  @override
  void dispose() {
    // IMPORTANT : Toujours libérer les contrôleurs pour éviter les fuites de mémoire
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo section
                _buildLogo(),
                const SizedBox(height: 40),

                // Champs de saisie
                _buildTextField(
                  controller: _emailController,
                  label: "Email / Username",
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 20),
                _buildPasswordField(),

                const SizedBox(height: 30),

                // Bouton
                SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: royalBlue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      "Se connecter",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                Text(
                  "Admin: admin@school.ma / admin123\nProf: prof1@school.ma / pass123",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widgets extraits pour rendre le code plus propre
  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          height: 100,
          width: 100,
          decoration: BoxDecoration(
              color: royalBlue.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(Icons.school, size: 50, color: royalBlue),
        ),
        const SizedBox(height: 20),
        const Text("School Notes",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String label,
      required IconData icon}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: royalBlue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: "Mot de passe",
        prefixIcon: Icon(Icons.lock_outline, color: royalBlue),
        suffixIcon: IconButton(
          icon: Icon(
              _isPasswordVisible ? Icons.visibility : Icons.visibility_off),
          onPressed: () =>
              setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }
}
