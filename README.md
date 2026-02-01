# 🕰️ Class Now

**Elevate Your Academic Schedule Management**

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-039BE5?style=for-the-badge&logo=Firebase&logoColor=white)](https://firebase.google.com)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)

**Class Now** is a high-performance Flutter application designed to bridge the gap between students and mentors. It provides a real-time, synchronized timetable management experience powered by Firebase, ensuring that everyone is on the same page.

---

## ✨ Key Features

### 👨‍🏫 Dual Role Architecture
- **Mentor Mode:** Secure **Email & Password** authentication to manage schedules, post real-time announcements, and handle class deletions.
- **Student View:** A clean, focused interface for students to track their daily classes and receive instant updates anonymously.

### 📱 Intelligent Dashboard
- **Dynamic Day Selector:** Effortlessly navigate through the weekly schedule with a responsive UI.
- **Class Progress Tracking:** Visual cues like **opacity changes** and **line-through decorations** automatically mark completed classes based on the current time.
- **Announcement Hub:** A dedicated stream of updates to keep everyone informed in real-time.

### 🧩 Advanced Visuals & Integration
- **Retro OLED Display:** A custom-styled dashboard element showing "Live Now" and "Coming Up Next" classes in a classic digital format.
- **Arduino Robot Eyes:** Innovative mood-based animations (Happy, Angry, Tired, Confused) that respond dynamically, giving the app a unique personality.
- **Home Screen Widgets:** Stay updated with **Dynamic Timetable Widgets** directly on your Android home screen.

### 🔔 Smart Notifications
- **Lead-Time Alerts:** Automated reminders 15 minutes (configurable) before each class.
- **In-Class Status:** Persistent notifications that trigger automatically during class hours to keep you oriented.

### 📶 Offline First Design
- **Robust Caching:** Powered by **SharedPreferences**, the app caches your entire timetable locally.
- **Seamless Sync:** Automatically refreshes and updates local data whenever you come back online, ensuring the timetable is always accessible.

---

## 🛠️ Tech Stack

- **Framework:** [Flutter](https://flutter.dev)
- **Backend:** [Cloud Firestore](https://firebase.google.com/docs/firestore) & [Cloud Functions](https://firebase.google.com/docs/functions)
- **State Management:** [Provider](https://pub.dev/packages/provider) & Streams
- **Local Storage:** [Shared Preferences](https://pub.dev/packages/shared_preferences)
- **UI & Animations:** [Google Fonts](https://fonts.google.com/specimen/Inter), [Shimmer](https://pub.dev/packages/shimmer), and Custom Shaders.

---

## 🚀 Getting Started

### Installation
1. **Clone the Repository:**
   ```bash
   git clone https://github.com/shantoshdurai/Timewise-app.git
   ```
2. **Install Dependencies:**
   ```bash
   flutter pub get
   ```
3. **Firebase Configuration:**
   - Add your `google-services.json` to `android/app/`.
   - Enable Email/Password Authentication in the Firebase Console.
4. **Run the App:**
   ```bash
   flutter run
   ```

---

## 📸 Preview

| Dashboard | Mentor Mode | Announcements |
| :---: | :---: | :---: |
| <img src="screenshots/dashboard.jpeg" width="200"> | <img src="screenshots/mentor.jpeg" width="200"> | <img src="screenshots/announcements.png" width="200"> |

---

## 🤝 Contributing
Contributions are what make the open-source community such an amazing place to learn, inspire, and create.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📝 License
Distributed under the MIT License. See `LICENSE` for more information.

---

*Built with ❤️ for better academic productivity.*
