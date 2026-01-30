import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tapped logic here
      },
    );
  }

  static Future<void> scheduleTimetableNotifications() async {
    final prefs = await SharedPreferences.getInstance();

    if (!prefs.containsKey('notifications_enabled')) {
      await prefs.setBool('notifications_enabled', true);
    }

    final bool enabled = prefs.getBool('notifications_enabled') ?? true;
    final int minutesBefore = prefs.getInt('notifications_lead_time') ?? 15;

    await _notifications.cancelAll();

    if (!enabled) return;

    // Try to get schedule data with offline fallback
    List<Map<String, dynamic>> scheduleData = await _getScheduleDataWithOffline();

    for (var data in scheduleData) {
      final dayOfWeek = data['dayOfWeek'] as String;
      final startTimeStr = data['startTime'] as String;
      final subject = data['subject'] as String;
      final room = data['room'] as String;

      final dayIndex = _getDayIndex(dayOfWeek);
      if (dayIndex == -1) continue;

      final timeParts = startTimeStr.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      await _scheduleWeekly(
        id: data['id']?.hashCode ?? data.toString().hashCode,
        title: 'Class Starting Soon: $subject',
        body: 'Room: $room starts in $minutesBefore minutes.',
        dayIndex: dayIndex,
        hour: hour,
        minute: minute,
        leadMinutes: minutesBefore,
      );
    }
  }

  static Future<List<Map<String, dynamic>>> _getScheduleDataWithOffline() async {
    final prefs = await SharedPreferences.getInstance();
    
    try {
      // Try online first
      final snapshot = await FirebaseFirestore.instance
          .collection('schedule')
          .get(const GetOptions(source: Source.server));
      
      final scheduleData = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Cache the data for offline use
      await _cacheScheduleData(scheduleData);
      return scheduleData;
      
    } catch (e) {
      // Fallback to cached data
      return await _getCachedScheduleData();
    }
  }

  static Future<void> _cacheScheduleData(List<Map<String, dynamic>> scheduleData) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(scheduleData);
    await prefs.setString('cached_schedule_data', jsonString);
    await prefs.setString('schedule_cache_updated', DateTime.now().toIso8601String());
  }

  static Future<List<Map<String, dynamic>>> _getCachedScheduleData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('cached_schedule_data');
    
    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        return jsonList.cast<Map<String, dynamic>>();
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  static Future<void> _scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required int dayIndex,
    required int hour,
    required int minute,
    required int leadMinutes,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    ).subtract(Duration(minutes: leadMinutes));

    while (scheduledDate.weekday != dayIndex) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'classnow_classes',
          'Class Reminders',
          channelDescription: 'Notifications for upcoming classes',
          importance: Importance.max,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(''),
        ),
      ),
      payload: 'schedule_notification',
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  static Future<void> refreshNotificationsWhenOnline() async {
    try {
      // Check if we can reach Firestore
      await FirebaseFirestore.instance.collection('schedule').limit(1).get(const GetOptions(source: Source.server));
      
      // If successful, refresh notifications with latest data
      await scheduleTimetableNotifications();
    } catch (e) {
      // Still offline, keep using cached data
      print('Still offline, using cached notification data');
    }
  }

  static Future<String> getCacheStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedTime = prefs.getString('schedule_cache_updated');
    
    if (cachedTime != null) {
      final cacheTime = DateTime.parse(cachedTime);
      final now = DateTime.now();
      final difference = now.difference(cacheTime);
      
      if (difference.inHours < 1) {
        return 'Cached: ${difference.inMinutes} min ago';
      } else if (difference.inDays < 1) {
        return 'Cached: ${difference.inHours} hours ago';
      } else {
        return 'Cached: ${difference.inDays} days ago';
      }
    }
    
    return 'No cache';
  }

  static int _getDayIndex(String day) {
    switch (day.toLowerCase()) {
      case 'monday':
        return DateTime.monday;
      case 'tuesday':
        return DateTime.tuesday;
      case 'wednesday':
        return DateTime.wednesday;
      case 'thursday':
        return DateTime.thursday;
      case 'friday':
        return DateTime.friday;
      case 'saturday':
        return DateTime.saturday;
      case 'sunday':
        return DateTime.sunday;
      default:
        return -1;
    }
  }
}
