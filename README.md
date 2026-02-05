# ⏰ Class Now - Premium University Companion

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-039BE5?style=for-the-badge&logo=Firebase&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![DSU](https://img.shields.io/badge/University-DSU-gold?style=for-the-badge)

**A high-performance timetable management app with advanced glassmorphism aesthetics and official DSU branding.**

[Features](#-features) • [Screenshots](#-screenshots) • [Tech Stack](#-tech-stack) • [Installation](#-installation) • [Usage](#-usage)

</div>

---

## ✨ Features

### 🏛️ **University Branding (DSU Edition)**
- **Premium DSU Glow** - Dedicated setup page featuring a high-fidelity, shimmering DSU university logo.
- **Syncing Animations** - Interactive pulse and shine effects that provide visual feedback during data synchronization.
- **Official Identity** - Tailored specifically for Dhanalakshmi Srinivasan University students and faculty.

### 🎨 **Modern Glassmorphism UI**
- **Frosted Glass Effects** - High-fidelity blur and depth-based UI components.
- **Dynamic Color System** - Curated vibrant palette designed for maximum legibility in both light and dark modes.
- **True OLED Black Theme** - Optimized for power saving and high contrast.
- **Interactive Micro-animations** - Fluid transitions and real-time visual feedback using `flutter_animate`.

### 📅 **Intelligent Scheduling**
- **Live Tracking** - Real-time categorization into current, upcoming, and completed sessions.
- **Progress Monitoring** - High-resolution visual progress indicators for active classes.
- **Universal Pull-to-Refresh** - Seamless synchronization gesture that works across all schedule states.
- **Offline Reliability** - Persistent local caching ensures access to timetable data even without connectivity.

### 🏠 **High-Fidelity Home Screen Widgets**
- **High-Resolution Rendering** - Widgets are drawn at double logical resolution for edge-to-edge sharpness.
- **Ambient Glass Design** - Transparent frosted backgrounds that blend natively with any device wallpaper.
- **Visual Sync Confirmation** - Interactive refresh logic where the sync icon rotates on every update.

### 🔔 **Precision Notification System**
- **Predictive Alerts** - Get notified before class starts with customizable lead times.
- **Smart Filtering** - Granular control over notification triggers based on subject or availability.
- **Notification Diagnostics** - Integrated testing suite to verify system-level permissions.

---

## 🛠️ Tech Stack

### **Core Framework**
- **Flutter 3.x** - High-performance cross-platform development.
- **Dart 3.x** - Optimized, type-safe application logic.
- **Flutter Animate** - Powerful, sequence-based animations for a "premium" feel.

### **Backend Architecture**
- **Firebase Firestore** - Real-time NoSQL data synchronization.
- **Firebase Auth** - Multi-provider authentication management (Anonymous & Email).
- **Cloud Functions** - Serverless logic for hardware integration.

---

## 🚀 Installation

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Firebase Project Reference
- Android Studio / VS Code

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone https://github.com/shantoshdurai/Timewise-app.git
   cd Timewise-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration**
   - Place your `google-services.json` in `android/app/`.
   - Enable **Anonymous** and **Email/Password** providers in Firebase Console.

4. **Run Development Mode**
   ```bash
   flutter run
   ```

---

## 🏗️ Project Architecture

```
lib/
├── main.dart                      # Core app initialization
├── app_theme.dart                 # Design system & color tokens
├── notification_service.dart      # Precision scheduling engine
├── widget_service.dart            # High-res widget rendering engine
├── onboarding_screen.dart         # DSU Branded Onboarding logic
└── widgets/
    └── glass_widgets.dart         # Reusable glassmorphism components
```

---

## 📄 License

Licensed under the MIT License.

---

## 📞 Contact & Support

- **Developer:** Shantosh Durai
- **GitHub:** [@shantoshdurai](https://github.com/shantoshdurai)

<div align="center">

### Built for performance. Designed for DSU.

**Star ⭐ this repo if you support modern open-source education tools!**

</div>
