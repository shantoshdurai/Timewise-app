import 'dart:ui'; // Add for Blur
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:home_widget/home_widget.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'dart:async';
import 'dart:convert';

import 'package:flutter_firebase_test/onboarding_screen.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_firebase_test/widget_service.dart';
import 'package:flutter_firebase_test/settings_page.dart';
import 'package:flutter_firebase_test/login_screen.dart';
import 'package:flutter_firebase_test/theme_provider.dart';
import 'package:flutter_firebase_test/app_theme.dart';
import 'package:flutter_firebase_test/providers/user_selection_provider.dart';
import 'package:flutter_firebase_test/widgets/skeleton_loader.dart';
import 'package:flutter_firebase_test/retro_digital_display.dart';
import 'package:flutter_firebase_test/splash_screen.dart';
import 'package:flutter_firebase_test/subject_utils.dart';
import 'package:flutter_firebase_test/widgets/glass_widgets.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  // For Workmanager
  Workmanager().executeTask((task, inputData) async {
    print("Native called background task: $task");
    try {
      await Firebase.initializeApp();
      await WidgetService.updateWidget();
    } catch (e) {
      print("Background task failed: $e");
    }
    return Future.value(true);
  });
}

// Separate callback for home_widget background clicks
@pragma('vm:entry-point')
Future<void> homeWidgetBackgroundCallback(Uri? uri) async {
  print("HomeWidget background click: $uri");
  if (uri?.host == 'update' || uri?.path == '/update') {
    try {
      await Firebase.initializeApp();
      await WidgetService.updateWidget();
    } catch (e) {
      print("HomeWidget background update failed: $e");
    }
  }
}

// Global ValueNotifier for retro display setting
final retroDisplayEnabledNotifier = ValueNotifier<bool>(false);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  HomeWidget.registerBackgroundCallback(homeWidgetBackgroundCallback);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => UserSelectionProvider()),
      ],
      child: const TimetableApp(),
    ),
  );
}

class TimetableApp extends StatelessWidget {
  const TimetableApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Class Now',
      themeMode: themeProvider.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}

