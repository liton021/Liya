# 🚀 Quick Start Guide - Liya

## Prerequisites

1. **Flutter SDK** - [Install Flutter](https://docs.flutter.dev/get-started/install)
2. **Firebase Account** - [Create Firebase Project](https://console.firebase.google.com)
3. **Android Studio** or **Xcode** (for emulators)

## Setup Steps

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Configure Firebase

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase (auto-generates firebase_options.dart)
flutterfire configure
```

**Select your Firebase project and platforms (Android/iOS)**

### 3. Enable Firebase Services

In Firebase Console:

1. **Authentication**
   - Go to Authentication > Sign-in method
   - Enable "Email/Password"

2. **Firestore Database**
   - Go to Firestore Database
   - Create database (Start in test mode)
   - Set these rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    match /chats/{chatId} {
      allow read, write: if request.auth != null && 
        request.auth.uid in resource.data.participants;
    }
    
    match /chats/{chatId}/messages/{messageId} {
      allow read, write: if request.auth != null;
    }
    
    match /calls/{callId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 4. Run the App

**Using Script (Recommended):**

Linux/Mac:
```bash
chmod +x setup.sh
./setup.sh
```

Windows:
```bash
setup.bat
```

**Manual:**
```bash
# Check connected devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Or run on default device
flutter run
```

## Build Release

### Android APK
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```
Output: `build/web/`

## Troubleshooting

### Firebase not configured
- Make sure you ran `flutterfire configure`
- Check `lib/firebase_options.dart` exists

### Dependencies error
```bash
flutter clean
flutter pub get
```

### Camera/Microphone permissions
- **Android**: Already configured in `AndroidManifest.xml`
- **iOS**: Already configured in `Info.plist`

### WebRTC issues
- Test on real device (emulators may have issues)
- Check camera/mic permissions are granted

## Features

✅ Email/Password Authentication
✅ Real-time Chat (Firestore)
✅ Video Calls (WebRTC P2P)
✅ Audio Calls (WebRTC P2P)
✅ Online Status
✅ Premium Dark UI
✅ Glassmorphism Design

## Tech Stack

- Flutter 3.0+
- Firebase Auth
- Cloud Firestore
- WebRTC (flutter_webrtc)
- Provider (State Management)
- Google Fonts (Inter)

## Free Tier Limits

- **Firebase Auth**: Unlimited
- **Firestore**: 50K reads/day, 20K writes/day, 1GB storage
- **WebRTC**: Unlimited (P2P, no server costs)

Perfect for personal projects! 🎉
