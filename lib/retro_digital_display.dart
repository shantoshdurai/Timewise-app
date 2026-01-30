import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RetroDigitalDisplay extends StatefulWidget {
  final bool enabled;
  final String? currentClass;
  final String? nextClass;
  final String? currentEndTime;
  final String? nextStartTime;
  final String? room;

  const RetroDigitalDisplay({
    super.key,
    this.enabled = true,
    this.currentClass,
    this.nextClass,
    this.currentEndTime,
    this.nextStartTime,
    this.room,
  });

  @override
  State<RetroDigitalDisplay> createState() => _RetroDigitalDisplayState();
}

class _RetroDigitalDisplayState extends State<RetroDigitalDisplay>
    with TickerProviderStateMixin {
  late AnimationController _titleController;
  late AnimationController _scanlineController;
  late AnimationController _glitchController;
  late Animation<int> _titleAnimation;
  late Animation<double> _scanlineAnimation;
  late Animation<double> _glitchAnimation;
  
  final Random _random = Random();
  String _currentTime = '';
  String _statusMessage = '';
  bool _showCursor = true;
  String _titleText = 'CLASS TRACKER v1.0';
  int _titleIndex = 0;

  @override
  void initState() {
    super.initState();
    
    _titleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
    
    _scanlineController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    _glitchController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    
    _titleAnimation = IntTween(begin: 0, end: _titleText.length).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.linear),
    );
    
    _scanlineAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_scanlineController);
    
    _glitchAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_glitchController);
    
    _updateTime();
    _updateStatusMessage();
    
    // Update time every second
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) _updateTime();
    });
    
    // Update status message every 5 seconds
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) _updateStatusMessage();
    });
    
    // Cursor blink
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          _showCursor = !_showCursor;
        });
      }
    });
    
    // Random glitch effect
    Timer.periodic(const Duration(seconds: 8), (timer) {
      if (mounted && _random.nextDouble() < 0.3) {
        _triggerGlitch();
      }
    });
  }

  void _triggerGlitch() {
    _glitchController.forward().then((_) {
      _glitchController.reset();
    });
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = DateFormat('HH:mm:ss').format(now);
    });
  }

  void _updateStatusMessage() {
    final messages = [
      'SYSTEM ONLINE',
      'MONITORING SCHEDULE',
      'SCANNING CLASSES',
      'TRACKING TIME',
      'CLASS MODE ACTIVE',
    ];
    
    setState(() {
      _statusMessage = messages[_random.nextInt(messages.length)];
    });
  }

  String _formatClassInfo() {
    if (widget.currentClass != null) {
      final timeLeft = _calculateTimeLeft(widget.currentEndTime);
      return 'CLASS: ${widget.currentClass?.toUpperCase()}';
    } else if (widget.nextClass != null) {
      return 'NEXT: ${widget.nextClass?.toUpperCase()}';
    } else {
      return 'NO CLASSES TODAY';
    }
  }

  String _formatTimeInfo() {
    if (widget.currentClass != null) {
      final timeLeft = _calculateTimeLeft(widget.currentEndTime);
      return 'ENDS IN: $timeLeft';
    } else if (widget.nextClass != null) {
      return 'STARTS: ${widget.nextStartTime}';
    } else {
      return 'SYSTEM IDLE';
    }
  }

  String _calculateTimeLeft(String? endTime) {
    if (endTime == null) return 'UNKNOWN';
    
    try {
      final now = DateTime.now();
      final end = DateFormat('HH:mm').parse(endTime);
      final endDateTime = DateTime(
        now.year, now.month, now.day,
        end.hour, end.minute,
      );
      
      final difference = endDateTime.difference(now);
      if (difference.isNegative) return 'ENDED';
      
      final minutes = difference.inMinutes;
      final seconds = difference.inSeconds % 60;
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'ERROR';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _scanlineController.dispose();
    _glitchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: const Color(0xFF333333),
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          // Scanline effect
          AnimatedBuilder(
            animation: _scanlineAnimation,
            builder: (context, child) {
              return Positioned(
                top: _scanlineAnimation.value * 120,
                left: 0,
                right: 0,
                height: 2,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.green.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Glitch effect
          AnimatedBuilder(
            animation: _glitchAnimation,
            builder: (context, child) {
              if (_glitchAnimation.value > 0) {
                return Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(_glitchAnimation.value * 0.1),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          
          // Main content
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top status bar with animated title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AnimatedBuilder(
                      animation: _titleAnimation,
                      builder: (context, child) {
                        final displayText = _titleText.substring(0, _titleAnimation.value);
                        return _buildPixelText(displayText, 8);
                      },
                    ),
                    _buildPixelText(_currentTime, 8),
                  ],
                ),
                const SizedBox(height: 4),
                
                // Main class info
                _buildPixelText(_formatClassInfo(), 12),
                const SizedBox(height: 2),
                
                // Time info
                _buildPixelText(_formatTimeInfo(), 10),
                
                const Spacer(),
                
                // Bottom status bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPixelText(_statusMessage, 8),
                    _buildPixelText('ROOM: ${widget.room ?? 'N/A'}', 8),
                  ],
                ),
                const SizedBox(height: 2),
                
                // Cursor
                Row(
                  children: [
                    _buildPixelText('READY${_showCursor ? '_' : ' '}', 8),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPixelText(String text, double fontSize) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.green,
        fontSize: fontSize,
        fontFamily: 'monospace',
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }
}
