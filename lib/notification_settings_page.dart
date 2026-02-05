import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_firebase_test/notification_service.dart';
import 'package:flutter_firebase_test/widgets/glass_widgets.dart';
import 'package:flutter_firebase_test/app_theme.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _isLoading = true;
  bool _notificationsEnabled = true;
  bool _allSubjects = true;
  List<String> _subjects = [];
  List<String> _selectedSubjects = [];
  int _leadTimeMinutes = 15; // Default 15 minutes before class

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('notifications_enabled') ?? true;
    final all = prefs.getBool('notifications_all_subjects') ?? true;
    final selected =
        prefs.getStringList('notification_selected_subjects') ?? [];
    final leadTime = prefs.getInt('notifications_lead_time') ?? 15;

    final uniqueSubjects = await NotificationService.getUniqueSubjects();

    if (mounted) {
      setState(() {
        _notificationsEnabled = enabled;
        _allSubjects = all;
        _selectedSubjects = selected;
        _subjects = uniqueSubjects;
        _leadTimeMinutes = leadTime;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('notifications_all_subjects', _allSubjects);
    await prefs.setStringList(
      'notification_selected_subjects',
      _selectedSubjects,
    );
    await prefs.setInt('notifications_lead_time', _leadTimeMinutes);

    await NotificationService.scheduleTimetableNotifications();
  }

  void _toggleSubject(String subject, bool? isSelected) {
    setState(() {
      if (isSelected == true) {
        if (!_selectedSubjects.contains(subject)) {
          _selectedSubjects.add(subject);
        }
      } else {
        _selectedSubjects.remove(subject);
      }
    });
    _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Notification Preferences')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildExperimentCard(theme),
                const SizedBox(height: 24),

                SwitchListTile(
                  title: Text(
                    'Enable Notifications',
                    style: theme.textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    'Turn on/off all class reminders',
                    style: theme.textTheme.bodySmall,
                  ),
                  value: _notificationsEnabled,
                  onChanged: (val) {
                    setState(() => _notificationsEnabled = val);
                    _saveSettings();
                  },
                  secondary: Icon(
                    Icons.notifications_active_outlined,
                    color: theme.primaryColor,
                  ),
                ),

                const Divider(height: 32),

                if (_notificationsEnabled) ...[
                  // Premium Glassmorphism Notification Timing Card
                  GlassCard(
                    blur: 15,
                    opacity: 0.08,
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with animated gradient icon
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.primaryBlue,
                                    AppTheme.accentPurple,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryBlue.withOpacity(
                                      0.4,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.schedule_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Notification Timing',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Remind me before class starts',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.hintColor.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Premium Slider
                        Row(
                          children: [
                            Text(
                              '5',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.hintColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderThemeData(
                                  activeTrackColor: AppTheme.primaryBlue,
                                  inactiveTrackColor: theme.hintColor
                                      .withOpacity(0.2),
                                  thumbColor: Colors.white,
                                  overlayColor: AppTheme.primaryBlue
                                      .withOpacity(0.2),
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 12,
                                    elevation: 4,
                                  ),
                                  trackHeight: 4,
                                ),
                                child: Slider(
                                  value: _leadTimeMinutes.toDouble(),
                                  min: 5,
                                  max: 30,
                                  divisions: 3,
                                  onChanged: (value) {
                                    setState(() {
                                      _leadTimeMinutes = value.toInt();
                                    });
                                  },
                                  onChangeEnd: (value) {
                                    _saveSettings();
                                  },
                                ),
                              ),
                            ),
                            Text(
                              '30',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.hintColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Glowing Badge
                        Center(
                          child: GlowingCard(
                            glowColor: AppTheme.primaryBlue,
                            glowRadius: 8,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 18,
                                  color: AppTheme.primaryBlue,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$_leadTimeMinutes minutes before',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: AppTheme.primaryBlue,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  SwitchListTile(
                    title: Text(
                      'All Classes',
                      style: theme.textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      'Get notified for every class in your schedule',
                      style: theme.textTheme.bodySmall,
                    ),
                    value: _allSubjects,
                    onChanged: (val) {
                      setState(() => _allSubjects = val);
                      _saveSettings();
                    },
                    secondary: Icon(
                      Icons.select_all,
                      color: theme.primaryColor,
                    ),
                  ),

                  if (!_allSubjects) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Select Specific Classes',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_subjects.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No classes found in schedule.'),
                      ),
                    ..._subjects.map((subject) {
                      final isSelected = _selectedSubjects.contains(subject);
                      return CheckboxListTile(
                        title: Text(subject),
                        value: isSelected,
                        onChanged: (val) => _toggleSubject(subject, val),
                        activeColor: theme.colorScheme.primary,
                        checkboxShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ],
            ),
    );
  }

  Widget _buildExperimentCard(ThemeData theme) {
    return Card(
      elevation: 4,
      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.science_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Test Notifications',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Send a test alert to check if notifications are working.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  await NotificationService.showTestNotification();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Test notification sent! Check your status bar.',
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.send_rounded),
                label: const Text('Send Test Notification'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
