import 'dart:math';
import 'package:flutter/material.dart';

class ArduinoRobotEyes extends StatefulWidget {
  final bool enabled;
  final double size;

  const ArduinoRobotEyes({
    super.key,
    this.enabled = true,
    this.size = 200,
  });

  @override
  State<ArduinoRobotEyes> createState() => _ArduinoRobotEyesState();
}

class _ArduinoRobotEyesState extends State<ArduinoRobotEyes>
    with TickerProviderStateMixin {
  late AnimationController _frameController;
  late AnimationController _blinkController;
  
  // Eye geometry (matching Arduino code)
  double eyeLwidthDefault = 36;
  double eyeLheightDefault = 36;
  double eyeLwidthCurrent = 36;
  double eyeLheightCurrent = 1; // Start closed
  double eyeRwidthDefault = 36;
  double eyeRheightDefault = 36;
  double eyeRwidthCurrent = 36;
  double eyeRheightCurrent = 1; // Start closed
  
  double eyeLborderRadiusDefault = 8;
  double eyeRborderRadiusDefault = 8;
  double spaceBetweenDefault = 10;
  double spaceBetweenCurrent = 10;
  
  // Eye positions
  double eyeLx = 0;
  double eyeLy = 0;
  double eyeRx = 0;
  double eyeRy = 0;
  double eyeLxNext = 0;
  double eyeLyNext = 0;
  double eyeRxNext = 0;
  double eyeRyNext = 0;
  
  // Mood states
  bool tired = false;
  bool angry = false;
  bool happy = false;
  bool eyeL_open = true;
  bool eyeR_open = true;
  
  // Animation states
  bool autoblinker = true;
  bool idle = true;
  bool confused = false;
  bool laugh = false;
  bool sweat = false;
  
  // Timing variables (matching Arduino code)
  int blinkInterval = 3;
  int blinkIntervalVariation = 4;
  DateTime blinktimer = DateTime.now().add(const Duration(seconds: 3));
  
  int idleInterval = 2;
  int idleIntervalVariation = 3;
  DateTime idleAnimationTimer = DateTime.now().add(const Duration(seconds: 2));
  
  bool confusedToggle = true;
  int confusedAnimationDuration = 500;
  DateTime confusedAnimationTimer = DateTime.now();
  
  bool laughToggle = true;
  int laughAnimationDuration = 500;
  DateTime laughAnimationTimer = DateTime.now();
  
  // Flicker animations
  bool hFlicker = false;
  bool hFlickerAlternate = false;
  double hFlickerAmplitude = 2;
  
  bool vFlicker = false;
  bool vFlickerAlternate = false;
  double vFlickerAmplitude = 10;
  
  final Random _random = Random();
  
  @override
  void initState() {
    super.initState();
    
    // 50 FPS like Arduino (1000/50 = 20ms)
    _frameController = AnimationController(
      duration: const Duration(milliseconds: 20),
      vsync: this,
    )..repeat();
    
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _initializeEyePositions();
    _startAnimations();
  }

  void _initializeEyePositions() {
    final screenWidth = widget.size;
    final screenHeight = widget.size * 0.6;
    
    eyeLx = ((screenWidth) - (eyeLwidthDefault + spaceBetweenDefault + eyeRwidthCurrent)) / 2;
    eyeLy = ((screenHeight - eyeLheightDefault) / 2);
    eyeRx = eyeLx + eyeLwidthCurrent + spaceBetweenCurrent;
    eyeRy = eyeLy;
    
    eyeLxNext = eyeLx;
    eyeLyNext = eyeLy;
    eyeRxNext = eyeRx;
    eyeRyNext = eyeRy;
  }

  void _startAnimations() {
    if (!widget.enabled) return;
    
    // Start with eyes opening
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          eyeLheightCurrent = eyeLheightDefault;
          eyeRheightCurrent = eyeRheightDefault;
        });
      }
    });
    
    // Schedule mood changes
    _scheduleMoodChange();
  }

  void _scheduleMoodChange() {
    if (!widget.enabled) return;
    
    Future.delayed(Duration(seconds: 8 + _random.nextInt(10)), () {
      if (mounted && widget.enabled) {
        _changeMood();
        _scheduleMoodChange();
      }
    });
  }

  void _changeMood() {
    final moods = [0, 1, 2, 3]; // DEFAULT, TIRED, ANGRY, HAPPY
    final newMood = moods[_random.nextInt(moods.length)];
    
    switch (newMood) {
      case 1: // TIRED
        tired = true;
        angry = false;
        happy = false;
        break;
      case 2: // ANGRY
        tired = false;
        angry = true;
        happy = false;
        break;
      case 3: // HAPPY
        tired = false;
        angry = false;
        happy = true;
        break;
      default: // DEFAULT
        tired = false;
        angry = false;
        happy = false;
        break;
    }
    
    // Sometimes trigger confused or laugh animations
    if (_random.nextBool()) {
      _triggerConfused();
    } else if (_random.nextBool()) {
      _triggerLaugh();
    }
  }

  void _triggerConfused() {
    confused = true;
    confusedToggle = true;
    confusedAnimationTimer = DateTime.now();
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        confused = false;
      }
    });
  }

  void _triggerLaugh() {
    laugh = true;
    laughToggle = true;
    laughAnimationTimer = DateTime.now();
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        laugh = false;
      }
    });
  }

  void _updateFrame() {
    if (!widget.enabled) return;
    
    final now = DateTime.now();
    
    // Auto blink logic (matching Arduino code)
    if (autoblinker && now.isAfter(blinktimer)) {
      _blink();
      blinktimer = now.add(Duration(seconds: blinkInterval + _random.nextInt(blinkIntervalVariation)));
    }
    
    // Idle movement (matching Arduino code)
    if (idle && now.isAfter(idleAnimationTimer)) {
      _moveEyesRandomly();
      idleAnimationTimer = now.add(Duration(seconds: idleInterval + _random.nextInt(idleIntervalVariation)));
    }
    
    // Handle confused animation
    if (confused) {
      if (confusedToggle) {
        hFlicker = true;
        hFlickerAmplitude = 20;
        confusedToggle = false;
        confusedAnimationTimer = now;
      } else if (now.difference(confusedAnimationTimer).inMilliseconds >= confusedAnimationDuration) {
        hFlicker = false;
        confused = true;
        confusedToggle = true;
      }
    }
    
    // Handle laugh animation
    if (laugh) {
      if (laughToggle) {
        vFlicker = true;
        vFlickerAmplitude = 5;
        laughToggle = false;
        laughAnimationTimer = now;
      } else if (now.difference(laughAnimationTimer).inMilliseconds >= laughAnimationDuration) {
        vFlicker = false;
        laugh = true;
        laughToggle = true;
      }
    }
    
    // Smooth eye position transitions
    eyeLx = (eyeLx + eyeLxNext) / 2;
    eyeLy = (eyeLy + eyeLyNext) / 2;
    eyeRx = (eyeRx + eyeRxNext) / 2;
    eyeRy = (eyeRy + eyeRyNext) / 2;
    
    spaceBetweenCurrent = (spaceBetweenCurrent + spaceBetweenDefault) / 2;
    
    // Open eyes after closing
    if (eyeL_open && eyeLheightCurrent <= 1) {
      eyeLheightCurrent = eyeLheightDefault;
    }
    if (eyeR_open && eyeRheightCurrent <= 1) {
      eyeRheightCurrent = eyeRheightDefault;
    }
    
    // Apply flicker offsets
    if (hFlicker) {
      if (hFlickerAlternate) {
        eyeLx += hFlickerAmplitude;
        eyeRx += hFlickerAmplitude;
      } else {
        eyeLx -= hFlickerAmplitude;
        eyeRx -= hFlickerAmplitude;
      }
      hFlickerAlternate = !hFlickerAlternate;
    }
    
    if (vFlicker) {
      if (vFlickerAlternate) {
        eyeLy += vFlickerAmplitude;
        eyeRy += vFlickerAmplitude;
      } else {
        eyeLy -= vFlickerAmplitude;
        eyeRy -= vFlickerAmplitude;
      }
      vFlickerAlternate = !vFlickerAlternate;
    }
  }

  void _blink() {
    eyeLheightCurrent = 1;
    eyeRheightCurrent = 1;
    eyeL_open = false;
    eyeR_open = false;
    
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        eyeL_open = true;
        eyeR_open = true;
      }
    });
  }

  void _moveEyesRandomly() {
    final screenWidth = widget.size;
    final screenHeight = widget.size * 0.6;
    
    final maxX = screenWidth - eyeLwidthDefault - spaceBetweenDefault - eyeRwidthCurrent;
    final maxY = screenHeight - eyeLheightDefault;
    
    eyeLxNext = _random.nextDouble() * maxX;
    eyeLyNext = _random.nextDouble() * maxY;
  }

  @override
  void didUpdateWidget(ArduinoRobotEyes oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      if (widget.enabled) {
        _startAnimations();
      } else {
        _frameController.stop();
      }
    }
  }

  @override
  void dispose() {
    _frameController.dispose();
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _frameController,
      builder: (context, child) {
        _updateFrame();
        return CustomPaint(
          size: Size(widget.size, widget.size * 0.6),
          painter: ArduinoEyesPainter(
            eyeLx: eyeLx,
            eyeLy: eyeLy,
            eyeLwidth: eyeLwidthCurrent,
            eyeLheight: eyeLheightCurrent,
            eyeLborderRadius: eyeLborderRadiusDefault,
            eyeRx: eyeRx,
            eyeRy: eyeRy,
            eyeRwidth: eyeRwidthCurrent,
            eyeRheight: eyeRheightCurrent,
            eyeRborderRadius: eyeRborderRadiusDefault,
            tired: tired,
            angry: angry,
            happy: happy,
            screenWidth: widget.size,
            screenHeight: widget.size * 0.6,
          ),
        );
      },
    );
  }
}

