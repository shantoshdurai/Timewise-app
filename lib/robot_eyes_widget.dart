import 'dart:math';
import 'package:flutter/material.dart';

class RobotEyesWidget extends StatefulWidget {
  final bool enabled;
  final double size;

  const RobotEyesWidget({
    super.key,
    this.enabled = true,
    this.size = 120,
  });

  @override
  State<RobotEyesWidget> createState() => _RobotEyesWidgetState();
}

class _RobotEyesWidgetState extends State<RobotEyesWidget>
    with TickerProviderStateMixin {
  late AnimationController _blinkController;
  late AnimationController _moveController;
  late AnimationController _moodController;
  
  late Animation<double> _blinkAnimation;
  late Animation<Offset> _moveAnimation;
  late Animation<double> _moodAnimation;
  
  Offset _leftEyePosition = const Offset(-0.3, 0.0);
  Offset _rightEyePosition = const Offset(0.3, 0.0);
  double _leftEyeHeight = 1.0;
  double _rightEyeHeight = 1.0;
  
  EyeMood _currentMood = EyeMood.normal;
  final Random _random = Random();
  
  DateTime _nextBlinkTime = DateTime.now().add(const Duration(seconds: 3));
  DateTime _nextMoveTime = DateTime.now().add(const Duration(seconds: 2));
  DateTime _nextMoodChange = DateTime.now().add(const Duration(seconds: 8));

  @override
  void initState() {
    super.initState();
    
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _moveController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _moodController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _blinkAnimation = Tween<double>(
      begin: 1.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _blinkController,
      curve: Curves.easeInOut,
    ));
    
    _moveAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _moveController,
      curve: Curves.easeInOutBack,
    ));
    
    _moodAnimation = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _moodController,
      curve: Curves.easeInOut,
    ));
    
    _startAnimations();
  }

  void _startAnimations() {
    if (!widget.enabled) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleNextBlink();
      _scheduleNextMove();
      _scheduleNextMoodChange();
    });
  }

  void _scheduleNextBlink() {
    if (!widget.enabled) return;
    
    final now = DateTime.now();
    if (now.isAfter(_nextBlinkTime)) {
      _blink();
      _nextBlinkTime = now.add(Duration(seconds: 2 + _random.nextInt(4)));
    }
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _scheduleNextBlink();
    });
  }

  void _scheduleNextMove() {
    if (!widget.enabled) return;
    
    final now = DateTime.now();
    if (now.isAfter(_nextMoveTime)) {
      _moveEyes();
      _nextMoveTime = now.add(Duration(seconds: 1 + _random.nextInt(3)));
    }
    
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _scheduleNextMove();
    });
  }

  void _scheduleNextMoodChange() {
    if (!widget.enabled) return;
    
    final now = DateTime.now();
    if (now.isAfter(_nextMoodChange)) {
      _changeMood();
      _nextMoodChange = now.add(Duration(seconds: 5 + _random.nextInt(10)));
    }
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _scheduleNextMoodChange();
    });
  }

  void _blink() {
    if (!widget.enabled) return;
    
    _blinkController.forward().then((_) {
      _blinkController.reverse();
    });
  }

  void _moveEyes() {
    if (!widget.enabled) return;
    
    final directions = [
      const Offset(-0.4, -0.3), // Top-left
      const Offset(0.0, -0.4),  // Top-center
      const Offset(0.4, -0.3), // Top-right
      const Offset(-0.4, 0.0),  // Left
      const Offset(0.0, 0.0),   // Center
      const Offset(0.4, 0.0),   // Right
      const Offset(-0.4, 0.3),  // Bottom-left
      const Offset(0.0, 0.4),   // Bottom-center
      const Offset(0.4, 0.3),   // Bottom-right
    ];
    
    final newDirection = directions[_random.nextInt(directions.length)];
    
    _moveAnimation = Tween<Offset>(
      begin: _moveAnimation.value,
      end: newDirection,
    ).animate(CurvedAnimation(
      parent: _moveController,
      curve: Curves.easeInOutBack,
    ));
    
    _moveController.forward().then((_) {
      _moveController.reset();
    });
  }

  void _changeMood() {
    if (!widget.enabled) return;
    
    final moods = EyeMood.values;
    final newMood = moods[_random.nextInt(moods.length)];
    
    if (newMood != _currentMood) {
      setState(() {
        _currentMood = newMood;
      });
      
      _moodAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _moodController,
        curve: Curves.easeInOut,
      ));
      
      _moodController.forward().then((_) {
        _moodController.reverse();
      });
    }
  }

  @override
  void didUpdateWidget(RobotEyesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      if (widget.enabled) {
        _startAnimations();
      } else {
        _blinkController.stop();
        _moveController.stop();
        _moodController.stop();
      }
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _moveController.dispose();
    _moodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: widget.size,
      height: widget.size * 0.6,
      child: AnimatedBuilder(
        animation: Listenable.merge([_blinkAnimation, _moveAnimation, _moodAnimation]),
        builder: (context, child) {
          return CustomPaint(
            painter: RobotEyesPainter(
              blinkProgress: _blinkAnimation.value,
              moveOffset: _moveAnimation.value,
              moodProgress: _moodAnimation.value,
              mood: _currentMood,
              eyeSize: widget.size * 0.25,
            ),
          );
        },
      ),
    );
  }
}

