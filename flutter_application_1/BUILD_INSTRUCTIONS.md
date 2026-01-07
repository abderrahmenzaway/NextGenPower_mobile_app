# next gen-power - Setup & Build Guide

Quick guide to set up and build the Flutter mobile application.

---

## 📱 Application Info

- **App Name:** next gen-power
- **Logo:** `lib/screens/assets/logo.png`
- **Platform:** Android & iOS

---

## 🚀 Quick Setup (3 Steps)

### Step 1: Install Requirements

**Flutter SDK:**
```bash
# Download from: https://docs.flutter.dev/get-started/install
# Verify installation:
flutter doctor
```

**Android Studio** (for building APK):
- Download: https://developer.android.com/studio
- Choose "Standard" installation
- Accept licenses: `flutter doctor --android-licenses`

**Node.js & PostgreSQL** (for backend):
- Node.js: https://nodejs.org/
- PostgreSQL: https://www.postgresql.org/download/

### Step 2: Start Backend

```bash
# In WSL or terminal:
cd blockchain/hedera-energy-trading
npm install
npm start
```

Backend runs on `http://localhost:3000`

### Step 3: Run the App

**For Development:**
```bash
cd flutter_application_1
flutter pub get
flutter run
```

**For APK (Phone):**

First, expose backend with ngrok:
```bash
ngrok http 3000
# Copy the URL: https://xxxx.ngrok-free.dev
```

Then build APK:
```bash
flutter build apk --release --dart-define=API_BASE_URL=https://your-ngrok-url.ngrok-free.dev
```

APK location: `build/app/outputs/flutter-apk/app-release.apk`

---

## 📦 Install APK on Phone

1. Copy `app-release.apk` to your phone
2. Open the file and tap "Install"
3. Enable "Unknown sources" if prompted

**OR** use ADB:
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## 🔧 Troubleshooting

| Problem | Solution |
|---------|----------|
| Android SDK not found | Install Android Studio |
| Backend connection failed | Start backend on port 3000 |
| bcrypt error (Windows) | Use WSL: `wsl bash -c "cd /mnt/c/EcoGuardians-main/blockchain/hedera-energy-trading && npm start"` |
| App can't connect | Update ngrok URL and rebuild APK |

---

## ⚙️ Configuration

**Change API URL:**
Edit `lib/services/api_service.dart` line 11:
```dart
defaultValue: 'http://localhost:3000',  // Change this
```

**Custom Icon:**
```bash
flutter pub add dev:flutter_launcher_icons
# Add to pubspec.yaml:
flutter_icons:
  android: true
  image_path: "lib/screens/assets/logo.png"
# Generate:
flutter pub run flutter_launcher_icons
```

---

## 📝 Important Notes

- Keep backend **and** ngrok running while using APK
- Free ngrok URL changes on restart (rebuild APK with new URL)
- For production, use a permanent backend URL

---

**Need help?** Check Flutter docs: https://docs.flutter.dev
