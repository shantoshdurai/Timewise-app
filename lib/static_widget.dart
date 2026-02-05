import 'package:flutter/material.dart';
import 'package:flutter_firebase_test/subject_utils.dart';

// --- EXISTING LARGE WIDGET ---
class StaticTimetableWidget extends StatelessWidget {
  final Map<String, dynamic>? currentClass;
  final Map<String, dynamic>? nextClass;
  final String? timeRemaining;
  final double progress;

  final double refreshAngle;

  const StaticTimetableWidget({
    super.key,
    this.currentClass,
    this.nextClass,
    this.timeRemaining,
    this.progress = 0.0,
    this.refreshAngle = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 800,
      height: 400,
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F0F).withOpacity(0.7),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.white24, width: 2.0),
        ),
        child: Material(color: Colors.transparent, child: _buildContent()),
      ),
    );
  }

  Widget _buildContent() {
    final displayData = currentClass ?? nextClass;
    final isCurrent = currentClass != null;

    return Stack(
      children: [
        // Subtle Refresh Icon (Top Right)
        Positioned(
          top: 0,
          right: 0,
          child: Transform.rotate(
            angle: refreshAngle,
            child: Icon(
              Icons.refresh,
              color: Colors.white.withOpacity(0.3),
              size: 40,
            ),
          ),
        ),
        // Central Content
        Center(
          child: currentClass == null && nextClass == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      color: Colors.white24,
                      size: 100, // Large for high-res
                    ),
                    const SizedBox(height: 25),
                    const Text(
                      'No classes scheduled',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 32, // Large font for 800x400
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
              : _buildMainContent(isCurrent, displayData!),
        ),
      ],
    );
  }

  Widget _buildMainContent(bool isCurrent, Map<String, dynamic> displayData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCurrent ? 'NOW' : 'NEXT UP',
                  style: TextStyle(
                    color: isCurrent
                        ? const Color(0xFFA7F3D0)
                        : const Color(0xFFBAE6FD),
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                  ),
                ),
                if (isCurrent && timeRemaining != null)
                  Text(
                    timeRemaining!,
                    style: const TextStyle(
                      color: Color(0xFF6EE7B7),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            // The Stack already handles the refresh icon position
          ],
        ),
        const SizedBox(height: 15),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isCurrent
                    ? const Color(0xFF10B981).withOpacity(0.2)
                    : const Color(0xFF0EA5E9).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                SubjectUtils.getSubjectIcon(displayData['subject']),
                color: isCurrent
                    ? const Color(0xFF6EE7B7)
                    : const Color(0xFF7DD3FC),
                size: 32,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayData['subject'] ?? 'Unknown',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const Spacer(),
        Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 14,
              color: Colors.white70,
            ),
            const SizedBox(width: 4),
            Text(
              '${displayData['room']}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const Spacer(),
            Text(
              '${displayData['startTime']}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
        if (isCurrent) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF34D399),
              ),
              minHeight: 3,
            ),
          ),
        ],
      ],
    );
  }
}

// --- NEW EMO ROBOT WIDGET (OLED STYLE) ---
enum RobotMood { happy, focused, waiting }

class SmallRobotWidget extends StatelessWidget {
  final Map<String, dynamic>? currentClass;
  final Map<String, dynamic>? nextClass;
  final double refreshAngle;

