#!/bin/bash

# TrueUp Lite Flutter Build Script

echo "🚀 Starting TrueUp Lite Flutter build process..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Installing dependencies..."
flutter pub get

# Generate code for JSON serialization
echo "🔧 Generating code..."
flutter packages pub run build_runner build --delete-conflicting-outputs

# Run tests
echo "🧪 Running tests..."
flutter test

# Build APK for Android
echo "📱 Building Android APK..."
flutter build apk --release

# Rename final APK
echo "🏷️ Renaming APK to TrueupLite.apk..."
if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
  cp "build/app/outputs/flutter-apk/app-release.apk" "build/app/outputs/flutter-apk/TrueupLite.apk"
else
  echo "❌ Expected APK not found at build/app/outputs/flutter-apk/app-release.apk"
  exit 1
fi

echo "✅ Build completed successfully!"
echo "📁 APK location: build/app/outputs/flutter-apk/TrueupLite.apk"