class AppLauncher extends StatelessWidget {
  const AppLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserSelectionProvider>(
      builder: (context, userSelection, child) {
        // The provider loads the selection in its constructor.
        // We can check if the selection is loaded and valid.
        if (userSelection.hasSelection) {
          return const DashboardPage();
        } else {
          // If no selection is found after loading, go to onboarding.
          return const OnboardingScreen();
        }
      },
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with WidgetsBindingObserver {
  String selectedDay = DateFormat('EEEE').format(DateTime.now());
  bool isAdmin = false;
  bool notificationsEnabled = true;
  bool widgetsEnabled = true;
  bool retroDisplayEnabled = true;
  bool isOnline = true;
  Timer? _connectivityTimer;
  Timer? _widgetUpdateTimer;
  Timer? _notificationTimer;
  Timer? _duringClassTimer;
  Timer? _classScheduleTimer;

  String? _scheduleCacheKey;
  List<Map<String, dynamic>> _cachedSchedule = [];
  DateTime? _cachedScheduleUpdatedAt;

  // Performance tracking variables
  int _updateCount = 0;
  DateTime? _lastUpdate;
  DateTime? _lastSuccessfulUpdate;
  int _errorCount = 0;
  final List<String> _updateHistory = [];

  List<_ScheduleItem> _itemsFromMaps(List<Map<String, dynamic>> all) {
    return all
        .map((e) => _ScheduleItem(data: Map<String, dynamic>.from(e)))
        .toList();
  }

  final List<String> weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print('🚀 DashboardPage initState - Setting up timers and observers');

    _loadSettings().then((_) {
      if (!mounted) return;
      if (widgetsEnabled) {
        _updateHomeScreenWidget();
      }
    });
    NotificationService.scheduleTimetableNotifications();

    // Trigger during-class notification immediately if needed
    NotificationService.triggerDuringClassNotification();
    _startConnectivityMonitoring();
    _startWidgetUpdateTimer();
    _scheduleNextClassUpdate();

    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (!mounted) return;
      if (user == null) {
        setState(() {
          isAdmin = false;
        });
      } else {
        _checkAdminStatus(user);
      }
    });
  }

  @override
  void dispose() {
    print('🗑️ DashboardPage dispose - Canceling all timers');
    WidgetsBinding.instance.removeObserver(this);

    // Cancel all timers to prevent memory leaks
    _connectivityTimer?.cancel();
    _widgetUpdateTimer?.cancel();
    _notificationTimer?.cancel();
    _duringClassTimer?.cancel();
    _classScheduleTimer?.cancel();

    super.dispose();
  }

  void _startConnectivityMonitoring() {
    print('🌐 Starting connectivity monitoring');
    _connectivityTimer?.cancel();
    _connectivityTimer = Timer.periodic(const Duration(minutes: 5), (
      timer,
    ) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      await _checkConnectivity();
    });

    // Initial check
    _checkConnectivity();
  }

  void _scheduleNextClassUpdate() {
    print('📅 [Schedule] Scheduling next class update...');

    _classScheduleTimer?.cancel();

    final now = DateTime.now();
    DateTime? nextUpdateTime;
    String? nextUpdateReason;

    // Find the next class start or end time
    for (var classData in _cachedSchedule) {
      try {
        final dayOfWeek =
            (classData['day'] ?? classData['dayOfWeek']) as String?;
        final currentDay = DateFormat('EEEE').format(now);

        // Only schedule for today's classes
        if (dayOfWeek != currentDay) continue;

        final startTime = DateFormat('HH:mm').parse(classData['startTime']);
        final endTime = DateFormat('HH:mm').parse(classData['endTime']);

        final startDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          startTime.hour,
          startTime.minute,
        );

        final endDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          endTime.hour,
          endTime.minute,
        );

        // Check if start time is in the future and closer than current nextUpdateTime
        if (startDateTime.isAfter(now)) {
          if (nextUpdateTime == null ||
              startDateTime.isBefore(nextUpdateTime)) {
            nextUpdateTime = startDateTime;
            nextUpdateReason = 'Class Start: ${classData['subject']}';
          }
        }

        // Check if end time is in the future and closer than current nextUpdateTime
        if (endDateTime.isAfter(now)) {
          if (nextUpdateTime == null || endDateTime.isBefore(nextUpdateTime)) {
            nextUpdateTime = endDateTime;
            nextUpdateReason = 'Class End: ${classData['subject']}';
          }
        }
      } catch (e) {
        print('⚠️ [Schedule] Error processing class: $e');
      }
    }

    if (nextUpdateTime != null) {
      final delay = nextUpdateTime.difference(now);
      final delayMinutes = delay.inMinutes;
      final delaySeconds = delay.inSeconds % 60;

      print(
        '⏰ [Schedule] Next update scheduled in ${delayMinutes}m ${delaySeconds}s',
      );
      print('📍 [Schedule] Reason: $nextUpdateReason');
      print(
        '🕐 [Schedule] Time: ${DateFormat('HH:mm').format(nextUpdateTime)}',
      );

      // Schedule the update
      _classScheduleTimer = Timer(delay, () {
        print('🔔 [Schedule] Scheduled update triggered: $nextUpdateReason');
        _updateHomeScreenWidget();

        // Schedule the next update after this one
        _scheduleNextClassUpdate();
      });
    } else {
      print('ℹ️ [Schedule] No more classes today, will check again tomorrow');

      // Schedule a check at midnight to set up tomorrow's schedule
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final untilMidnight = tomorrow.difference(now);

      _classScheduleTimer = Timer(untilMidnight, () {
        print('🌅 [Schedule] New day - rescheduling updates');
        _scheduleNextClassUpdate();
      });
    }
  }

  void _printDiagnosticInfo() {
    print('🔍 [Diagnostic] Widget Update System Status');
    print('   Total Updates: $_updateCount');
    print('   Error Count: $_errorCount');
    print(
      '   Last Update: ${_lastUpdate != null ? DateFormat('HH:mm:ss').format(_lastUpdate!) : 'Never'}',
    );
    print(
      '   Last Success: ${_lastSuccessfulUpdate != null ? DateFormat('HH:mm:ss').format(_lastSuccessfulUpdate!) : 'Never'}',
    );
    print('   Widgets Enabled: $widgetsEnabled');
    print('   Cached Classes: ${_cachedSchedule.length}');

    if (_updateHistory.isNotEmpty) {
      print('📋 [Diagnostic] Recent Update History:');
      for (int i = 0; i < _updateHistory.length; i++) {
        print('   ${i + 1}. ${_updateHistory[i]}');
      }
    }

    print('⏰ [Diagnostic] Timer Status:');
    print('   Widget Timer Active: ${_widgetUpdateTimer?.isActive ?? false}');
    print(
      '   Schedule Timer Active: ${_classScheduleTimer?.isActive ?? false}',
    );
    print(
      '   Connectivity Timer Active: ${_connectivityTimer?.isActive ?? false}',
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print('🔄 [Lifecycle] App state changed to: $state');

    switch (state) {
      case AppLifecycleState.resumed:
        print('▶️ [Lifecycle] App resumed - updating widget');
        _updateHomeScreenWidget();
        _scheduleNextClassUpdate(); // Reschedule in case times changed
        _printDiagnosticInfo(); // Print diagnostic info on resume
        break;
      case AppLifecycleState.paused:
        print('⏸️ [Lifecycle] App paused');
        break;
      case AppLifecycleState.inactive:
        print('💤 [Lifecycle] App inactive');
        break;
      case AppLifecycleState.detached:
        print('🔌 [Lifecycle] App detached');
        break;
      case AppLifecycleState.hidden:
        print('🙈 [Lifecycle] App hidden');
        break;
    }
  }

  Future<void> _checkConnectivity() async {
    bool wasOnline = isOnline;

    try {
      // Try to reach Firestore with server source
      await FirebaseFirestore.instance
          .collection('announcements')
          .limit(1)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 5));

      if (mounted) {
        setState(() {
          isOnline = true;
        });
      }

      // If we just came online, refresh notifications and widgets
      if (!wasOnline && mounted) {
        await NotificationService.refreshNotificationsWhenOnline();
        if (widgetsEnabled) {
          _updateHomeScreenWidget();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Back online. Syncing latest timetable…'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isOnline = false;
        });
      }

      if (wasOnline && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You’re offline. Showing saved timetable.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _loadScheduleCache(String cacheKey) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(cacheKey);
    final updatedRaw = prefs.getString('${cacheKey}_updatedAt');
    if (!mounted) return;

    if (raw == null) {
      setState(() {
        _scheduleCacheKey = cacheKey;
        _cachedSchedule = [];
        _cachedScheduleUpdatedAt = null;
      });
      return;
    }

    final decoded = jsonDecode(raw);
    final list = (decoded is List)
        ? decoded
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
        : <Map<String, dynamic>>[];

    setState(() {
      _scheduleCacheKey = cacheKey;
      _cachedSchedule = list;
      _cachedScheduleUpdatedAt = updatedRaw != null
          ? DateTime.tryParse(updatedRaw)
          : null;
    });
  }

  Future<void> _saveScheduleCache(
    String cacheKey,
    List<QueryDocumentSnapshot> docs, {
    required bool fromServer,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = docs.map((d) {
      final data = d.data() as Map<String, dynamic>;
      return {'id': d.id, ...data};
    }).toList();
    await prefs.setString(cacheKey, jsonEncode(payload));
    if (fromServer) {
      await prefs.setString(
        '${cacheKey}_updatedAt',
        DateTime.now().toIso8601String(),
      );
    }
  }

  Widget _buildRetroDisplayCard() {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final currentDay = DateFormat('EEEE').format(now);
    final currentTime = DateFormat('HH:mm').format(now);

    return Consumer<UserSelectionProvider>(
      builder: (context, userSelection, child) {
        if (!userSelection.hasSelection) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a1a),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0xFF333333),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: RetroDigitalDisplay(
                      enabled: true,
                      currentClass: null,
                      nextClass: null,
                      currentEndTime: null,
                      nextStartTime: null,
                      room: 'N/A',
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('departments')
              .doc(userSelection.departmentId)
              .collection('years')
              .doc(userSelection.yearId)
              .collection('sections')
              .doc(userSelection.sectionId)
              .collection('schedule')
              .where('day', isEqualTo: currentDay)
              .orderBy('startTime')
              .snapshots(),
          builder: (context, snapshot) {
            Map<String, dynamic>? currentClass;
            Map<String, dynamic>? nextClass;

            if (snapshot.hasData) {
              final classes = snapshot.data!.docs;
              for (var doc in classes) {
                final data = doc.data() as Map<String, dynamic>;
                final startTime = data['startTime'] as String;
                final endTime = data['endTime'] as String;

                final start = DateFormat('HH:mm').parse(startTime);
                final end = DateFormat('HH:mm').parse(endTime);
                final current = DateFormat('HH:mm').parse(currentTime);

                if (current.isAfter(start) && current.isBefore(end)) {
                  currentClass = data;
                } else if (current.isBefore(start)) {
                  nextClass = data;
                  break;
                }
              }
            }

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1a1a1a),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xFF333333),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: RetroDigitalDisplay(
                        enabled: true,
                        currentClass: currentClass?['subject'],
                        nextClass: nextClass?['subject'],
                        currentEndTime: currentClass?['endTime'],
                        nextStartTime: nextClass?['startTime'],
                        room:
                            currentClass?['room'] ??
                            nextClass?['room'] ??
                            'N/A',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTodaySummaryCard() {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final currentDay = DateFormat('EEEE').format(now);
    final currentTime = DateFormat('HH:mm').format(now);

    return Consumer<UserSelectionProvider>(
      builder: (context, userSelection, child) {
        if (!userSelection.hasSelection) {
          return Card(
            elevation: 0,
            color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.school_outlined, size: 48, color: theme.hintColor),
                  const SizedBox(height: 12),
                  Text(
                    'Welcome to Class Now',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select your class in Settings to get started',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('departments')
              .doc(userSelection.departmentId)
              .collection('years')
              .doc(userSelection.yearId)
              .collection('sections')
              .doc(userSelection.sectionId)
              .collection('schedule')
              .where('day', isEqualTo: currentDay)
              .orderBy('startTime')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildTodaySummarySkeleton(theme);
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Card(
                elevation: 0,
                color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_available_outlined,
                        size: 48,
                        color: theme.hintColor,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No classes today',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enjoy your free time!',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.hintColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            final classes = snapshot.data!.docs;
            Map<String, dynamic>? currentClass;
            Map<String, dynamic>? nextClass;

            for (var doc in classes) {
              final data = doc.data() as Map<String, dynamic>;
              final startTime = data['startTime'] as String;
              final endTime = data['endTime'] as String;

              final start = DateFormat('HH:mm').parse(startTime);
              final end = DateFormat('HH:mm').parse(endTime);
              final current = DateFormat('HH:mm').parse(currentTime);

              if (current.isAfter(start) && current.isBefore(end)) {
                currentClass = data;
              } else if (current.isBefore(start)) {
                nextClass = data;
                break;
              }
            }

            return Card(
              elevation: 2,
              color: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.today_outlined, color: theme.primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Today Summary',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          DateFormat('MMM dd').format(now),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (currentClass != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.play_circle_filled,
                                  color: theme.primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'NOW',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currentClass['subject'] ?? 'No Subject',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: theme.hintColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "${currentClass['startTime']} - ${currentClass['endTime']}",
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.hintColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 16,
                                  color: theme.hintColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "Room ${currentClass['room'] ?? 'TBD'}",
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.hintColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (nextClass != null) ...[
                      if (currentClass != null) const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant.withOpacity(
                            0.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'NEXT',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              nextClass['subject'] ?? 'No Subject',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: theme.hintColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  nextClass['startTime'],
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.hintColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 16,
                                  color: theme.hintColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "Room ${nextClass['room'] ?? 'TBD'}",
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.hintColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (currentClass == null && nextClass == null) ...[
                      Text(
                        'All classes completed for today!',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.hintColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTodaySummarySkeleton(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: theme.hintColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 120,
                  height: 20,
                  decoration: BoxDecoration(
                    color: theme.hintColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                color: theme.hintColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner({
    required String title,
    String? subtitle,
    IconData icon = Icons.info_outline,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatUpdatedAt(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('MMM dd, hh:mm a').format(dt);
  }

  String _friendlyFirestoreError(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return "Can’t refresh right now. Showing saved timetable.";
        case 'unavailable':
        case 'network-request-failed':
          return "You’re offline. Showing saved timetable.";
        default:
          return "We couldn’t load the latest timetable. Showing saved data.";
      }
    }
    return "We couldn’t load the latest timetable. Showing saved data.";
  }

  Future<void> _checkAdminStatus(User user) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (mounted) {
        setState(() {
          isAdmin = doc.exists && doc.data()?['role'] == 'mentor';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          isAdmin = false;
        });
      }
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      final retroEnabled = prefs.getBool('retro_display_enabled') ?? false;
      print('DEBUG: retro_display_enabled = $retroEnabled'); // Debug print
      setState(() {
        notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        widgetsEnabled = prefs.getBool('widgets_enabled') ?? true;
        retroDisplayEnabled = retroEnabled;
      });
      // Update the global notifier
      retroDisplayEnabledNotifier.value = retroEnabled;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload settings when dependencies change (like when returning from settings)
    _loadSettings();
  }

  @override
  void didUpdateWidget(DashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload settings when widget updates
    _loadSettings();
  }

  Future<void> _postAnnouncement(
    String message, {
    bool isSystemMessage = false,
  }) async {
    try {
      final userSelection = Provider.of<UserSelectionProvider>(
        context,
        listen: false,
      );
      if (!userSelection.hasSelection) return;

      await FirebaseFirestore.instance
          .collection('departments')
          .doc(userSelection.departmentId)
          .collection('years')
          .doc(userSelection.yearId)
          .collection('sections')
          .doc(userSelection.sectionId)
          .collection('announcements')
          .add({
            'message': message,
            'timestamp': FieldValue.serverTimestamp(),
            'isSystemMessage': isSystemMessage,
            'author': isAdmin
                ? FirebaseAuth.instance.currentUser?.email
                : 'System',
          });

      print('📢 [Announcement] Posted: $message');
    } catch (e) {
      print('❌ [Announcement] Error posting announcement: $e');
    }
  }

  Future<void> _manualRefresh() async {
    print('🔄 [Dashboard] Manual refresh triggered');
    try {
      await _checkConnectivity().timeout(const Duration(seconds: 7));
    } catch (_) {
      isOnline = false;
    }

    if (!mounted) return;

    if (isOnline) {
      if (widgetsEnabled) {
        await _updateHomeScreenWidget();
      }
      await NotificationService.refreshNotificationsWhenOnline();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Timetable updated successfully'),
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Offline: Displaying cached timetable'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _updateHomeScreenWidget() async {
    _updateCount++;
    if (widgetsEnabled) {
      await WidgetService.updateWidget();
      if (mounted) {
        setState(() {
          _lastUpdate = DateTime.now();
          _lastSuccessfulUpdate = DateTime.now();
          if (_updateHistory.length > 10) _updateHistory.removeAt(0);
          _updateHistory.add(
            '${DateFormat('HH:mm:ss').format(_lastUpdate!)} - SUCCESS',
          );
        });
      }
    }
  }

  void _startWidgetUpdateTimer() {
    print('⏰ [Timer] Starting foreground update timer (30 mins)');

    // We rely on AndroidAlarmManager for precise background updates
    // Removing periodic Workmanager task to save battery
    try {
      Workmanager().cancelByUniqueName("updateWidgetTask");
    } catch (_) {}

    _widgetUpdateTimer?.cancel();
    _widgetUpdateTimer = Timer.periodic(const Duration(minutes: 30), (
      timer,
    ) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (widgetsEnabled) {
        await _updateHomeScreenWidget();
      }
    });
    print('✅ [Timer] Foreground timer set to 30 mins');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: isDark
          ? const Color(0xFF000000)
          : const Color(0xFFF2F2F7),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100), // Increased height
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 45, 16, 0),
          child: GlassCard(
            blur: 40,
            opacity: 0.25,
            borderRadius: BorderRadius.circular(20),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              height: 70,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Perfectly Centered Title
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Class Now',
                        style: AppTextStyles.interTitle.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontSize: 20,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        isAdmin ? "Mentor Mode" : "Student View",
                        style: AppTextStyles.interSubtitle.copyWith(
                          color: isAdmin
                              ? AppTheme.accentPurple
                              : theme.hintColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                  // Left Action
                  Positioned(
                    left: 0,
                    child: IconButton(
                      icon: Icon(
                        isAdmin
                            ? Icons.lock_open_rounded
                            : Icons.lock_outline_rounded,
                        color: isAdmin
                            ? AppTheme.accentPurple
                            : theme.hintColor,
                      ),
                      onPressed: _showLoginDialog,
                    ),
                  ),
                  // Right Actions
                  Positioned(
                    right: 0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isAdmin)
                          IconButton(
                            icon: Icon(
                              Icons.add_circle_outline_rounded,
                              color: theme.primaryColor,
                            ),
                            onPressed: () => _showClassDialog(context),
                          ),
                        IconButton(
                          icon: Icon(
                            Icons.settings_outlined,
                            color: theme.primaryColor,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsPage(),
                              ),
                            );
                          },
                        ),
                      ],
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
            child: Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                final customPath = themeProvider.customBackgroundPath;
                if (customPath != null && File(customPath).existsSync()) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // Apply blur to background image
                      ImageFiltered(
                        imageFilter: ImageFilter.blur(
                          sigmaX: themeProvider.backgroundBlur,
                          sigmaY: themeProvider.backgroundBlur,
                          tileMode: TileMode.decal,
                        ),
                        child: Image.file(File(customPath), fit: BoxFit.cover),
                      ),
                    ],
                  );
                }
                return Container(
                  color: isDark
                      ? const Color(0xFF000000)
                      : const Color(0xFFF2F2F7),
                );
              },
            ),
          ),

          // Decorative blur circles - ONLY show when NO custom background
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              final hasCustomBg =
                  themeProvider.customBackgroundPath != null &&
                  File(themeProvider.customBackgroundPath!).existsSync();

              // Don't show decorative blurs if custom background is active
              if (hasCustomBg) return const SizedBox.shrink();

              return Stack(
                children: [
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
                ],
              );
            },
          ),

          // Main Content
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _manualRefresh,
              displacement: 80,
              backgroundColor: theme.primaryColor,
              color: Colors.white,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.only(top: 20, bottom: 100),
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: MediaQuery.of(context).size.height - 100,
                        ),
                        child: Column(
                          children: [
                            ValueListenableBuilder<bool>(
                              valueListenable: retroDisplayEnabledNotifier,
                              builder: (context, retroEnabled, child) {
                                if (retroEnabled) {
                                  return Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      0,
                                      16,
                                      20,
                                    ),
                                    child: _buildRetroDisplayCard(),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                            _buildDaySelector(),
                            const SizedBox(height: 10),
                            _buildClassList(),
                            if (isAdmin) ...[
                              const SizedBox(height: 20),
                              _MentorSaturdayControlPanel(),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return GlassCard(
              blur: themeProvider.glassBlur,
              opacity: 0.25,
              borderRadius: BorderRadius.circular(30),
              padding: EdgeInsets.zero,
              child: FloatingActionButton(
                backgroundColor: Colors.transparent,
                elevation: 0,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AnnouncementsPage(isAdmin: isAdmin),
                  ),
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('announcements')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final hasNew =
                        snapshot.hasData && snapshot.data!.docs.isNotEmpty;
                    return Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.campaign_rounded,
                          color: theme.primaryColor,
                          size: 28,
                        ),
                        if (hasNew)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: GlowingCard(
                              glowColor: theme.colorScheme.error,
                              glowRadius: 4,
                              padding: const EdgeInsets.all(4),
                              borderRadius: BorderRadius.circular(10),
                              child: Text(
                                '${snapshot.data!.docs.length}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDaySelector() {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(
      context,
    ); // Access provider
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 54,
      child: GlassCard(
        blur: themeProvider.glassBlur, // Dynamic blur
        opacity: 0.3,
        borderRadius: BorderRadius.circular(20),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: weekDays.length,
          itemBuilder: (context, index) {
            final day = weekDays[index];
            final isSelected = day == selectedDay;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => setState(() => selectedDay = day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              AppTheme.primaryBlue,
                              AppTheme.accentPurple,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.primaryBlue.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: Text(
                      day.substring(0, 3).toUpperCase(),
                      style: theme.textTheme.labelLarge?.copyWith(
                        letterSpacing: 0.5,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : theme.hintColor.withOpacity(0.8),
                        fontSize: 13,
                        height: 1.0, // Force centering
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildClassList() {
    final theme = Theme.of(context);
    return Consumer<UserSelectionProvider>(
      builder: (context, userSelection, child) {
        if (!userSelection.hasSelection) {
          return Center(
            child: Text(
              "Please select your class from the settings.",
              style: theme.textTheme.bodyLarge,
            ),
          );
        }

        final cacheKey =
            'cache_schedule_${userSelection.departmentId}_${userSelection.yearId}_${userSelection.sectionId}';
        if (_scheduleCacheKey != cacheKey) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _loadScheduleCache(cacheKey);
          });
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('departments')
              .doc(userSelection.departmentId)
              .collection('years')
              .doc(userSelection.yearId)
              .collection('sections')
              .doc(userSelection.sectionId)
              .collection('schedule')
              .snapshots(includeMetadataChanges: true),
          builder: (context, snapshot) {
            final hasCached =
                _scheduleCacheKey == cacheKey && _cachedSchedule.isNotEmpty;
            final fromCache = snapshot.data?.metadata.isFromCache == true;

            if (snapshot.hasData) {
              final docs = snapshot.data!.docs
                  .whereType<QueryDocumentSnapshot>()
                  .toList();
              _saveScheduleCache(cacheKey, docs, fromServer: !fromCache);
            }

            if (snapshot.connectionState == ConnectionState.waiting &&
                !hasCached) {
              return const ClassListSkeleton();
            }

            List<Map<String, dynamic>> all;
            if (snapshot.hasData) {
              all = snapshot.data!.docs
                  .map((d) => Map<String, dynamic>.from(d.data() as Map))
                  .toList();
            } else {
              all = _scheduleCacheKey == cacheKey ? _cachedSchedule : [];
            }

            final items = snapshot.hasData
                ? snapshot.data!.docs
                      .whereType<QueryDocumentSnapshot>()
                      .map(
                        (d) => _ScheduleItem(
                          doc: d,
                          data: Map<String, dynamic>.from(d.data() as Map),
                        ),
                      )
                      .toList()
                : _itemsFromMaps(all);

            if (snapshot.hasError && hasCached) {
              final title = _friendlyFirestoreError(snapshot.error!);
              final updated = _formatUpdatedAt(_cachedScheduleUpdatedAt);
              return Column(
                children: [
                  _buildInfoBanner(
                    title: title,
                    subtitle: updated.isNotEmpty
                        ? 'Last updated: $updated'
                        : null,
                    icon: Icons.wifi_off_outlined,
                  ),
                  _buildFilteredScheduleList(theme, items),
                ],
              );
            }

            // Only show offline banner if we've been offline for a while (debounce)
            // Don't show it when just switching days - that's annoying
            final shouldShowOfflineBanner =
                fromCache &&
                hasCached &&
                !isOnline &&
                snapshot.connectionState != ConnectionState.waiting;

            if (shouldShowOfflineBanner) {
              // Only show if we're truly offline, not just loading from cache
              return _buildFilteredScheduleList(theme, items);
            }

            if (snapshot.hasError && !hasCached) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_off_outlined,
                        size: 48,
                        color: theme.hintColor,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Can’t load timetable",
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _friendlyFirestoreError(snapshot.error!),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.hintColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return _buildFilteredScheduleList(theme, items);
          },
        );
      },
    );
  }

  Widget _buildFilteredScheduleList(ThemeData theme, List<_ScheduleItem> all) {
    final docs = all
        .where((e) => (e.data['day'] ?? '') == selectedDay)
        .toList();
    docs.sort(
      (a, b) => (a.data['startTime'] ?? '00:00').compareTo(
        (b.data['startTime'] ?? '00:00'),
      ),
    );

    if (docs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              children: [
                Icon(
                  Icons.event_available_outlined,
                  size: 44,
                  color: theme.hintColor,
                ),
                const SizedBox(height: 10),
                Text(
                  'No classes on $selectedDay',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Enjoy your time. Pull down to refresh when you\'re online.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final now = DateTime.now();
    final currentTime = DateFormat('HH:mm').format(now);
    final currentDay = DateFormat('EEEE').format(now);

    _ScheduleItem? currentClass;
    final List<_ScheduleItem> upcomingClasses = [];
    final List<_ScheduleItem> completedClasses = [];

    for (var doc in docs) {
      final startTime = doc.data['startTime'] ?? '';
      final endTime = doc.data['endTime'] ?? '';

      if (_isTimeInRange(currentTime, startTime, endTime) &&
          selectedDay == currentDay) {
        currentClass = doc;
      } else if (_isTimeBefore(currentTime, startTime) &&
          selectedDay == currentDay) {
        upcomingClasses.add(doc);
      } else {
        completedClasses.add(doc);
      }
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount:
          (currentClass != null ? 1 : 0) +
          upcomingClasses.length +
          completedClasses.length,
      itemBuilder: (context, index) {
        if (currentClass != null && index == 0) {
          return _buildCurrentClassCard(currentClass);
        } else {
          final adjustedIndex = currentClass != null ? index - 1 : index;
          if (adjustedIndex < upcomingClasses.length) {
            return _buildUpcomingClassCard(
              upcomingClasses[adjustedIndex],
              adjustedIndex == 0 && currentClass == null,
            );
          } else {
            final completedIndex = adjustedIndex - upcomingClasses.length;
            return _buildCompletedClassCard(completedClasses[completedIndex]);
          }
        }
      },
    );
  }

  bool _isTimeInRange(String currentTime, String startTime, String endTime) {
    try {
      final current = DateFormat('HH:mm').parse(currentTime);
      final start = DateFormat('HH:mm').parse(startTime);
      final end = DateFormat('HH:mm').parse(endTime);

      return (current.isAfter(start) || current.isAtSameMomentAs(start)) &&
          (current.isBefore(end) || current.isAtSameMomentAs(end));
    } catch (e) {
      return false;
    }
  }

  bool _isTimeBefore(String currentTime, String startTime) {
    try {
      final current = DateFormat('HH:mm').parse(currentTime);
      final start = DateFormat('HH:mm').parse(startTime);
      return current.isBefore(start);
    } catch (e) {
      return false;
    }
  }

  Widget _buildCurrentClassCard(_ScheduleItem item) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final data = item.data;
    final start = data['startTime'] ?? '--:--';
    final end = data['endTime'] ?? '--:--';

    // Calculate progress
    final now = DateTime.now();
    final currentTime = DateFormat('HH:mm').format(now);
    double progress = 0.0;

    try {
      final current = DateFormat('HH:mm').parse(currentTime);
      final classStart = DateFormat('HH:mm').parse(start);
      final classEnd = DateFormat('HH:mm').parse(end);

      final totalDuration = classEnd.difference(classStart).inMinutes;
      final elapsedDuration = current.difference(classStart).inMinutes;

      if (totalDuration > 0) {
        progress = (elapsedDuration / totalDuration).clamp(0.0, 1.0);
      }
    } catch (e) {
      progress = 0.0;
    }

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return GlassCard(
          margin: const EdgeInsets.only(bottom: 16),
          blur:
              themeProvider.glassBlur + 10, // Slightly more blur for live card
          opacity: 0.35,
          borderRadius: BorderRadius.circular(24),
          padding: EdgeInsets.zero,
          border: Border.all(
            color: theme.primaryColor.withOpacity(0.3),
            width: 1.5,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shimmering header for current class
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.primaryColor.withOpacity(0.15),
                      theme.primaryColor.withOpacity(0.05),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.5),
                                blurRadius: 4,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        )
                        .animate(
                          onPlay: (controller) =>
                              controller.repeat(reverse: true),
                        )
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.3, 1.3),
                          duration: const Duration(seconds: 1),
                        ),
                    const SizedBox(width: 8),
                    Text(
                      'LIVE NOW',
                      style: AppTextStyles.interLiveNow.copyWith(
                        color: Colors.red,
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "$start - $end",
                      style: AppTextStyles.interProgress.copyWith(
                        color: isDark
                            ? Colors.white70
                            : theme.colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            SubjectUtils.getSubjectIcon(data['subject']),
                            color: theme.primaryColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['subject'] ?? 'No Subject',
                                style: AppTextStyles.interSubject.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                data['mentor'] ?? 'Unknown Mentor',
                                style: AppTextStyles.interMentor.copyWith(
                                  color: isDark
                                      ? Colors.white60
                                      : theme.colorScheme.onSurface.withOpacity(
                                          0.6,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Session Progress',
                          style: AppTextStyles.interProgress.copyWith(
                            color: isDark
                                ? Colors.white70
                                : theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: AppTextStyles.interProgress.copyWith(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: theme.primaryColor.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.primaryColor,
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 16,
                          color: theme.primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Room ${data['room'] ?? 'TBD'}",
                          style: AppTextStyles.interSmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        if (isAdmin)
                          IconButton(
                            icon: const Icon(Icons.edit_note_rounded),
                            onPressed: () => _showEditOptions(item.doc!),
                            color: theme.primaryColor,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUpcomingClassCard(_ScheduleItem item, bool isFirst) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final data = item.data;
    final start = data['startTime'] ?? '--:--';
    final end = data['endTime'] ?? '--:--';

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return GlassCard(
          margin: const EdgeInsets.only(bottom: 12),
          blur: themeProvider.glassBlur,
          opacity: 0.25,
          borderRadius: BorderRadius.circular(18),
          padding: EdgeInsets.zero,
          child: InkWell(
            onLongPress: (isAdmin && item.doc != null)
                ? () => _showEditOptions(item.doc!)
                : null,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isFirst)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'UP NEXT',
                            style: AppTextStyles.interLiveNow.copyWith(
                              color: theme.primaryColor,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      const Spacer(),
                      Text(
                        "$start - $end",
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isDark
                              ? Colors.white70
                              : theme.colorScheme.onSurface.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        SubjectUtils.getSubjectIcon(data['subject']),
                        size: 20,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          data['subject'] ?? 'No Subject',
                          style: AppTextStyles.interNext.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      if (isAdmin)
                        IconButton(
                          icon: const Icon(Icons.edit_note_rounded),
                          onPressed: () => _showEditOptions(item.doc!),
                          color: theme.primaryColor,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 14,
                        color: isDark
                            ? Colors.white60
                            : theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        data['mentor'] ?? 'Unknown',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? Colors.white60
                              : theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: isDark
                            ? Colors.white60
                            : theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Room ${data['room'] ?? 'TBD'}",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? Colors.white60
                              : theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompletedClassCard(_ScheduleItem item) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final data = item.data;
    final start = data['startTime'] ?? '--:--';
    final end = data['endTime'] ?? '--:--';

    final Color mutedColor = isDark ? Colors.white24 : Colors.black26;

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return GlassCard(
          margin: const EdgeInsets.only(bottom: 8),
          blur: themeProvider.glassBlur * 0.75,
          opacity: 0.15,
          borderRadius: BorderRadius.circular(12),
          padding: EdgeInsets.zero,
          child: InkWell(
            onLongPress: (isAdmin && item.doc != null)
                ? () => _showEditOptions(item.doc!)
                : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'FINISHED',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: mutedColor,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w900,
                          fontSize: 9,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        "$start - $end",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: mutedColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: mutedColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          data['subject'] ?? 'No Subject',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            decoration: TextDecoration.lineThrough,
                            decorationColor: mutedColor.withOpacity(0.5),
                            decorationThickness: 2,
                            color: mutedColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (isAdmin)
                        IconButton(
                          icon: const Icon(Icons.edit_note_rounded),
                          onPressed: () => _showEditOptions(item.doc!),
                          color: theme.primaryColor.withOpacity(0.5),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showLoginDialog() {
    if (isAdmin) {
      FirebaseAuth.instance.signOut();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  void _showEditOptions(DocumentSnapshot doc) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.blue),
            title: const Text('Edit Class'),
            onTap: () {
              Navigator.pop(context);
              _showClassDialog(context, doc: doc);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete Class'),
            onTap: () {
              Navigator.pop(context);
              final data = doc.data() as Map<String, dynamic>;
              doc.reference.delete();
              _postAnnouncement(
                "Class deleted: ${data['subject']} (${data['day']} ${data['startTime']})",
                isSystemMessage: true,
              );
              if (widgetsEnabled) {
                _updateHomeScreenWidget();
              }
              NotificationService.scheduleTimetableNotifications();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showClassDialog(BuildContext context, {DocumentSnapshot? doc}) async {
    // ... (This dialog's styling can be improved later if needed)
    final prefs = await SharedPreferences.getInstance();
    final departmentId = prefs.getString('departmentId');
    final yearId = prefs.getString('yearId');
    final sectionId = prefs.getString('sectionId');

    final data = doc?.data() as Map<String, dynamic>?;
    final oldData = Map<String, dynamic>.from(data ?? {});
    final subjectController = TextEditingController(text: data?['subject']);
    final mentorController = TextEditingController(text: data?['mentor']);
    final roomController = TextEditingController(text: data?['room']);
    String addDay = data?['day'] ?? selectedDay;

    TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 30);
    TimeOfDay endTime = const TimeOfDay(hour: 9, minute: 20);
    if (data != null) {
      final s = data['startTime'].split(':');
      final e = data['endTime'].split(':');
      startTime = TimeOfDay(hour: int.parse(s[0]), minute: int.parse(s[1]));
      endTime = TimeOfDay(hour: int.parse(e[0]), minute: int.parse(e[1]));
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          surfaceTintColor: Colors.transparent,
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          title: Text(
            doc == null ? 'Add Class' : 'Edit Class',
            style: AppTextStyles.interTitle.copyWith(fontSize: 22),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: addDay,
                  dropdownColor: isDark
                      ? const Color(0xFF2C2C2E)
                      : Colors.white,
                  decoration: InputDecoration(
                    labelText: 'Day',
                    filled: true,
                    fillColor: theme.colorScheme.onSurface.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: weekDays
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => addDay = v!),
                ),
                const SizedBox(height: 16),
                _buildDialogField(
                  subjectController,
                  'Subject',
                  Icons.book_rounded,
                  isDark,
                ),
                const SizedBox(height: 16),
                _buildDialogField(
                  mentorController,
                  'Staff Name',
                  Icons.person_rounded,
                  isDark,
                ),
                const SizedBox(height: 16),
                _buildDialogField(
                  roomController,
                  'Room No',
                  Icons.room_rounded,
                  isDark,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: startTime,
                          );
                          if (t != null) setDialogState(() => startTime = t);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text('Start', style: theme.textTheme.labelSmall),
                              Text(
                                startTime.format(context),
                                style: TextStyle(
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: endTime,
                          );
                          if (t != null) setDialogState(() => endTime = t);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text('End', style: theme.textTheme.labelSmall),
                              Text(
                                endTime.format(context),
                                style: TextStyle(
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: theme.hintColor)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: () {
                final startStr =
                    "${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}";
                final endStr =
                    "${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}";

                final payload = {
                  'subject': subjectController.text,
                  'mentor': mentorController.text,
                  'room': roomController.text,
                  'day': addDay,
                  'startTime': startStr,
                  'endTime': endStr,
                };

                if (doc == null) {
                  if (departmentId != null &&
                      yearId != null &&
                      sectionId != null) {
                    FirebaseFirestore.instance
                        .collection('departments')
                        .doc(departmentId)
                        .collection('years')
                        .doc(yearId)
                        .collection('sections')
                        .doc(sectionId)
                        .collection('schedule')
                        .add(payload);
                    _postAnnouncement(
                      "New class added: ${payload['subject']} (${payload['day']} ${payload['startTime']})",
                      isSystemMessage: true,
                    );
                  }
                } else {
                  doc.reference.update(payload);
                  List<String> changes = [];
                  if (oldData['room'] != payload['room']) {
                    changes.add(
                      "Room: ${oldData['room']} → ${payload['room']}",
                    );
                  }
                  if (oldData['startTime'] != payload['startTime']) {
                    changes.add(
                      "Time: ${oldData['startTime']} → ${payload['startTime']}",
                    );
                  }
                  if (oldData['mentor'] != payload['mentor']) {
                    changes.add("Staff changed");
                  }

                  if (changes.isNotEmpty) {
                    _postAnnouncement(
                      "${payload['subject']} updated: ${changes.join(', ')}",
                      isSystemMessage: true,
                    );
                  }
                }
                if (widgetsEnabled) {
                  _updateHomeScreenWidget();
                }
                NotificationService.scheduleTimetableNotifications();
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogField(
    TextEditingController controller,
    String label,
    IconData icon,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          size: 20,
          color: theme.primaryColor.withOpacity(0.7),
        ),
        filled: true,
        fillColor: theme.colorScheme.onSurface.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.primaryColor),
        ),
      ),
    );
  }
}

class _ScheduleItem {
  final DocumentSnapshot? doc;
  final Map<String, dynamic> data;

  const _ScheduleItem({this.doc, required this.data});
}

class _MentorSaturdayControlPanel extends StatefulWidget {
  @override
  __MentorSaturdayControlPanelState createState() =>
      __MentorSaturdayControlPanelState();
}

class __MentorSaturdayControlPanelState
    extends State<_MentorSaturdayControlPanel> {
  String? _selectedSourceDay;
  bool _isLoading = false;

  final List<String> _sourceDays = [
    'None',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  Future<void> _applySchedule() async {
    if (_selectedSourceDay == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Action'),
        content: Text(
          'Are you sure you want to replace the entire Saturday schedule for ALL sections with the schedule from $_selectedSourceDay? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm & Apply'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final userSelection = Provider.of<UserSelectionProvider>(
        context,
        listen: false,
      );
      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      final sectionsRef = db
          .collection('departments')
          .doc(userSelection.departmentId)
          .collection('years')
          .doc(userSelection.yearId)
          .collection('sections');

      final sectionsSnapshot = await sectionsRef.get();

      if (sectionsSnapshot.docs.isEmpty) {
        throw Exception("No sections found to update.");
      }

      // For each section, prepare the delete and create operations
      for (final sectionDoc in sectionsSnapshot.docs) {
        final scheduleRef = sectionDoc.reference.collection('schedule');

        // Delete existing Saturday schedule
        final saturdaySnapshot = await scheduleRef
            .where('day', isEqualTo: 'Saturday')
            .get();
        for (final doc in saturdaySnapshot.docs) {
          batch.delete(doc.reference);
        }

        // Only clone if not "None"
        if (_selectedSourceDay != 'None') {
          // Get source day schedule to copy
          final sourceDaySnapshot = await scheduleRef
              .where('day', isEqualTo: _selectedSourceDay)
              .get();
          for (final doc in sourceDaySnapshot.docs) {
            final classData = doc.data();
            final newDocRef = scheduleRef.doc();
            batch.set(newDocRef, {...classData, 'day': 'Saturday'});
          }
        }
      }

      // Commit all operations in one atomic batch
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saturday schedule updated for all sections!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GlassCard(
      margin: const EdgeInsets.all(16),
      blur: 20,
      opacity: 0.1,
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_motion_rounded,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Saturday Setup',
                style: AppTextStyles.interTitle.copyWith(
                  fontSize: 18,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Clone a weekday timetable to Saturday for all sections.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? Colors.white60
                  : theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _selectedSourceDay,
            dropdownColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            decoration: InputDecoration(
              labelText: 'Select Source Day',
              labelStyle: TextStyle(color: theme.primaryColor),
              filled: true,
              fillColor: theme.colorScheme.onSurface.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            items: _sourceDays
                .map(
                  (day) => DropdownMenuItem(
                    value: day,
                    child: Text(
                      day,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedSourceDay = value;
              });
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: _selectedSourceDay == null || _isLoading
                  ? null
                  : _applySchedule,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Apply to Saturday',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ANNOUNCEMENTS PAGE
class AnnouncementsPage extends StatefulWidget {
  final bool isAdmin;
  const AnnouncementsPage({super.key, required this.isAdmin});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  final messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: isDark
          ? const Color(0xFF000000)
          : const Color(0xFFF2F2F7),
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
                    'Announcements',
                    style: AppTextStyles.interTitle.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontSize: 18,
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

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('announcements')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.campaign_outlined,
                                size: 64,
                                color: theme.hintColor.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No announcements yet',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.hintColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data =
                              docs[index].data() as Map<String, dynamic>;
                          final isSystem = data['isSystemMessage'] ?? false;
                          final timestamp = data['timestamp'] as Timestamp?;

                          return GlassCard(
                            margin: const EdgeInsets.only(bottom: 12),
                            blur: 15,
                            opacity: 0.08,
                            padding: EdgeInsets.zero,
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      (isSystem
                                              ? theme.primaryColor
                                              : theme.colorScheme.secondary)
                                          .withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isSystem
                                      ? Icons.info_outline
                                      : Icons.campaign_outlined,
                                  color: isSystem
                                      ? theme.primaryColor
                                      : theme.colorScheme.secondary,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                data['message'] ?? '',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              subtitle: timestamp != null
                                  ? Text(
                                      DateFormat(
                                        'MMM dd, hh:mm a',
                                      ).format(timestamp.toDate()),
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: theme.hintColor.withOpacity(
                                              0.7,
                                            ),
                                          ),
                                    )
                                  : null,
                              trailing: widget.isAdmin
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.delete_outline_rounded,
                                        size: 18,
                                        color: theme.colorScheme.error
                                            .withOpacity(0.7),
                                      ),
                                      onPressed: () =>
                                          docs[index].reference.delete(),
                                    )
                                  : null,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                if (widget.isAdmin)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    child: GlassCard(
                      blur: 20,
                      opacity: 0.1,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: messageController,
                              style: theme.textTheme.bodyMedium,
                              decoration: InputDecoration(
                                hintText: 'Type announcement...',
                                hintStyle: TextStyle(
                                  color: theme.hintColor.withOpacity(0.5),
                                ),
                                border: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.send_rounded,
                              color: theme.primaryColor,
                            ),
                            onPressed: () {
                              if (messageController.text.trim().isNotEmpty) {
                                FirebaseFirestore.instance
                                    .collection('announcements')
                                    .add({
                                      'message': messageController.text.trim(),
                                      'timestamp': FieldValue.serverTimestamp(),
                                      'isSystemMessage': false,
                                    });
                                messageController.clear();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
