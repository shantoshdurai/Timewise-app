import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_firebase_test/main.dart';
import 'package:provider/provider.dart';
import 'package:flutter_firebase_test/onboarding_screen.dart';
import 'package:flutter_firebase_test/theme_provider.dart';
import 'package:flutter_firebase_test/notification_settings_page.dart';
import 'package:flutter_firebase_test/widgets/glass_widgets.dart';
import 'package:flutter_firebase_test/app_theme.dart';
import 'package:image_picker/image_picker.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _widgetsEnabled = true;
  bool _retroDisplayEnabled = true;
  bool _showAdvancedSettings = false; // NEW: For collapsible section

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

  Future<void> _pickBackgroundImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        final themeProvider = Provider.of<ThemeProvider>(
          context,
          listen: false,
        );
        await themeProvider.setCustomBackground(pickedFile.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Custom background applied!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<void> _clearBackgroundImage() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    await themeProvider.clearCustomBackground();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Background reset to default')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 45, 16, 0),
          child: GlassCard(
            blur: 25,
            opacity: 0.1,
            borderRadius: BorderRadius.circular(20),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              height: 70,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    'Settings',
                    style: AppTextStyles.interTitle.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontSize: 20,
                      height: 1.0,
                    ),
                  ),
                  Positioned(
                    left: 0,
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: theme.primaryColor,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Layer
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF000000)
                    : const Color(0xFFF2F2F7),
              ),
            ),
          ),
          if (isDark)
            Positioned(
              top: -100,
              right: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryBlue.withOpacity(0.15),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentPurple.withOpacity(0.15),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              children: [
                // 🎯 PRIORITY 1: Academic - Primary Purpose
                _buildSettingsGroup(
                  context,
                  title: 'Academic',
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.school_outlined,
                        color: theme.primaryColor,
                      ),
                      title: Text(
                        'My Class',
                        style: AppTextStyles.interMentor.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Change section or year',
                        style: AppTextStyles.interSmall.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: theme.hintColor,
                      ),
                      onTap: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OnboardingScreen(),
                          ),
                          (route) => false,
                        );
                      },
                    ),
                    const Divider(
                      height: 1,
                      indent: 56,
                      endIndent: 16,
                      color: Colors.white10,
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.notifications_outlined,
                        color: theme.primaryColor,
                      ),
                      title: Text(
                        'Class Alerts',
                        style: AppTextStyles.interMentor.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Manage notification preferences',
                        style: AppTextStyles.interSmall.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: theme.hintColor,
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const NotificationSettingsPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 🎨 PRIORITY 2: Appearance - Basic Visual Settings
                _buildSettingsGroup(
                  context,
                  title: 'Appearance',
                  children: [
                    SwitchListTile(
                      title: Text(
                        'Dark Mode',
                        style: AppTextStyles.interMentor.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Comfortable viewing for nighttime',
                        style: AppTextStyles.interSmall.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                      value: themeProvider.themeMode == ThemeMode.dark,
                      onChanged: (value) {
                        themeProvider.toggleTheme(value);
                      },
                      activeColor: theme.colorScheme.primary,
                      secondary: Icon(
                        Icons.brightness_6_outlined,
                        color: theme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // ⚙️ PRIORITY 3: Advanced - Detailed Customization
                _buildSettingsGroup(
                  context,
                  title: 'Advanced',
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.image_outlined,
                        color: theme.primaryColor,
                      ),
                      title: Text(
                        'Custom Background',
                        style: AppTextStyles.interMentor.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        themeProvider.customBackgroundPath != null
                            ? 'Tap to change image'
                            : 'Personalize your dashboard',
                        style: AppTextStyles.interSmall.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (themeProvider.customBackgroundPath != null)
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                              onPressed: _clearBackgroundImage,
                              tooltip: 'Reset to default',
                            ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: theme.hintColor,
                          ),
                        ],
                      ),
                      onTap: _pickBackgroundImage,
                    ),
                    const Divider(
                      height: 1,
                      indent: 56,
                      endIndent: 16,
                      color: Colors.white10,
                    ),
                    // UI Glass Blur Control
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.blur_on,
                                  color: theme.primaryColor,
                                  size: 24,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'UI Glass Blur',
                                        style: AppTextStyles.interMentor
                                            .copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Text(
                                        'Control the frostiness of cards and UI elements',
                                        style: AppTextStyles.interSmall
                                            .copyWith(color: theme.hintColor),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: theme.primaryColor,
                              inactiveTrackColor: theme.primaryColor
                                  .withOpacity(0.2),
                              thumbColor: Colors.white,
                              overlayColor: theme.primaryColor.withOpacity(0.2),
                              trackHeight: 4.0,
                            ),
                            child: Slider(
                              value: themeProvider.glassBlur,
                              min: 0.0,
                              max: 50.0,
                              divisions: 50,
                              label: themeProvider.glassBlur.round().toString(),
                              onChanged: (value) {
                                themeProvider.setGlassBlur(value);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                      height: 1,
                      indent: 56,
                      endIndent: 16,
                      color: Colors.white10,
                    ),
                    // Background Blur Control
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.blur_circular,
                                  color: theme.primaryColor,
                                  size: 24,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Background Blur',
                                        style: AppTextStyles.interMentor
                                            .copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Text(
                                        'Blur the background image for better readability',
                                        style: AppTextStyles.interSmall
                                            .copyWith(color: theme.hintColor),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: theme.primaryColor,
                              inactiveTrackColor: theme.primaryColor
                                  .withOpacity(0.2),
                              thumbColor: Colors.white,
                              overlayColor: theme.primaryColor.withOpacity(0.2),
                              trackHeight: 4.0,
                            ),
                            child: Slider(
                              value: themeProvider.backgroundBlur,
                              min: 0.0,
                              max: 20.0,
                              divisions: 40,
                              label: themeProvider.backgroundBlur
                                  .toStringAsFixed(1),
                              onChanged: (value) {
                                themeProvider.setBackgroundBlur(value);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                _buildSettingsGroup(
                  context,
                  title: 'Academic',
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.school_outlined,
                        color: theme.primaryColor,
                      ),
                      title: Text(
                        'My Class',
                        style: AppTextStyles.interMentor.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Change section or year',
                        style: AppTextStyles.interSmall.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: theme.hintColor,
                      ),
                      onTap: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OnboardingScreen(),
                          ),
                          (route) => false,
                        );
                      },
                    ),
                    const Divider(
                      height: 1,
                      indent: 56,
                      endIndent: 16,
                      color: Colors.white10,
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.notifications_outlined,
                        color: theme.primaryColor,
                      ),
                      title: Text(
                        'Class Alerts',
                        style: AppTextStyles.interMentor.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Manage notification preferences',
                        style: AppTextStyles.interSmall.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: theme.hintColor,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const NotificationSettingsPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // ADVANCED SETTINGS - Collapsible
                GlassCard(
                  padding: EdgeInsets.zero,
                  opacity: 0.05,
                  borderRadius: BorderRadius.circular(24),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          _showAdvancedSettings
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color: theme.primaryColor,
                        ),
                        title: Text(
                          'Advanced Features',
                          style: AppTextStyles.interMentor.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                        subtitle: Text(
                          _showAdvancedSettings
                              ? 'Hide additional options'
                              : 'Show widgets, retro display, etc.',
                          style: AppTextStyles.interSmall.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _showAdvancedSettings = !_showAdvancedSettings;
                          });
                        },
                      ),
                      if (_showAdvancedSettings) ...[
                        const Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: Colors.white10,
                        ),
                        SwitchListTile(
                          title: Text(
                            'Home Screen Widgets',
                            style: AppTextStyles.interMentor.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'Auto-update timetable widget',
                            style: AppTextStyles.interSmall.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                          value: _widgetsEnabled,
                          onChanged: _setWidgetsEnabled,
                          activeColor: theme.colorScheme.primary,
                          secondary: Icon(
                            Icons.widgets_outlined,
                            color: theme.primaryColor,
                          ),
                        ),
                        const Divider(
                          height: 1,
                          indent: 56,
                          endIndent: 16,
                          color: Colors.white10,
                        ),
                        SwitchListTile(
                          title: Text(
                            '90s Retro Display',
                            style: AppTextStyles.interMentor.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'Pixel-style class tracker',
                            style: AppTextStyles.interSmall.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                          value: _retroDisplayEnabled,
                          onChanged: _setRetroDisplayEnabled,
                          activeColor: theme.colorScheme.primary,
                          secondary: Icon(
                            Icons.computer_outlined,
                            color: theme.primaryColor,
                          ),
                        ),
                        const Divider(
                          height: 1,
                          indent: 56,
                          endIndent: 16,
                          color: Colors.white10,
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.info_outline_rounded,
                            color: theme.primaryColor,
                          ),
                          title: Text(
                            'Widget Setup Guide',
                            style: AppTextStyles.interMentor.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'Learn how to add widgets',
                            style: AppTextStyles.interSmall.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: theme.hintColor,
                          ),
                          onTap: () => _showWidgetInfoDialog(context),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 40),
                // App Info Footer
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Class Now',
                        style: AppTextStyles.interTitle.copyWith(
                          color: theme.hintColor.withOpacity(0.5),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'DSU Timetable Management System',
                        style: AppTextStyles.interSmall.copyWith(
                          color: theme.hintColor.withOpacity(0.4),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
          child: Text(
            title.toUpperCase(),
            style: AppTextStyles.interBadge.copyWith(
              color: theme.primaryColor,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        GlassCard(
          padding: EdgeInsets.zero,
          opacity: 0.05,
          borderRadius: BorderRadius.circular(24),
          child: Column(children: children),
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
              Text('On Android:', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                '1. Long-press on a blank space on your home screen.\n'
                '2. Tap on "Widgets".\n'
                '3. Find "Class Now" in the list.\n'
                '4. Drag the widget to your desired location.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text('On iOS:', style: theme.textTheme.titleMedium),
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
