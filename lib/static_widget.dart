import 'package:flutter/material.dart';


// --- EXISTING LARGE WIDGET ---
class StaticTimetableWidget extends StatelessWidget {
  final Map<String, dynamic>? currentClass;
  final Map<String, dynamic>? nextClass;
  final String? timeRemaining;
  final double progress;

  const StaticTimetableWidget({
    super.key,
    this.currentClass,
    this.nextClass,
    this.timeRemaining,
    this.progress = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24, width: 0.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (currentClass == null && nextClass == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, color: Colors.white54, size: 32),
            SizedBox(height: 8),
            Text(
              'No classes scheduled',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      );
    }

    final displayData = currentClass ?? nextClass!;
    final isCurrent = currentClass != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isCurrent ? 'NOW' : 'NEXT UP',
              style: TextStyle(
                color: isCurrent ? const Color(0xFFA7F3D0) : const Color(0xFFBAE6FD),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            if (isCurrent && timeRemaining != null)
              Text(
                timeRemaining!,
                style: const TextStyle(
                  color: Color(0xFF6EE7B7),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          displayData['subject'] ?? 'Unknown',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            height: 1.1,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const Spacer(),
        Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 14, color: Colors.white70),
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
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF34D399)),
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
  
  const SmallRobotWidget({
    super.key,
    this.currentClass,
    this.nextClass,
  });

  @override
  Widget build(BuildContext context) {
    RobotMood mood = RobotMood.happy;
    String status = "FREE";
    String info = "Enjoy!";
    Color themeColor = const Color(0xFF6EE7B7); // Happy Green

    if (currentClass != null) {
      mood = RobotMood.focused;
      status = "CLASS";
      info = currentClass!['subject'] ?? "Busy";
      themeColor = const Color(0xFFFCA5A5); // Focused Red/Soft Pink
    } else if (nextClass != null) {
      mood = RobotMood.waiting;
      status = "NEXT";
      info = nextClass!['startTime'] ?? "Soon";
      themeColor = const Color(0xFF38BDF8); // Waiting Blue
    }

    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: Colors.black, // True OLED Black
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          // Background Glow
          Center(
            child: Container(
              width: 120,
              height: 60,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withAlpha(26),
                    blurRadius: 40,
                    spreadRadius: 10,
                  )
                ],
              ),
            ),
          ),
          // Face Content
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // OLED Eyes
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildOledEye(mood, themeColor, isLeft: true),
                    const SizedBox(width: 20),
                    _buildOledEye(mood, themeColor, isLeft: false),
                  ],
                ),
                const SizedBox(height: 15),
                // Status Text
                Text(
                  status,
                  style: TextStyle(
                    color: themeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    info,
                    style: TextStyle(
                      color: Colors.white.withAlpha(102),
                      fontSize: 11,
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
    );
  }

  Widget _buildOledEye(RobotMood mood, Color color, {required bool isLeft}) {
    return CustomPaint(
      size: const Size(45, 45),
      painter: RobotEyePainter(mood: mood, color: color, isLeft: isLeft),
    );
  }
}

class RobotEyePainter extends CustomPainter {
  final RobotMood mood;
  final Color color;
  final bool isLeft;

  RobotEyePainter({required this.mood, required this.color, required this.isLeft});

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
          size.width / 2, size.height / 2, 
          size.width + 5, size.height
        )
        ..lineTo(size.width + 5, size.height + 10)
        ..lineTo(-5, size.height + 10)
        ..close();
      
      eyePath = Path.combine(PathOperation.difference, eyePath, cutPath);
    } 
    else if (mood == RobotMood.focused) {
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
    }
    else if (mood == RobotMood.waiting) {
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
