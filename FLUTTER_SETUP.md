# Flutter Mobile App Setup

## 📱 **Flutter Project Ready!**

### **Project Structure:**
```
frontend/aplikasi_tms/
├── lib/                 # Dart source code
├── android/            # Android configuration
├── ios/               # iOS configuration  
├── web/               # Web configuration
├── pubspec.yaml       # Dependencies
└── README.md          # Flutter docs
```

### **Dependencies Configured:**
- ✅ **http**: API communication
- ✅ **provider**: State management
- ✅ **shared_preferences**: Local storage
- ✅ **cupertino_icons**: iOS-style icons

## 🚀 **Manual Flutter Commands:**

### **1. Setup (First time):**
```bash
cd frontend/aplikasi_tms
flutter pub get
```

### **2. Run on Mobile Device:**
```bash
# Connect your Android device or start emulator
flutter devices
flutter run
```

### **3. Run on Web:**
```bash
flutter run -d web-server --web-port=3005
```

### **4. Build APK:**
```bash
flutter build apk --release
```

## 🔧 **Makefile Commands:**
```bash
make flutter-check      # Check project setup
make flutter-mobile     # Show manual instructions
make flutter-web        # Run web version (if Flutter works)
```

## 📱 **Next Steps:**

1. **Fix Flutter SDK** (if needed):
   ```bash
   sudo snap remove flutter
   sudo snap install flutter --classic
   flutter doctor
   ```

2. **Connect Device:**
   - Enable USB Debugging on Android
   - Or start Android Emulator

3. **Run App:**
   ```bash
   cd frontend/aplikasi_tms
   flutter run
   ```

## 🌐 **Alternative: Web Preview**
```bash
make web  # HTML interface at http://localhost:3006/tms-dashboard.html
```