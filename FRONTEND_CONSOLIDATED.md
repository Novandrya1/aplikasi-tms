# Frontend Structure Organized

## 📱 **Flutter Mobile App + 🌐 HTML Web Interface**

### **Two Frontend Options:**
- 📱 **Flutter**: For mobile app (Android/iOS)
- 🌐 **HTML**: For web testing and preview

### **Main Interface**
- **URL**: http://localhost:3006/tms-dashboard.html
- **Features**: Complete TMS dashboard with all modules
- **Mobile**: Responsive design with hamburger menu
- **Authentication**: Login/register integrated

### **Quick Start**
```bash
# Start complete system
make all

# Or start separately
make dev    # Backend + Database
make web    # Web Interface only
```

### **Available Commands**

**Mobile App (Flutter):**
```bash
make flutter-install    # Install Flutter SDK
make flutter-mobile     # Run on mobile device
make flutter-web        # Run Flutter web version
make flutter-build-apk  # Build Android APK
```

**Web Interface (HTML):**
```bash
make web              # Start HTML web interface
make test-webapp      # Test web connectivity
```

**System:**
```bash
make all              # Start complete system
make dev              # Backend + Database only
make stop-all         # Stop all services
```

### **Archived Interfaces**
- Flutter project: `frontend/aplikasi_tms/` (kept for reference)
- Old HTML files: `archive/html-interfaces/`
- Legacy commands: `make flutter-legacy`

### **Access Points**
- **Mobile App**: Flutter on device/emulator
- **Web Preview**: http://localhost:3006/tms-dashboard.html
- **Flutter Web**: http://localhost:3005 (when running)
- **Backend API**: http://localhost:8080
- **Database Admin**: http://localhost:5050
- **Login**: admin@tms.com / admin123

## 🎯 **Next Steps**
1. ✅ Frontend Structure Organized
2. 📱 Mobile App Development
3. 📋 Unit Testing
4. 📚 API Documentation  
5. 🚀 Production Deployment