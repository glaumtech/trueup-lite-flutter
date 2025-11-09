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

echo "✅ Build completed successfully!"
echo "📁 APK location: build/app/outputs/flutter-apk/app-release.apk"
