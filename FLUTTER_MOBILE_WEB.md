# 📱 FLUTTER MOBILE & WEB SETUP

## 🚀 QUICK START

```bash
# Start backend
make all

# Start Flutter (mobile & web)
make flutter-fix
```

## 📱 MOBILE DEVELOPMENT

```bash
# Check devices
flutter devices

# Run on mobile device
flutter run

# Run on specific device
flutter run -d <device_id>
```

## 🌐 WEB DEVELOPMENT

```bash
# Run web only
flutter run -d web-server --web-port=3005

# Build for web
flutter build web
```

## 🔧 TROUBLESHOOTING

### Flutter Not Working?
```bash
make flutter-install
make flutter-fix
```

### Dependencies Error?
```bash
cd frontend/aplikasi_tms
flutter clean
flutter pub get
```

### Web Not Loading?
- Check: http://localhost:3005
- Backend must be running: http://localhost:8080

## 📊 DEVELOPMENT WORKFLOW

1. **Start Backend**: `make all`
2. **Start Flutter**: `make flutter-fix`
3. **Access Web**: http://localhost:3005
4. **Mobile**: Connect device and `flutter run`

## 🎯 FEATURES READY

- ✅ Cross-platform API config (web/mobile)
- ✅ Authentication (login/register)
- ✅ Dashboard with analytics
- ✅ Vehicle management
- ✅ Driver management  
- ✅ Trip management
- ✅ Real-time data integration