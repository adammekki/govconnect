# GovConnect

GovConnect is a modern Flutter application designed to bridge the gap between citizens, government officials, and advertisers. It provides a platform for community engagement, announcements, problem reporting, polls, advertisements, and real-time communication.

---

## ✨ Features

- **User Authentication**: Secure sign up, login, and email verification.
- **Profile Management**: Edit your profile, update contact info, and manage your account.
- **Feed**: Unified feed displaying announcements, polls, and advertisements.
- **Announcements**: Government officials can post announcements with images and categories; citizens can comment and interact.
- **Polls**: Participate in community polls and view poll results.
- **Problem Reporting**: Citizens can report local issues with descriptions, images, and geolocation; government can track and update statuses.
- **Advertisements**: Advertisers can submit ads for review; government can approve or reject.
- **Chat**: Real-time chat between users.
- **Notifications**: Stay updated with push notifications.
- **Emergency Contacts**: Quick access to emergency services.
- **Dark & Light Theme**: Seamless theme switching for better accessibility.

---

## 📂 Project Structure

```
lib/
├── auth/                # Authentication screens & logic
├── components/          # Reusable UI components (bottom bar, drawer, header)
├── models/              # Data models (problem report, notification, etc.)
├── Polls/               # Polls UI and logic
├── providers/           # State management (Provider)
├── screens/             # Main app screens (feed, profile, problems, ads, chat, etc.)
├── theme/               # App theming (light/dark)
├── utils/               # Utility functions (map styling, etc.)
├── homePage_screen.dart # Main home page
├── main.dart            # App entry point
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Firebase Project](https://firebase.google.com/)
- Android Studio / Xcode / VS Code
- Android Studio Emulator

### Installation

1. **Clone the repository:**
   ```sh
   git clone https://github.com/yourusername/govconnect.git
   cd govconnect
   ```

2. **Install dependencies:**
   ```sh
   flutter pub get
   ```

3. **Configure Firebase:**
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) to the respective directories.
   - Enable Authentication, Firestore, and Storage in your Firebase project.

4. **Run the app:**
   ```sh
   flutter run
   ```

---

## 🛠️ Key Packages Used

- `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `firebase_messaging`
- `provider` for state management
- `google_maps_flutter` for map integration
- `image_picker`, `share_plus`, `translator`, `profanity_filter`, etc.


> Built with ❤️ using Flutter.