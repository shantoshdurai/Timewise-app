import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:workmanager/workmanager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_firebase_test/main.dart';
import 'package:flutter_firebase_test/notification_service.dart';
import 'package:flutter_firebase_test/widget_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Setup animations
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Start initialization
    _initializeApp();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    // Minimal delay - just enough for animation to show
    final minDelay = Future.delayed(const Duration(milliseconds: 400));

    try {
      // 1. Initialize Firebase core FIRST (required for everything else)
      await Firebase.initializeApp();

      // 2. Setup Firestore settings immediately
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
      );

      // 3. Run remaining init tasks in parallel (these don't block each other)
      await Future.wait([
        _initNotifications(),
        _initWidgetService(),
        _initAuth(),
      ]);

      // 4. Defer Workmanager to after splash (non-critical)
      _deferredWorkmanagerInit();
    } catch (e) {
      print('Error during initialization: $e');
      // Continue anyway - app might work in offline mode
    }

    // Wait for minimum animation time
    await minDelay;

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const AppLauncher(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 200),
        ),
      );
    }
  }

  Future<void> _initNotifications() async {
    try {
      await NotificationService.init();
    } catch (e) {
      print('Notification init failed: $e');
    }
  }

  Future<void> _initWidgetService() async {
    try {
      await WidgetService.initialize();
    } catch (e) {
      print('Widget service init failed: $e');
    }
  }

  Future<void> _initAuth() async {
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
    } catch (e) {
      print('Auth init failed: $e');
    }
  }

  void _deferredWorkmanagerInit() {
    // Initialize Workmanager after app is running (non-blocking)
    Future.microtask(() async {
      try {
        await Workmanager().initialize(
          callbackDispatcher,
          isInDebugMode: false,
        );
      } catch (e) {
        print('Workmanager init failed: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Cute animated logo
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_stories_rounded,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Animated Text
            FadeTransition(
              opacity: _fadeAnimation, // Fade text in
              child: Column(
                children: [
                  Text(
                    'Class Now',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Getting everything ready...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
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
}
