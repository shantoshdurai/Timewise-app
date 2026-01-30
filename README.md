# 🕰️ Class Now

**Elevate Your Academic Schedule Management**

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-039BE5?style=for-the-badge&logo=Firebase&logoColor=white)](https://firebase.google.com)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)

**Class Now** is a high-performance Flutter application designed to bridge the gap between students and mentors. It provides a real-time, synchronized timetable management experience powered by Firebase, ensuring that everyone is on the same page, at the same time.

---

## ✨ Key Features

### 👨‍🏫 Dual Role Architecture
- **Mentor Mode:** Password-protected access (via PIN) to manage schedules, import bulk data, and post real-time announcements.
- **Student View:** A clean, focused interface for students to track their daily classes and receive instant updates.

### 📱 Intelligent Dashboard
- **Dynamic Day Selector:** Easily navigate through the weekly schedule with a smooth, responsive UI.
- **Class Progress Tracking:** Visual cues (opacity changes and strikethroughs) automatically mark completed classes based on the current time.
- **Announcement Hub:** A dedicated stream of updates with unread counters to keep everyone informed.

### 🧩 Home Screen Widgets
- Stay updated without even opening the app. Includes **Dynamic Timetable Widgets** and a unique **Robot Status Widget** for quick schedule glances.

### 🔔 Smart Notifications
- Automated reminders for upcoming classes to ensure punctuality (Toggleable via settings).

---

## 🛠️ Tech Stack

- **Framework:** [Flutter](https://flutter.dev)
- **Backend:** [Cloud Firestore](https://firebase.google.com/docs/firestore) (NoSQL Database)
- **Local Storage:** [Shared Preferences](https://pub.dev/packages/shared_preferences)
- **State Management:** Stateful Widgets & Streams
- **Deep Integration:** Android Home Screen Widgets & Local Notifications

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (Latest Version)
- Android Studio / VS Code
- Firebase Project Setup

### Installation
1. **Clone the Repository:**
   ```bash
   git clone https://github.com/shantoshdurai/ClassNow-app.git
   ```
2. **Install Dependencies:**
   ```bash
   flutter pub get
   ```
3. **Firebase Configuration:**
   - Add your `google-services.json` to `android/app/`.
   - Initialize Firestore with collections: `schedule` and `announcements`.
4. **Run the App:**
   ```bash
   flutter run
   ```

---

## 📸 Preview

*Note: Add your screenshots here!*

| Dashboard | Mentor Mode | Announcements |
| :---: | :---: | :---: |
| <img src="screenshots/dashboard.jpeg" width="200"> | <img src="screenshots/mentor.jpeg" width="200"> | <img src="screenshots/announcements.png" width="200"> |

---

## 🤝 Contributing
Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

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
