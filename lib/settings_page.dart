import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_firebase_test/onboarding_screen.dart';
import 'package:flutter_firebase_test/theme_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Enable/disable dark mode'),
            value: themeProvider.themeMode == ThemeMode.dark,
            onChanged: (value) {
              themeProvider.toggleTheme(value);
            },
            secondary: const Icon(Icons.brightness_6),
          ),
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text('Change Class'),
            subtitle: const Text('Select a different department, year, or section'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OnboardingScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.widgets),
            title: const Text('Home Screen Widgets'),
            subtitle: const Text('Learn how to add widgets'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Add Home Screen Widgets'),
                  content: const SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'On Android:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '1. Long-press on a blank space on your home screen.\n'
                          '2. Tap on "Widgets".\n'
                          '3. Find "TimeWise" in the list.\n'
                          '4. Drag the widget to your desired location.',
                        ),
                        SizedBox(height: 16),
                        Text(
                          'On iOS:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '1. Long-press on a blank space on your home screen until the apps jiggle.\n'
                          '2. Tap the "+" button in the top-left corner.\n'
                          '3. Search for "TimeWise".\n'
                          '4. Choose a widget size and tap "Add Widget".',
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
