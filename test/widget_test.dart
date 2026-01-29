import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_firebase_test/main.dart';
import 'package:mockito/mockito.dart';

// Mock the FirebaseCorePlatform implementation
class MockFirebaseCorePlatform extends Mock implements FirebaseCorePlatform {
  @override
  Future<FirebaseApp> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    return MockFirebaseApp();
  }
}

class MockFirebaseApp extends Mock implements FirebaseApp {
  @override
  String get name => '[DEFAULT]';
}


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Firebase.delegatePackingProperty = true;
  FirebasePlatform.instance = MockFirebaseCorePlatform();


  testWidgets('TimetableApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TimetableApp());

    // Verify that our app shows the material app.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