enum EyeMood {
  normal,
  happy,
  tired,
  angry,
  curious,
}

class RobotEyesPainter extends CustomPainter {
  final double blinkProgress;
  final Offset moveOffset;
  final double moodProgress;
  final EyeMood mood;
  final double eyeSize;

  RobotEyesPainter({
    required this.blinkProgress,
    required this.moveOffset,
    required this.moodProgress,
    required this.mood,
    required this.eyeSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.shade700
      ..style = PaintingStyle.fill;

    final eyeWidth = eyeSize;
    final eyeHeight = eyeSize * blinkProgress;
    final spacing = eyeSize * 0.3;
    
    // Calculate eye positions
    final leftEyeX = size.width / 2 - spacing - eyeWidth / 2 + moveOffset.dx * 20;
    final rightEyeX = size.width / 2 + spacing - eyeWidth / 2 + moveOffset.dx * 20;
    final eyeY = size.height / 2 - eyeHeight / 2 + moveOffset.dy * 15;

    // Apply mood transformations
    final adjustedLeftEyeHeight = _getMoodAdjustedHeight(eyeHeight, true);
    final adjustedRightEyeHeight = _getMoodAdjustedHeight(eyeHeight, false);

    // Draw left eye
    _drawEye(canvas, Rect.fromLTWH(leftEyeX, eyeY, eyeWidth, adjustedLeftEyeHeight), paint, true);
    
    // Draw right eye
    _drawEye(canvas, Rect.fromLTWH(rightEyeX, eyeY, eyeWidth, adjustedRightEyeHeight), paint, false);

    // Draw mood-specific features
    _drawMoodFeatures(canvas, size, paint);
  }

  double _getMoodAdjustedHeight(double baseHeight, bool isLeftEye) {
    switch (mood) {
      case EyeMood.happy:
        return baseHeight + (moodProgress * baseHeight * 0.2);
      case EyeMood.tired:
        return baseHeight * (1 - moodProgress * 0.5);
      case EyeMood.angry:
        return baseHeight * (1 - moodProgress * 0.3);
      case EyeMood.curious:
        return baseHeight + (moodProgress * baseHeight * 0.4);
      default:
        return baseHeight;
    }
  }

  void _drawEye(Canvas canvas, Rect eyeRect, Paint paint, bool isLeftEye) {
    // Main eye shape
    final radius = Radius.circular(eyeRect.width * 0.3);
    canvas.drawRRect(RRect.fromRectAndRadius(eyeRect, radius), paint);

    // Draw pupils
    if (blinkProgress > 0.3) {
      final pupilPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.fill;

      final pupilSize = eyeRect.width * 0.3 * blinkProgress;
      final pupilCenter = Offset(
        eyeRect.center.dx + moveOffset.dx * 10,
        eyeRect.center.dy + moveOffset.dy * 8,
      );

      canvas.drawCircle(pupilCenter, pupilSize, pupilPaint);

      // Add shine effect
      final shinePaint = Paint()
        ..color = Colors.white.withOpacity(0.7)
        ..style = PaintingStyle.fill;

      final shineSize = pupilSize * 0.3;
      final shineOffset = Offset(pupilSize * 0.3, -pupilSize * 0.3);
      canvas.drawCircle(pupilCenter + shineOffset, shineSize, shinePaint);
    }
  }

  void _drawMoodFeatures(Canvas canvas, Size size, Paint paint) {
    switch (mood) {
      case EyeMood.happy:
        _drawHappyFeatures(canvas, size, paint);
        break;
      case EyeMood.tired:
        _drawTiredFeatures(canvas, size, paint);
        break;
      case EyeMood.angry:
        _drawAngryFeatures(canvas, size, paint);
        break;
      case EyeMood.curious:
        _drawCuriousFeatures(canvas, size, paint);
        break;
      default:
        break;
    }
  }

  void _drawHappyFeatures(Canvas canvas, Size size, Paint paint) {
    final mouthPaint = Paint()
      ..color = Colors.blue.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final mouthY = size.height * 0.75;
    final mouthWidth = size.width * 0.3;
    
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width / 2, mouthY),
        width: mouthWidth,
        height: mouthWidth * 0.6,
      ),
      0,
      pi,
      false,
      mouthPaint,
    );
  }

  void _drawTiredFeatures(Canvas canvas, Size size, Paint paint) {
    final eyePaint = Paint()
      ..color = Colors.blue.shade700.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // Draw tired eyelids
    final eyeWidth = eyeSize;
    final spacing = eyeSize * 0.3;
    final lidHeight = eyeSize * 0.2 * moodProgress;
    
    final leftLidX = size.width / 2 - spacing - eyeWidth / 2 + moveOffset.dx * 20;
    final rightLidX = size.width / 2 + spacing - eyeWidth / 2 + moveOffset.dx * 20;
    final lidY = size.height / 2 - eyeSize / 2 + moveOffset.dy * 15;

    canvas.drawRect(Rect.fromLTWH(leftLidX, lidY, eyeWidth, lidHeight), eyePaint);
    canvas.drawRect(Rect.fromLTWH(rightLidX, lidY, eyeWidth, lidHeight), eyePaint);
  }

  void _drawAngryFeatures(Canvas canvas, Size size, Paint paint) {
    final browPaint = Paint()
      ..color = Colors.blue.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final eyeWidth = eyeSize;
    final spacing = eyeSize * 0.3;
    final browAngle = 0.3 * moodProgress;
    
    final leftBrowX = size.width / 2 - spacing - eyeWidth / 2 + moveOffset.dx * 20;
    final rightBrowX = size.width / 2 + spacing - eyeWidth / 2 + moveOffset.dx * 20;
    final browY = size.height / 2 - eyeSize / 2 + moveOffset.dy * 15 - 10;

    // Left angry brow
    canvas.drawLine(
      Offset(leftBrowX - 5, browY),
      Offset(leftBrowX + eyeWidth + 5, browY + eyeWidth * browAngle),
      browPaint,
    );

    // Right angry brow
    canvas.drawLine(
      Offset(rightBrowX - 5, browY + eyeWidth * browAngle),
      Offset(rightBrowX + eyeWidth + 5, browY),
      browPaint,
    );
  }

  void _drawCuriousFeatures(Canvas canvas, Size size, Paint paint) {
    final questionPaint = Paint()
      ..color = Colors.blue.shade700.withOpacity(0.5 * moodProgress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final questionX = size.width * 0.85;
    final questionY = size.height * 0.3;

    // Draw question mark
    canvas.drawCircle(Offset(questionX, questionY), 3, questionPaint);
    canvas.drawPath(
      Path()
        ..moveTo(questionX, questionY + 3)
        ..quadraticBezierTo(
          questionX - 5, questionY + 10,
          questionX, questionY + 15,
        )
        ..moveTo(questionX, questionY + 20)
        ..lineTo(questionX, questionY + 22),
      questionPaint,
    );
  }

  @override
  bool shouldRepaint(covariant RobotEyesPainter oldDelegate) {
    return oldDelegate.blinkProgress != blinkProgress ||
           oldDelegate.moveOffset != moveOffset ||
           oldDelegate.moodProgress != moodProgress ||
           oldDelegate.mood != mood;
  }
}
