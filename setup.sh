#!/bin/bash

echo "🚀 Liya - Setup & Build Script"
echo "================================"
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed!"
    echo ""
    echo "📥 Install Flutter:"
    echo "   Visit: https://docs.flutter.dev/get-started/install"
    echo ""
    exit 1
fi

echo "✅ Flutter found"
flutter --version
echo ""

# Install dependencies
echo "📦 Installing dependencies..."
flutter pub get

if [ $? -ne 0 ]; then
    echo "❌ Failed to install dependencies"
    exit 1
fi

echo ""
echo "✅ Dependencies installed"
echo ""

# Setup Firebase
echo "🔥 Firebase Setup"
echo "================================"
echo ""
echo "Before building, you need to configure Firebase:"
echo ""
echo "1. Create a Firebase project at https://console.firebase.google.com"
echo "2. Enable Authentication (Email/Password)"
echo "3. Enable Firestore Database"
echo "4. Run: dart pub global activate flutterfire_cli"
echo "5. Run: flutterfire configure"
echo ""
echo "This will generate firebase_options.dart with your config"
echo ""

read -p "Have you completed Firebase setup? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "⚠️  Please complete Firebase setup first"
    exit 1
fi

echo ""
echo "🏗️  Building Liya..."
echo "================================"
echo ""

# Check available devices
echo "📱 Available devices:"
flutter devices
echo ""

read -p "Enter device ID (or press Enter for default): " DEVICE_ID

if [ -z "$DEVICE_ID" ]; then
    echo "🚀 Running on default device..."
    flutter run
else
    echo "🚀 Running on device: $DEVICE_ID"
    flutter run -d "$DEVICE_ID"
fi
