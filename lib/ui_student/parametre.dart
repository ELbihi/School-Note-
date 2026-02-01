import 'package:flutter/material.dart';
import 'package:note_school_ssbm/services/settingsprovider.dart';
import 'package:provider/provider.dart';
// Importez votre provider ici

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(settings.translate("Paramètres", "Settings"))),
      body: Column(
        children: [
          // Changer le Thème
          SwitchListTile(
            title: Text(settings.translate("Mode Sombre", "Dark Mode")),
            value: settings.themeMode == ThemeMode.dark,
            onChanged: (val) => settings.toggleTheme(val),
          ),
          
          // Changer la Langue
          ListTile(
            title: Text(settings.translate("Langue", "Language")),
            trailing: DropdownButton<String>(
              value: settings.languageCode,
              items: const [
                DropdownMenuItem(value: 'fr', child: Text("Français 🇫🇷")),
                DropdownMenuItem(value: 'en', child: Text("English 🇬🇧")),
              ],
              onChanged: (val) => settings.setLanguage(val!),
            ),
          ),
        ],
      ),
    );
  }
}