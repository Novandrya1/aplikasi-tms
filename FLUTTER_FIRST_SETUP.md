# Flutter-First TMS Setup

## 📱 **Primary: Flutter Mobile App**

### **Quick Start:**
```bash
# Start complete mobile development
make mobile

# Or step by step:
make dev              # Start backend + database
make flutter-mobile   # Start Flutter mobile app
```

### **Features:**
- ✅ 11 Complete screens (Login, Dashboard, Vehicle, Driver, Trip, etc.)
- ✅ 6 API services (Auth, Vehicle, Driver, Trip, Analytics)
- ✅ Multi-platform (Android, iOS, Windows, macOS, Linux)
- ✅ Material Design UI
- ✅ State management with Provider

## 🌐 **Secondary: Flutter Web**

### **Quick Start:**
```bash
# Start web development
make web

# Or step by step:
make dev            # Start backend + database  
make flutter-web    # Start Flutter web version
```

### **Access:**
- **Flutter Web**: http://localhost:3005
- **Backend API**: http://localhost:8080
- **Database Admin**: http://localhost:5050

## 🧪 **Testing: HTML Interface**

### **For Quick Testing Only:**
```bash
make web-test       # HTML test interface on port 3006
```

## 🚀 **Development Workflow**

### **1. Mobile Development (Primary):**
```bash
make mobile         # Complete mobile setup
# Connect Android device or start emulator
# App will launch automatically
```

### **2. Web Development (Secondary):**
```bash
make web           # Flutter web version
# Open http://localhost:3005 in browser
```

### **3. API Testing:**
```bash
make test-all-endpoints    # Test all backend APIs
make test-security         # Security tests
make test-performance      # Performance tests
```

## 📊 **Project Structure**

```
aplikasi-tms/
├── backend/                    # Go API server
├── frontend/aplikasi_tms/      # 📱 Flutter App (PRIMARY)
│   ├── lib/screens/           # 11 UI screens
│   ├── lib/services/          # 6 API services  
│   ├── lib/models/            # Data models
│   ├── android/               # Android config
│   ├── ios/                   # iOS config
│   └── web/                   # 🌐 Flutter Web
├── tms-dashboard.html         # 🧪 HTML test interface
└── Makefile                   # Build commands
```

## 🎯 **Next Steps**

1. **✅ Flutter-First Strategy Implemented**
2. **📱 Focus on Mobile App Development**
3. **🌐 Flutter Web as Secondary Interface**
4. **🧪 HTML for Testing Only**

## 📋 **Commands Summary**

```bash
# Primary Development
make mobile         # Flutter mobile app
make web           # Flutter web app
make all           # Complete system (Flutter web)

# Testing & Utilities
make web-test      # HTML test interface
make flutter-check # Check Flutter setup
make flutter-fix   # Fix Flutter issues

# Backend
make dev           # Backend + database only
make test          # Test backend health
```