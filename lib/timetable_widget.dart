import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class TimetableWidget extends StatefulWidget {
  const TimetableWidget({super.key});

  @override
  State<TimetableWidget> createState() => _TimetableWidgetState();
}

class _TimetableWidgetState extends State<TimetableWidget> {
  Timer? _timer;
  
  @override
  void initState() {
    super.initState();
    // Update every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Map<String, dynamic>? _getCurrentClass(List<DocumentSnapshot> docs) {
    final now = DateTime.now();
    final currentDay = DateFormat('EEEE').format(now);
    
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['dayOfWeek'] != currentDay) continue;
      
      final startParts = (data['startTime'] as String).split(':');
      final endParts = (data['endTime'] as String).split(':');
      
      final start = DateTime(now.year, now.month, now.day, int.parse(startParts[0]), int.parse(startParts[1]));
      final end = DateTime(now.year, now.month, now.day, int.parse(endParts[0]), int.parse(endParts[1]));
      
      if (now.isAfter(start) && now.isBefore(end)) {
        return {
          'data': data,
          'start': start,
          'end': end,
          'isCurrent': true,
        };
      }
    }
    return null;
  }

  Map<String, dynamic>? _getNextClass(List<DocumentSnapshot> docs) {
    final now = DateTime.now();
    final currentDay = DateFormat('EEEE').format(now);
    
    DocumentSnapshot? nextClass;
    DateTime? nextStart;
    
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['dayOfWeek'] != currentDay) continue;
      
      final startParts = (data['startTime'] as String).split(':');
      final start = DateTime(now.year, now.month, now.day, int.parse(startParts[0]), int.parse(startParts[1]));
      
      if (start.isAfter(now)) {
        if (nextStart == null || start.isBefore(nextStart)) {
          nextStart = start;
          nextClass = doc;
        }
      }
    }
    
    if (nextClass != null) {
      final data = nextClass.data() as Map<String, dynamic>;
      final endParts = (data['endTime'] as String).split(':');
      return {
        'data': data,
        'start': nextStart,
        'end': DateTime(now.year, now.month, now.day, int.parse(endParts[0]), int.parse(endParts[1])),
        'isCurrent': false,
      };
    }
    return null;
  }

  String _getTimeRemaining(DateTime end) {
    final now = DateTime.now();
    final diff = end.difference(now);
    
    if (diff.inHours > 0) {
      return '${diff.inHours}h ${diff.inMinutes % 60}m left';
    } else {
      return '${diff.inMinutes}m left';
    }
  }

  double _getProgress(DateTime start, DateTime end) {
    final now = DateTime.now();
    final total = end.difference(start).inMinutes;
    final elapsed = now.difference(start).inMinutes;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('schedule').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(179),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white70),
            ),
          );
        }

        final docs = snapshot.data!.docs;
        final current = _getCurrentClass(docs);
        final next = _getNextClass(docs);

        if (current == null && next == null) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(179),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event_available, color: Colors.white70, size: 32),
                SizedBox(height: 12),
                Text(
                  'No classes today',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          );
        }

        final display = current ?? next;
        final data = display!['data'] as Map<String, dynamic>;
        final isCurrent = display['isCurrent'] as bool;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(217),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withAlpha(26), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Label
              Text(
                isCurrent ? 'NOW' : 'NEXT UP',
                style: TextStyle(
                  color: isCurrent ? Colors.greenAccent : Colors.blueAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              
              // Subject Name
              Text(
                data['subject'] ?? 'Unknown',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              
              // Time & Room
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.white.withAlpha(153)),
                  const SizedBox(width: 6),
                  Text(
                    '${data['startTime']} - ${data['endTime']}',
                    style: TextStyle(color: Colors.white.withAlpha(179), fontSize: 13),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.location_on_outlined, size: 14, color: Colors.white.withAlpha(153)),
                  const SizedBox(width: 6),
                  Text(
                    'Room ${data['room']}',
                    style: TextStyle(color: Colors.white.withAlpha(179), fontSize: 13),
                  ),
                ],
              ),
              
              if (isCurrent) ...[
                const SizedBox(height: 16),
                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _getProgress(display['start'], display['end']),
                    backgroundColor: Colors.white.withAlpha(26),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 8),
                // Time Remaining
                Text(
                  _getTimeRemaining(display['end']),
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ] else ...[
                const SizedBox(height: 12),
                Text(
                  'Starts in ${_getTimeRemaining(display['start']).replaceAll(' left', '')}',
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              
              // Next class preview (if currently in a class)
              if (isCurrent && next != null) ...[
                const SizedBox(height: 16),
                Divider(color: Colors.white.withAlpha(26), height: 1),
                const SizedBox(height: 12),
                Text(
                  'UP NEXT',
                  style: TextStyle(
                    color: Colors.white.withAlpha(128),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  (next['data'] as Map<String, dynamic>)['subject'] ?? 'Unknown',
                  style: TextStyle(
                    color: Colors.white.withAlpha(179),
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
