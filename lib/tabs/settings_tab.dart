// import required libraries
import 'package:flutter/material.dart';

// define the StatefulWidget class
class SettingsTab extends StatefulWidget {
  // constructor
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

// define the State class
class _SettingsTabState extends State<SettingsTab> {
  // manage state variables here

  // build the UI for this tab content
  @override
  Widget build(BuildContext context) {
    ThemeMode themeMode = ThemeMode.dark;
    bool _isDarkTheme = themeMode == ThemeMode.dark;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          ListTile(
            title: Text('Dark Mode'),
            trailing: Switch(
              value: _isDarkTheme,
              onChanged: (value) {
                setState(() {
                  _isDarkTheme = value;
                  themeMode = value ? ThemeMode.dark : ThemeMode.light;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
