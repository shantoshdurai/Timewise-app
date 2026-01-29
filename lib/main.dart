import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:home_widget/home_widget.dart';
import 'static_widget.dart';
import 'notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.init();
  runApp(const TimetableApp());
}

class TimetableApp extends StatelessWidget {
  const TimetableApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TimeWise',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF673AB7),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String selectedDay = DateFormat('EEEE').format(DateTime.now());
  bool isAdmin = false;
  bool notificationsEnabled = true;
  final String adminPIN = "1234";

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
    // Update widget on app start
    _updateHomeScreenWidget();
    // Schedule notifications on app start
    _loadSettings();
    NotificationService.scheduleTimetableNotifications();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _toggleNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final newValue = !notificationsEnabled;
    await prefs.setBool('notifications_enabled', newValue);
    setState(() {
      notificationsEnabled = newValue;
    });
    NotificationService.scheduleTimetableNotifications();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newValue ? "Notifications Enabled" : "Notifications Disabled",
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _updateHomeScreenWidget() async {
    try {
      final now = DateTime.now();
      final currentDay = DateFormat('EEEE').format(now);

      final snapshot = await FirebaseFirestore.instance
          .collection('schedule')
          .get();
      final docs = snapshot.docs;

      Map<String, dynamic>? currentClass;
      Map<String, dynamic>? nextClass;
      String? timeRemaining;
      double progress = 0.0;

      // Calculate Current Class
      for (var doc in docs) {
        final data = doc.data();
        if (data['dayOfWeek'] != currentDay) continue;

        final startP = (data['startTime'] as String).split(':');
        final endP = (data['endTime'] as String).split(':');
        final start = DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(startP[0]),
          int.parse(startP[1]),
        );
        final end = DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(endP[0]),
          int.parse(endP[1]),
        );

        if (now.isAfter(start) && now.isBefore(end)) {
          currentClass = data;
          final diff = end.difference(now);
          timeRemaining = diff.inHours > 0
              ? '${diff.inHours}h ${diff.inMinutes % 60}m'
              : '${diff.inMinutes}m';
          final total = end.difference(start).inMinutes;
          final elapsed = now.difference(start).inMinutes;
          progress = (elapsed / total).clamp(0.0, 1.0);
          break;
        }
      }

      // Calculate Next Class if no current
      if (currentClass == null) {
        DateTime? nextStart;
        for (var doc in docs) {
          final data = doc.data();
          if (data['dayOfWeek'] != currentDay) continue;
          final startP = (data['startTime'] as String).split(':');
          final start = DateTime(
            now.year,
            now.month,
            now.day,
            int.parse(startP[0]),
            int.parse(startP[1]),
          );
          if (start.isAfter(now)) {
            if (nextStart == null || start.isBefore(nextStart)) {
              nextStart = start;
              nextClass = data;
            }
          }
        }
      }

      await HomeWidget.renderFlutterWidget(
        StaticTimetableWidget(
          currentClass: currentClass,
          nextClass: nextClass,
          timeRemaining: timeRemaining,
          progress: progress,
        ),
        key: 'timetable_widget',
        logicalSize: const Size(320, 160),
        pixelRatio: 3.0,
      );

      await HomeWidget.renderFlutterWidget(
        SmallRobotWidget(
          currentClass: currentClass,
          nextClass: nextClass,
        ),
        key: 'robot_widget',
        logicalSize: const Size(160, 160),
        pixelRatio: 3.0,
      );

      await HomeWidget.updateWidget(
        name: 'TimetableWidgetProvider',
        androidName: 'TimetableWidgetProvider',
      );
      
