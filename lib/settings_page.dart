import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_firebase_test/main.dart';
import 'package:provider/provider.dart';
import 'package:flutter_firebase_test/onboarding_screen.dart';
import 'package:flutter_firebase_test/theme_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _widgetsEnabled = true;
  bool _retroDisplayEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _widgetsEnabled = prefs.getBool('widgets_enabled') ?? true;
      _retroDisplayEnabled = prefs.getBool('retro_display_enabled') ?? true;
    });
  }

  Future<void> _setRetroDisplayEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('retro_display_enabled', value);
    if (!mounted) return;
    setState(() {
      _retroDisplayEnabled = value;
    });
    // Update the global notifier to trigger immediate UI update
    retroDisplayEnabledNotifier.value = value;
  }

  Future<void> _setWidgetsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('widgets_enabled', value);
    if (!mounted) return;
    setState(() {
      _widgetsEnabled = value;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'Widgets enabled' : 'Widgets disabled'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSettingsGroup(
            context,
            title: 'Display',
            children: [
              SwitchListTile(
                title: Text('Dark Mode', style: theme.textTheme.titleMedium),
                subtitle: Text('A comfortable view for nighttime', style: theme.textTheme.bodySmall),
                value: themeProvider.themeMode == ThemeMode.dark,
                onChanged: (value) {
                  themeProvider.toggleTheme(value);
                },
                activeColor: theme.colorScheme.secondary,
                secondary: Icon(Icons.brightness_6_outlined, color: theme.primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingsGroup(
            context,
            title: 'Account',
            children: [
              ListTile(
                leading: Icon(Icons.school_outlined, color: theme.primaryColor),
                title: Text('Change My Class', style: theme.textTheme.titleMedium),
                subtitle: Text('Select a different section or year', style: theme.textTheme.bodySmall),
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const OnboardingScreen()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingsGroup(
            context,
            title: 'Extras',
            children: [
              SwitchListTile(
                title: Text('90s Retro Display', style: theme.textTheme.titleMedium),
                subtitle: Text('Show pixel-style class tracker display', style: theme.textTheme.bodySmall),
                value: _retroDisplayEnabled,
                onChanged: _setRetroDisplayEnabled,
                activeColor: theme.colorScheme.secondary,
                secondary: Icon(Icons.computer_outlined, color: theme.primaryColor),
              ),
              SwitchListTile(
                title: Text('Widgets Auto-Update', style: theme.textTheme.titleMedium),
                subtitle: Text('Keep home screen widgets updated automatically', style: theme.textTheme.bodySmall),
                value: _widgetsEnabled,
                onChanged: _setWidgetsEnabled,
                activeColor: theme.colorScheme.secondary,
                secondary: Icon(Icons.autorenew_rounded, color: theme.primaryColor),
              ),
              ListTile(
                leading: Icon(Icons.widgets_outlined, color: theme.primaryColor),
                title: Text('Home Screen Widgets', style: theme.textTheme.titleMedium),
                subtitle: Text('Learn how to add widgets', style: theme.textTheme.bodySmall),
                onTap: () => _showWidgetInfoDialog(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(BuildContext context, {required String title, required List<Widget> children}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.labelLarge?.copyWith(color: theme.primaryColor, fontWeight: FontWeight.bold),
          ),
        ),
        Card(
          elevation: theme.cardTheme.elevation ?? 1,
          color: theme.cardColor,
          shape: theme.cardTheme.shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  void _showWidgetInfoDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Home Screen Widgets'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'On Android:',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '1. Long-press on a blank space on your home screen.\n'
                '2. Tap on "Widgets".\n'
                '3. Find "Class Now" in the list.\n'
                '4. Drag the widget to your desired location.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'On iOS:',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '1. Long-press on a blank space on your home screen until the apps jiggle.\n'
                '2. Tap the "+" button in the top-left corner.\n'
                '3. Search for "Class Now".\n'
                '4. Choose a widget size and tap "Add Widget".',
                style: theme.textTheme.bodyMedium,
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
  }
}