class ArduinoEyesPainter extends CustomPainter {
  final double eyeLx, eyeLy, eyeLwidth, eyeLheight, eyeLborderRadius;
  final double eyeRx, eyeRy, eyeRwidth, eyeRheight, eyeRborderRadius;
  final bool tired, angry, happy;
  final double screenWidth, screenHeight;

  ArduinoEyesPainter({
    required this.eyeLx,
    required this.eyeLy,
    required this.eyeLwidth,
    required this.eyeLheight,
    required this.eyeLborderRadius,
    required this.eyeRx,
    required this.eyeRy,
    required this.eyeRwidth,
    required this.eyeRheight,
    required this.eyeRborderRadius,
    required this.tired,
    required this.angry,
    required this.happy,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Clear background (black like OLED)
    canvas.drawRect(Rect.fromLTWH(0, 0, screenWidth, screenHeight), Paint()..color = Colors.black);

    // Draw basic eye rectangles (matching Arduino code)
    final leftEyeRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(eyeLx, eyeLy, eyeLwidth, eyeLheight),
      Radius.circular(eyeLborderRadius),
    );
    canvas.drawRRect(leftEyeRect, paint);

    final rightEyeRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(eyeRx, eyeRy, eyeRwidth, eyeRheight),
      Radius.circular(eyeRborderRadius),
    );
    canvas.drawRRect(rightEyeRect, paint);