      await HomeWidget.updateWidget(
        name: 'RobotWidgetProvider',
        androidName: 'RobotWidgetProvider',
      );
    } catch (e) {
      debugPrint("Widget update failed: $e");
    }
  }

  // YOUR TIMETABLE DATA
  final List<Map<String, dynamic>> timetableData = [
    {
      "subject": "Design and Analysis of Algorithms",
      "mentor": "NF5/ AP/AIDS",
      "room": "704",
      "dayOfWeek": "Monday",
      "startTime": "08:30",
      "endTime": "09:20",
    },
    {
      "subject": "Discrete Mathematics",
      "mentor": "Mrs. N. Subashini /AP/MATHS",
      "room": "704",
      "dayOfWeek": "Monday",
      "startTime": "09:20",
      "endTime": "10:10",
    },
    {
      "subject": "Introduction to Computational Biology",
      "mentor": "Mrs. K. Bharathi /AP/BTE",
      "room": "704",
      "dayOfWeek": "Monday",
      "startTime": "10:10",
      "endTime": "11:00",
    },
    {
      "subject": "Operating Systems",
      "mentor": "Mrs. Keerthanasri /AP/AIDS",
      "room": "704",
      "dayOfWeek": "Monday",
      "startTime": "11:15",
      "endTime": "12:05",
    },
    {
      "subject": "Digital Electronics and Microprocessors",
      "mentor": "Mrs. Kalpana /AP/ECE",
      "room": "704",
      "dayOfWeek": "Monday",
      "startTime": "12:05",
      "endTime": "12:55",
    },
    {
      "subject": "Operating Systems",
      "mentor": "Mrs. Keerthanasri /AP/AIDS",
      "room": "704",
      "dayOfWeek": "Tuesday",
      "startTime": "08:30",
      "endTime": "09:20",
    },
    {
      "subject": "Environmental Science",
      "mentor": "Dr. K. Rajalakshmi/ASP/CHEM",
      "room": "704",
      "dayOfWeek": "Tuesday",
      "startTime": "09:20",
      "endTime": "10:10",
    },
    {
      "subject": "Discrete Mathematics",
      "mentor": "Mrs. N. Subashini /AP/MATHS",
      "room": "704",
      "dayOfWeek": "Tuesday",
      "startTime": "10:10",
      "endTime": "11:00",
    },
    {
      "subject": "Computational Intelligence",
      "mentor": "Ms. P. Sudha/AP/AIDS",
      "room": "704",
      "dayOfWeek": "Tuesday",
      "startTime": "11:15",
      "endTime": "12:05",
    },
    {
      "subject": "Design Thinking",
      "mentor": "Mrs. N. Radha /AP/AIDS",
      "room": "704",
      "dayOfWeek": "Tuesday",
      "startTime": "12:05",
      "endTime": "12:55",
    },
    {
      "subject": "Design and Analysis of Algorithms",
      "mentor": "NF5/ AP/AIDS",
      "room": "704",
      "dayOfWeek": "Wednesday",
      "startTime": "09:20",
      "endTime": "10:10",
    },
    {
      "subject": "Computational Intelligence",
      "mentor": "Ms. P. Sudha/AP/AIDS",
      "room": "704",
      "dayOfWeek": "Wednesday",
      "startTime": "10:10",
      "endTime": "11:00",
    },
    {
      "subject": "Introduction to Computational Biology",
      "mentor": "Mrs. K. Bharathi /AP/BTE",
      "room": "704",
      "dayOfWeek": "Wednesday",
      "startTime": "11:15",
      "endTime": "12:05",
    },
    {
      "subject": "Introduction to Computational Biology",
      "mentor": "Mrs. K. Bharathi /AP/BTE",
      "room": "704",
      "dayOfWeek": "Thursday",
      "startTime": "08:30",
      "endTime": "09:20",
    },
    {
      "subject": "Computational Intelligence",
      "mentor": "Ms. P. Sudha/AP/AIDS",
      "room": "704",
      "dayOfWeek": "Thursday",
      "startTime": "09:20",
      "endTime": "10:10",
    },
    {
      "subject": "Digital Electronics and Microprocessors",
      "mentor": "Mrs. Kalpana /AP/ECE",
      "room": "704",
      "dayOfWeek": "Thursday",
      "startTime": "10:10",
      "endTime": "11:00",
    },
    {
      "subject": "Discrete Mathematics",
      "mentor": "Mrs. N. Subashini /AP/MATHS",
      "room": "704",
      "dayOfWeek": "Thursday",
      "startTime": "11:15",
      "endTime": "12:05",
    },
    {
      "subject": "Design and Analysis of Algorithms",
      "mentor": "NF5/ AP/AIDS",
      "room": "704",
      "dayOfWeek": "Thursday",
      "startTime": "12:05",
      "endTime": "12:55",
    },
    {
      "subject": "Operating Systems",
      "mentor": "Mrs. Keerthanasri /AP/AIDS",
      "room": "704",
      "dayOfWeek": "Thursday",
      "startTime": "13:25",
      "endTime": "14:15",
    },
    {
      "subject": "Environmental Science",
      "mentor": "Dr. K. Rajalakshmi/ASP/CHEM",
      "room": "704",
      "dayOfWeek": "Friday",
      "startTime": "08:30",
      "endTime": "09:20",
    },
    {
      "subject": "Discrete Mathematics",
      "mentor": "Mrs. N. Subashini /AP/MATHS",
      "room": "704",
      "dayOfWeek": "Friday",
      "startTime": "09:20",
      "endTime": "10:10",
    },
    {
      "subject": "Operating Systems",
      "mentor": "Mrs. Keerthanasri /AP/AIDS",
      "room": "704",
      "dayOfWeek": "Friday",
      "startTime": "10:10",
      "endTime": "11:00",
    },
    {
      "subject": "Design Thinking",
      "mentor": "Mrs. N. Radha /AP/AIDS",
      "room": "704",
      "dayOfWeek": "Friday",
      "startTime": "11:15",
      "endTime": "12:05",
    },
    {
      "subject": "Digital Electronics and Microprocessors",
      "mentor": "Mrs. Kalpana /AP/ECE",
      "room": "704",
      "dayOfWeek": "Friday",
      "startTime": "12:05",
      "endTime": "12:55",
    },
  ];

  Future<void> _importData() async {
    final batch = FirebaseFirestore.instance.batch();
    final collection = FirebaseFirestore.instance.collection('schedule');

    final existingData = await collection.get();
    for (var doc in existingData.docs) {
      batch.delete(doc.reference);
    }

    for (var item in timetableData) {
      final newDoc = collection.doc();
      batch.set(newDoc, item);
    }

    await batch.commit();
    _updateHomeScreenWidget();
    NotificationService.scheduleTimetableNotifications();

    // Log the import action
    _postAnnouncement(
      "Full timetable imported successfully!",
      isSystemMessage: true,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Timetable Imported Successfully!")),
      );
    }
  }

  Future<void> _postAnnouncement(
    String message, {
    bool isSystemMessage = false,
  }) async {
    await FirebaseFirestore.instance.collection('announcements').add({
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'isSystemMessage': isSystemMessage,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              'TimeWise',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              isAdmin ? "MENTOR MODE" : "Student View",
              style: TextStyle(
                fontSize: 10,
                color: isAdmin ? Colors.green : Colors.grey,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            isAdmin ? Icons.lock_open : Icons.lock_outline,
            color: isAdmin ? Colors.green : Colors.grey,
          ),
          onPressed: _showLoginDialog,
        ),
        actions: [
          if (isAdmin) ...[
            IconButton(
              tooltip: "Import All Data",
              icon: const Icon(Icons.auto_fix_high, color: Colors.orange),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Import Full Timetable?"),
                    content: const Text(
                      "This will replace all current classes with the full timetable list.",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _importData();
                        },
                        child: const Text("Import Now"),
                      ),
                    ],
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Color(0xFF673AB7)),
              onPressed: () => _showClassDialog(context),
            ),
          ],
          IconButton(
            tooltip: "Notifications",
            icon: Icon(
              notificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
              color: notificationsEnabled ? const Color(0xFF673AB7) : Colors.grey,
            ),
            onPressed: _toggleNotifications,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDaySelector(),
          Expanded(child: _buildClassList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnnouncementsPage(isAdmin: isAdmin),
          ),
        ),
        backgroundColor: const Color(0xFF673AB7),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('announcements')
              .snapshots(),
          builder: (context, snapshot) {
            final hasNew = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
            return Stack(
              children: [
                const Icon(Icons.chat_bubble_outline, color: Colors.white),
                if (hasNew)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${snapshot.data!.docs.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
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
  }

  Widget _buildDaySelector() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: weekDays.length,
        itemBuilder: (context, index) {
          final day = weekDays[index];
          final isSelected = day == selectedDay;
          return GestureDetector(
            onTap: () => setState(() => selectedDay = day),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF673AB7)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF673AB7)
                      : Colors.grey[300]!,
                ),
              ),
              child: Text(
                day.substring(0, 3),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildClassList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schedule')
          .where('dayOfWeek', isEqualTo: selectedDay)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        docs.sort(
          (a, b) => ((a.data() as Map)['startTime'] ?? '00:00').compareTo(
            (b.data() as Map)['startTime'] ?? '00:00',
          ),
        );

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No classes on $selectedDay',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) => _buildClassCard(docs[index]),
        );
      },
    );
  }

  Widget _buildClassCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final start = data['startTime'] ?? '--:--';
    final end = data['endTime'] ?? '--:--';

    bool isCompleted = false;
    if (selectedDay == DateFormat('EEEE').format(DateTime.now())) {
      final now = DateTime.now();
      final endParts = end.split(':');
      if (endParts.length == 2) {
        final endTime = DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(endParts[0]),
          int.parse(endParts[1]),
        );
        isCompleted = now.isAfter(endTime);
      }
    }

    return Opacity(
      opacity: isCompleted ? 0.5 : 1.0,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        child: InkWell(
          onLongPress: isAdmin ? () => _showEditOptions(doc) : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.grey[100]
                            : const Color(0xFFEDE7F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "$start - $end",
                        style: TextStyle(
                          color: isCompleted
                              ? Colors.grey
                              : const Color(0xFF673AB7),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (isAdmin)
                      const Icon(
                        Icons.edit_note,
                        size: 20,
                        color: Colors.blueGrey,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  data['subject'] ?? 'No Subject',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      data['mentor'] ?? 'Unknown',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Room ${data['room'] ?? 'TBD'}",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLoginDialog() {
    if (isAdmin) {
      setState(() => isAdmin = false);
      return;
    }
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Mentor PIN'),
        content: TextField(
          controller: pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: "****"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (pinController.text == adminPIN) {
                setState(() => isAdmin = true);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("Wrong PIN!")));
              }
            },
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
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
                "Class deleted: ${data['subject']} (${data['dayOfWeek']} ${data['startTime']})",
                isSystemMessage: true,
              );
              _updateHomeScreenWidget();
              NotificationService.scheduleTimetableNotifications();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showClassDialog(BuildContext context, {DocumentSnapshot? doc}) {
    final data = doc?.data() as Map<String, dynamic>?;
    final oldData = Map<String, dynamic>.from(data ?? {});
    final subjectController = TextEditingController(text: data?['subject']);
    final mentorController = TextEditingController(text: data?['mentor']);
    final roomController = TextEditingController(text: data?['room']);
    String addDay = data?['dayOfWeek'] ?? selectedDay;

    TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 30);
    TimeOfDay endTime = const TimeOfDay(hour: 9, minute: 20);
    if (data != null) {
      final s = data['startTime'].split(':');
      final e = data['endTime'].split(':');
      startTime = TimeOfDay(hour: int.parse(s[0]), minute: int.parse(s[1]));
      endTime = TimeOfDay(hour: int.parse(e[0]), minute: int.parse(e[1]));
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(doc == null ? 'Add Class' : 'Edit Class'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: addDay,
                  isExpanded: true,
                  items: weekDays
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => addDay = v!),
                ),
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(labelText: 'Subject'),
                ),
                TextField(
                  controller: mentorController,
                  decoration: const InputDecoration(labelText: 'Mentor Name'),
                ),
                TextField(
                  controller: roomController,
                  decoration: const InputDecoration(labelText: 'Room No'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    TextButton(
                      onPressed: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: startTime,
                        );
                        if (t != null) setDialogState(() => startTime = t);
                      },
                      child: Text("Start: ${startTime.format(context)}"),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: endTime,
                        );
                        if (t != null) setDialogState(() => endTime = t);
                      },
                      child: Text("End: ${endTime.format(context)}"),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final startStr =
                    "${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}";
                final endStr =
                    "${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}";

                final payload = {
                  'subject': subjectController.text,
                  'mentor': mentorController.text,
                  'room': roomController.text,
                  'dayOfWeek': addDay,
                  'startTime': startStr,
                  'endTime': endStr,
                };

                if (doc == null) {
                  FirebaseFirestore.instance
                      .collection('schedule')
                      .add(payload);
                  _postAnnouncement(
                    "New class added: ${payload['subject']} (${payload['dayOfWeek']} ${payload['startTime']})",
                    isSystemMessage: true,
                  );
                } else {
                  doc.reference.update(payload);

                  // Generate change log
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
                    changes.add("Mentor changed");
                  }

                  if (changes.isNotEmpty) {
                    _postAnnouncement(
                      "${payload['subject']} updated: ${changes.join(', ')}",
                      isSystemMessage: true,
                    );
                  }
                }
                _updateHomeScreenWidget();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        backgroundColor: const Color(0xFF673AB7),
        foregroundColor: Colors.white,
      ),
      body: Column(
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
                  return const Center(child: Text('No announcements yet'));
                }

                return ListView.builder(
                  reverse: false,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isSystem = data['isSystemMessage'] ?? false;
                    final timestamp = data['timestamp'] as Timestamp?;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: isSystem ? Colors.blue[50] : Colors.white,
                      child: ListTile(
                        leading: Icon(
                          isSystem ? Icons.info_outline : Icons.campaign,
                          color: isSystem
                              ? Colors.blue
                              : const Color(0xFF673AB7),
                        ),
                        title: Text(
                          data['message'] ?? '',
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: timestamp != null
                            ? Text(
                                DateFormat(
                                  'MMM dd, hh:mm a',
                                ).format(timestamp.toDate()),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              )
                            : null,
                        trailing: widget.isAdmin
                            ? IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                ),
                                onPressed: () => docs[index].reference.delete(),
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type announcement...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFF673AB7)),
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
        ],
      ),
    );
  }
}