  const SmallRobotWidget({
    super.key,
    this.currentClass,
    this.nextClass,
    this.refreshAngle = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    RobotMood mood = RobotMood.happy;
    String status = "FREE";
    String info = "Enjoy!";
    Color themeColor = const Color(0xFF6EE7B7);

    if (currentClass != null) {
      mood = RobotMood.focused;
      status = "CLASS";
      info = currentClass!['subject'] ?? "Busy";
      themeColor = const Color(0xFFFCA5A5);
    } else if (nextClass != null) {
      mood = RobotMood.waiting;
      status = "NEXT";
      info = nextClass!['startTime'] ?? "Soon";
      themeColor = const Color(0xFF38BDF8);
    }

    return SizedBox(
      width: 400,
      height: 400,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(80),
        ),
        child: Stack(
          children: [
            // Subtle Refresh Icon (Transparent like Calendar)
            Positioned(
              top: 25,
              right: 25,
              child: Transform.rotate(
                angle: refreshAngle,
                child: Icon(
                  Icons.refresh,
                  color: Colors.white.withOpacity(0.3),
                  size: 30,
                ),
              ),
            ),
            // Face Content
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildOledEye(mood, themeColor, isLeft: true),
                      const SizedBox(width: 40),
                      _buildOledEye(mood, themeColor, isLeft: false),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Text(
                    status,
                    style: TextStyle(
                      color: themeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 32,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Text(
                      info,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOledEye(RobotMood mood, Color color, {required bool isLeft}) {
    return CustomPaint(
      size: const Size(100, 100), // Large eyes for high-res
      painter: RobotEyePainter(mood: mood, color: color, isLeft: isLeft),
    );
  }
}

class RobotEyePainter extends CustomPainter {
  final RobotMood mood;
  final Color color;
  final bool isLeft;

  RobotEyePainter({
    required this.mood,
    required this.color,
    required this.isLeft,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Draw Base Eye (Rounded Rect)
    final eyeRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(15),
    );

    // Create a path for the eye
    Path eyePath = Path()..addRRect(eyeRect);

    // Apply Mood Cuts (Eyelids)
    if (mood == RobotMood.happy) {
      // Cut from bottom (Happy arc)
      Path cutPath = Path()
        ..moveTo(-5, size.height)
        ..quadraticBezierTo(
          size.width / 2,
          size.height / 2,
          size.width + 5,
          size.height,
        )
        ..lineTo(size.width + 5, size.height + 10)
        ..lineTo(-5, size.height + 10)
        ..close();

      eyePath = Path.combine(PathOperation.difference, eyePath, cutPath);
    } else if (mood == RobotMood.focused) {
      // Sharp top cut (Determined/Focused)
      double cutHeight = size.height * 0.4;
      Path cutPath = Path();

      if (isLeft) {
        cutPath.moveTo(-5, -5);
        cutPath.lineTo(size.width + 5, -5);
        cutPath.lineTo(size.width + 5, cutHeight);
        cutPath.lineTo(-5, cutHeight * 0.7);
      } else {
        cutPath.moveTo(-5, -5);
        cutPath.lineTo(size.width + 5, -5);
        cutPath.lineTo(size.width + 5, cutHeight * 0.7);
        cutPath.lineTo(-5, cutHeight);
      }
      cutPath.close();

      eyePath = Path.combine(PathOperation.difference, eyePath, cutPath);
    } else if (mood == RobotMood.waiting) {
      // Tired/Waiting cut (Simple top straight cut)
      double cutHeight = size.height * 0.3;
      Path cutPath = Path()
        ..addRect(Rect.fromLTWH(-5, -5, size.width + 10, cutHeight + 5));

      eyePath = Path.combine(PathOperation.difference, eyePath, cutPath);
    }

    // Add Outer Glow (Subtle)
    canvas.drawPath(
      eyePath,
      Paint()
        ..color = color.withAlpha(77)
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8),
    );

    // Draw the final eye shape
    canvas.drawPath(eyePath, paint);
  }

  @override
  bool shouldRepaint(covariant RobotEyePainter oldDelegate) =>
      oldDelegate.mood != mood || oldDelegate.color != color;
}

class ErrorWidgetDisplay extends StatelessWidget {
  final bool small;
  const ErrorWidgetDisplay({super.key, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: small ? 160 : 320,
        height: 160,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.redAccent.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Colors.redAccent.withOpacity(0.8),
                size: small ? 24 : 32,
              ),
              const SizedBox(height: 12),
              Text(
                small
                    ? 'TAP TO RELOAD'
                    : 'Widget Sync Error\nTap to Reload App',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: small ? 10 : 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