    // Draw mood features (matching Arduino code)
    _drawMoodFeatures(canvas, paint);
  }

  void _drawMoodFeatures(Canvas canvas, Paint paint) {
    // Draw tired top eyelids (matching Arduino code)
    if (tired) {
      final eyelidsHeight = eyeLheight / 2;
      final bgPaint = Paint()..color = Colors.black;
      
      // Left eye tired eyelid
      final leftEyelid = Path();
      leftEyelid.moveTo(eyeLx, eyeLy - 1);
      leftEyelid.lineTo(eyeLx + eyeLwidth, eyeLy - 1);
      leftEyelid.lineTo(eyeLx, eyeLy + eyelidsHeight - 1);
      leftEyelid.close();
      canvas.drawPath(leftEyelid, bgPaint);

      // Right eye tired eyelid
      final rightEyelid = Path();
      rightEyelid.moveTo(eyeRx, eyeRy - 1);
      rightEyelid.lineTo(eyeRx + eyeRwidth, eyeRy - 1);
      rightEyelid.lineTo(eyeRx + eyeRwidth, eyeRy + eyelidsHeight - 1);
      rightEyelid.close();
      canvas.drawPath(rightEyelid, bgPaint);
    }

    // Draw angry top eyelids (matching Arduino code)
    if (angry) {
      final eyelidsHeight = eyeLheight / 2;
      final bgPaint = Paint()..color = Colors.black;
      
      // Left eye angry eyelid
      final leftEyelid = Path();
      leftEyelid.moveTo(eyeLx, eyeLy - 1);
      leftEyelid.lineTo(eyeLx + eyeLwidth, eyeLy - 1);
      leftEyelid.lineTo(eyeLx + eyeLwidth, eyeLy + eyelidsHeight - 1);
      leftEyelid.close();
      canvas.drawPath(leftEyelid, bgPaint);

      // Right eye angry eyelid
      final rightEyelid = Path();
      rightEyelid.moveTo(eyeRx, eyeRy - 1);
      rightEyelid.lineTo(eyeRx + eyeRwidth, eyeRy - 1);
      rightEyelid.lineTo(eyeRx, eyeRy + eyelidsHeight - 1);
      rightEyelid.close();
      canvas.drawPath(rightEyelid, bgPaint);
    }

    // Draw happy bottom eyelids (matching Arduino code)
    if (happy) {
      final eyelidsBottomOffset = (eyeLheight / 2) + 3;
      final bgPaint = Paint()..color = Colors.black;
      
      // Left eye happy bottom eyelid
      final leftBottomEyelid = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          eyeLx - 1,
          (eyeLy + eyeLheight) - eyelidsBottomOffset + 1,
          eyeLwidth + 2,
          eyeLheight,
        ),
        Radius.circular(eyeLborderRadius),
      );
      canvas.drawRRect(leftBottomEyelid, bgPaint);

      // Right eye happy bottom eyelid
      final rightBottomEyelid = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          eyeRx - 1,
          (eyeRy + eyeRheight) - eyelidsBottomOffset + 1,
          eyeRwidth + 2,
          eyeLheight,
        ),
        Radius.circular(eyeRborderRadius),
      );
      canvas.drawRRect(rightBottomEyelid, bgPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ArduinoEyesPainter oldDelegate) {
    return oldDelegate.eyeLx != eyeLx ||
           oldDelegate.eyeLy != eyeLy ||
           oldDelegate.eyeLheight != eyeLheight ||
           oldDelegate.eyeRx != eyeRx ||
           oldDelegate.eyeRy != eyeRy ||
           oldDelegate.eyeRheight != eyeRheight ||
           oldDelegate.tired != tired ||
           oldDelegate.angry != angry ||
           oldDelegate.happy != happy;
  }
}
