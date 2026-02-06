# Class Now - Smart Timetable App 📱

A professional, offline-first timetable application built with Flutter & Firebase.

## 🚀 Key Features

*   **Real-time Dashboard:** Auto-detects current and next class.
*   **Smart Widgets:**
    *   `TimetableWidgetProvider` (4x2): Detailed schedule view.
    *   `RobotWidgetProvider` (2x2): Minimalist OLED status.
    *   **Note:** Widgets update automatically via `WorkManager` (every 15-30m) or manual tap.
*   **Intelligent Notifications:** Local alarms scheduled 5-30 minutes before class (customizable).
*   **OLED Dark Mode:** Pure black UI with custom gradient background support.
*   **🤖 AI Assistant (Class Now Bot):**
    *   Powered by Google's **Gemma 3 27B** model.
    *   **Context-Aware:** Knows your schedule, room numbers, and timings.
    *   **Smart Interactions:** Ask "What's my next class?", "Where is room 704?", or just chat!
    *   **Features:** Direct API Integration (No package bloat) & Long-press to copy responses.

---

## 🛠️ Project Setup Instructions

### 1. Prerequisites
*   Flutter SDK (3.10+)
*   Android Studio
*   Firebase Project

### 2. Installation
```bash
# Clone the repository
git clone https://github.com/shantoshdurai/Timewise-app.git
cd flutter_firebase_test

# Install dependencies
flutter pub get
```

### 3. CRITICAL: Firebase Configuration
⚠️ **The app will CRASH on launch without this file.** ⚠️

You must provide your own `google-services.json` file.
1.  Go to [Firebase Console](https://console.firebase.google.com).
2.  Select your project -> Project Settings.
3.  Add Android App: `com.example.flutter_firebase_test`.
4.  Download `google-services.json`.
5.  Place it in: `android/app/google-services.json`.

---

## 🆘 Troubleshooting & Data Recovery (Read This)

### "I messed up the database/data is gone"
If the app shows "No classes scheduled" incorrectly:

1.  **Check Firestore:** Go to Firebase Console -> Firestore Database.
2.  **Verify Path:** Data should be at `departments/{deptId}/years/{yearId}/sections/{sectionId}/schedule`.
3.  **Emergency Restore:**
    *   If you have the Excel backup of the schedule:
    *   Run the restore script (if configured) or manually import the JSON.
    *   *Tip:* Always keep a local `.csv` copy of the timetable.

### "Widgets aren't updating"
*   **Android Battery Optimization:** On Xiaomi/Oppo/Vivo, go to App Info -> Battery Saver -> No Restrictions.
*   **Auto-Start:** Enable "Autostart".
*   **Logs:** Run `flutter run` and check the console for `[WidgetService]` logs.

### "App crashes immediately"
*   99% chance `google-services.json` is missing or invalid.
*   Run `flutter clean` and rebuild.

---

## 📂 Key Files for Maintenance
*   `lib/widget_service.dart`: Logic for home screen widgets.
*   `lib/notification_service.dart`: Notification scheduling logic.
*   `lib/main.dart`: App entry point & Theme logic.
*   `android/app/src/main/AndroidManifest.xml`: Permissions & Receivers.
