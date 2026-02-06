import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

/// Builds context information for the chatbot from user's schedule
class ChatbotContextBuilder {
  /// Build comprehensive context for the AI
  static Future<String> buildContext() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    // Get user's selection
    final departmentId = prefs.getString('departmentId') ?? 'Unknown';
    final yearId = prefs.getString('yearId') ?? 'Unknown';
    final sectionId = prefs.getString('sectionId') ?? 'Unknown';

    // Get schedule data
    final scheduleData = await _getScheduleData();

    // Find current and next class
    final currentClass = _getCurrentClass(scheduleData, now);
    final nextClass = _getNextClass(scheduleData, now);

    // Build the context string
    return _buildContextString(
      now: now,
      departmentId: departmentId,
      yearId: yearId,
      sectionId: sectionId,
      scheduleData: scheduleData,
      currentClass: currentClass,
      nextClass: nextClass,
    );
  }

  static Future<List<Map<String, dynamic>>> _getScheduleData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Try to get from cache first
      final cacheKey =
          'schedule_cache_${prefs.getString('departmentId')}_'
          '${prefs.getString('yearId')}_${prefs.getString('sectionId')}';
      final cachedData = prefs.getString(cacheKey);

      if (cachedData != null) {
        final decoded = jsonDecode(cachedData);
        if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }

      // If no cache, try to fetch from Firestore
      final departmentId = prefs.getString('departmentId');
      final yearId = prefs.getString('yearId');
      final sectionId = prefs.getString('sectionId');

      if (departmentId != null && yearId != null && sectionId != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('departments')
            .doc(departmentId)
            .collection('years')
            .doc(yearId)
            .collection('sections')
            .doc(sectionId)
            .collection('schedule')
            .get();

        return snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
      }
    } catch (e) {
      print('Error fetching schedule data: $e');
    }

    return [];
  }

  static Map<String, dynamic>? _getCurrentClass(
    List<Map<String, dynamic>> scheduleData,
    DateTime now,
  ) {
    final currentTime = DateFormat('HH:mm').format(now);
    final currentDay = DateFormat('EEEE').format(now);

    for (var classData in scheduleData) {
      final dayOfWeek = (classData['day'] ?? classData['dayOfWeek']) as String?;
      if (dayOfWeek != currentDay) continue;

      try {
        final startTime = classData['startTime'] as String;
        final endTime = classData['endTime'] as String;

        final start = DateFormat('HH:mm').parse(startTime);
        final end = DateFormat('HH:mm').parse(endTime);
        final current = DateFormat('HH:mm').parse(currentTime);

        if (current.isAfter(start) && current.isBefore(end)) {
          return classData;
        }
      } catch (e) {
        continue;
      }
    }

    return null;
  }

  static Map<String, dynamic>? _getNextClass(
    List<Map<String, dynamic>> scheduleData,
    DateTime now,
  ) {
    final currentTime = DateFormat('HH:mm').format(now);
    final currentDay = DateFormat('EEEE').format(now);

    // Look for next class today
    for (var classData in scheduleData) {
      final dayOfWeek = (classData['day'] ?? classData['dayOfWeek']) as String?;
      if (dayOfWeek != currentDay) continue;

      try {
        final startTime = classData['startTime'] as String;
        final start = DateFormat('HH:mm').parse(startTime);
        final current = DateFormat('HH:mm').parse(currentTime);

        if (current.isBefore(start)) {
          return classData;
        }
      } catch (e) {
        continue;
      }
    }

    // If no class today, find first class tomorrow
    final tomorrow = DateFormat(
      'EEEE',
    ).format(now.add(const Duration(days: 1)));
    for (var classData in scheduleData) {
      final dayOfWeek = (classData['day'] ?? classData['dayOfWeek']) as String?;
      if (dayOfWeek == tomorrow) {
        return classData;
      }
    }

    return null;
  }

  static String _buildContextString({
    required DateTime now,
    required String departmentId,
    required String yearId,
    required String sectionId,
    required List<Map<String, dynamic>> scheduleData,
    required Map<String, dynamic>? currentClass,
    required Map<String, dynamic>? nextClass,
  }) {
    final buffer = StringBuffer();

    buffer.writeln(
      'You are a helpful assistant for "Class Now", a college timetable management app.',
    );
    buffer.writeln('');
    buffer.writeln('CURRENT STATUS:');
    buffer.writeln(
      '- Current time: ${DateFormat('EEEE, MMMM d, h:mm a').format(now)}',
    );

    if (currentClass != null) {
      buffer.writeln(
        '- Current class: ${currentClass['subject']} in Room ${currentClass['room']}',
      );
      buffer.writeln('  Ends at: ${currentClass['endTime']}');
      if (currentClass['staff'] != null) {
        buffer.writeln('  Staff: ${currentClass['staff']}');
      }
    } else {
      buffer.writeln('- Current class: No class currently in session');
    }

    if (nextClass != null) {
      final nextDay = (nextClass['day'] ?? nextClass['dayOfWeek']) as String?;
      final isToday = nextDay == DateFormat('EEEE').format(now);
      buffer.writeln(
        '- Next class: ${nextClass['subject']} at ${nextClass['startTime']} in Room ${nextClass['room']}${isToday ? ' (today)' : ' ($nextDay)'}',
      );
      if (nextClass['staff'] != null) {
        buffer.writeln('  Staff: ${nextClass['staff']}');
      }
    } else {
      buffer.writeln('- Next class: No upcoming classes scheduled');
    }

    buffer.writeln('');
    buffer.writeln('STUDENT INFORMATION:');
    buffer.writeln('- Department: $departmentId');
    buffer.writeln('- Year: $yearId');
    buffer.writeln('- Section: $sectionId');
    buffer.writeln('');

    if (scheduleData.isNotEmpty) {
      buffer.writeln('FULL WEEK SCHEDULE:');
      buffer.writeln(_formatSchedule(scheduleData));
      buffer.writeln('');
      buffer.writeln('STAFF INFORMATION:');
      buffer.writeln(_formatStaffInfo(scheduleData));
    } else {
      buffer.writeln('(No schedule data available)');
    }

    buffer.writeln('');
    buffer.writeln('IDENTITY & KNOWLEDGE:');
    buffer.writeln('- You are the official AI Assistant for "Class Now".');
    buffer.writeln(
      '- You are designed exclusively to help students of **Dhanalakshmi Srinivasan University, Trichy**.',
    );
    buffer.writeln('- Be helpful, polite, and proud to represent DSU Trichy.');
    buffer.writeln(
      '- Your primary goal is to help students manage their academic schedule efficiently.',
    );
    buffer.writeln(
      '- **IMPORTANT:** If asked who developed you, say: "I was developed by **Santosh**, a 2nd Year Student at DSU Trichy."',
    );
    buffer.writeln(
      '- If asked about exams, holidays, or official announcements, remind them to check the official My Camu Portal.',
    );
    buffer.writeln(
      '- You are knowledgeable about the specific timetable provided above.',
    );

    buffer.writeln('');
    buffer.writeln('INSTRUCTIONS:');
    buffer.writeln(
      '- Answer questions about classes, timing, staff, and rooms',
    );
    buffer.writeln(
      '- Be friendly, concise, and helpful (2-4 sentences typically)',
    );
    buffer.writeln('- Use emojis occasionally to be friendly');
    buffer.writeln(
      '- If asked about "my next class" or "current class", use the CURRENT STATUS above',
    );
    buffer.writeln('- For specific days, refer to the FULL WEEK SCHEDULE');
    buffer.writeln('- Always mention room numbers when discussing classes');
    buffer.writeln('- Use 12-hour time format (e.g., "2:30 PM" not "14:30")');
    buffer.writeln(
      '- If you don\'t know something from the context, say so clearly',
    );
    buffer.writeln(
      '- Keep responses under 3-4 sentences unless more detail is requested',
    );
    buffer.writeln(
      '- Be encouraging and positive like a helpful classmate , end every response with a another question about classes',
    );

    return buffer.toString();
  }

  static String _formatSchedule(List<Map<String, dynamic>> schedule) {
    final grouped = <String, List<Map<String, dynamic>>>{};

    for (var cls in schedule) {
      final day = (cls['day'] ?? cls['dayOfWeek']) as String?;
      if (day != null) {
        grouped.putIfAbsent(day, () => []).add(cls);
      }
    }

    final buffer = StringBuffer();
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    for (var day in days) {
      if (grouped.containsKey(day) && grouped[day]!.isNotEmpty) {
        buffer.writeln('$day:');

        // Sort by start time
        final dayClasses = grouped[day]!;
        dayClasses.sort((a, b) {
          try {
            final aTime = DateFormat('HH:mm').parse(a['startTime']);
            final bTime = DateFormat('HH:mm').parse(b['startTime']);
            return aTime.compareTo(bTime);
          } catch (e) {
            return 0;
          }
        });

        for (var cls in dayClasses) {
          final subject = cls['subject'] ?? 'Unknown';
          final startTime = cls['startTime'] ?? 'N/A';
          final endTime = cls['endTime'] ?? 'N/A';
          final room = cls['room'] ?? 'N/A';
          final staff = cls['staff'] ?? 'TBA';

          buffer.writeln(
            '  - $subject ($startTime-$endTime) - Room $room - $staff',
          );
        }
      }
    }

    return buffer.toString();
  }

  static String _formatStaffInfo(List<Map<String, dynamic>> schedule) {
    final staffMap = <String, Set<String>>{};

    for (var cls in schedule) {
      final subject = cls['subject'] as String?;
      final staff = cls['staff'] as String?;

      if (subject != null && staff != null && staff != 'TBA') {
        staffMap.putIfAbsent(subject, () => {}).add(staff);
      }
    }

    if (staffMap.isEmpty) {
      return '(No staff information available)';
    }

    final buffer = StringBuffer();
    for (var entry in staffMap.entries) {
      buffer.writeln('- ${entry.key}: ${entry.value.join(', ')}');
    }

    return buffer.toString();
  }
}
