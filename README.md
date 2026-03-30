# Liya - Minimalist Premium Social Network

A modern, lightweight social network app with video/audio calls and chat built with Flutter and Firebase.

## Features

- 🎥 Video & Audio Calls (WebRTC)
- 💬 Real-time Chat (Firestore)
- 👥 User Contacts
- 🎨 Premium Dark UI
- 🔐 Firebase Authentication

## Setup

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Firebase Setup

1. Create a Firebase project at https://console.firebase.google.com
2. Enable Authentication (Email/Password)
3. Enable Firestore Database
4. Run FlutterFire CLI:
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This will automatically generate `firebase_options.dart` with your Firebase config.

### 3. Firestore Rules

Set these rules in Firebase Console > Firestore Database > Rules:

```
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
```bash
flutter run
```

## Architecture

```
lib/
├── core/
│   └── theme/          # App theme
├── features/
│   ├── auth/           # Authentication
│   ├── chat/           # Messaging
│   ├── call/           # Video/Audio calls
│   └── home/           # Main navigation
└── main.dart
```

## Tech Stack

- **Flutter** - UI Framework
- **Firebase Auth** - Authentication
- **Firestore** - Real-time database
- **WebRTC** - P2P video/audio calls
- **Provider** - State management

## Free Tier Limits

- Firebase Auth: Unlimited
- Firestore: 50K reads/day, 20K writes/day
- WebRTC: Unlimited (P2P)

Perfect for personal projects with no hosting costs!
