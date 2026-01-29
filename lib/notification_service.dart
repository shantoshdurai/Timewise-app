import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

    final snapshot = await FirebaseFirestore.instance
        .collection('schedule')
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
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
        id: doc.id.hashCode,
        title: 'Class Starting Soon: $subject',
        body: 'Room: $room starts in $minutesBefore minutes.',
        dayIndex: dayIndex,
        hour: hour,
        minute: minute,
        leadMinutes: minutesBefore,
      );
    }
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
          'timewise_classes',
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
