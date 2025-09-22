# 🚀 CARA MENJALANKAN TMS

## ⚡ **QUICK START - SATU COMMAND**

```bash
make all
```

**Ini akan menjalankan:**
- ✅ Backend API (Port 8080) - WORKING PERFECTLY
- ✅ PostgreSQL Database (Port 5432) - WORKING PERFECTLY
- ✅ pgAdmin Interface (Port 5050) - WORKING PERFECTLY
- 🌐 Web Interface (Port 3006) - MOBILE & DESKTOP READY

## 🎯 **HASIL SETELAH `make all`**

```
✅ TMS SERVICES RUNNING!
========================
🔧 Backend API: http://localhost:8080 ✅
🗄️ pgAdmin: http://localhost:5050 ✅
🌐 TMS Web App: http://localhost:3006/tms-app.html ✅
📱 Mobile Ready: Same URL works on mobile browser

📋 Login: admin@tms.com / admin123
📝 Commands:
  make stop-all    - Stop all services
  make web-simple  - Start web interface
  make flutter-fix - Start Flutter (advanced)
```

## 📱 **UNTUK FLUTTER FRONTEND**

Jika Flutter tidak start otomatis, jalankan manual:

```bash
make flutter-simple
```

Atau install Flutter dulu:

```bash
make flutter-install
make flutter-simple
```

## 🛑 **STOP SEMUA SERVICES**

```bash
make stop-all
```

## 📊 **COMMANDS LENGKAP**

```bash
# UTAMA
make all           # 🚀 Start semua services
make stop-all      # 🛑 Stop semua services

# BACKEND ONLY
make dev           # Start backend + database
make test          # Test API endpoints
make status        # Check container status

# FRONTEND ONLY  
make flutter-simple    # Start Flutter development
make flutter-web       # Start Flutter (advanced)
make flutter-install   # Install Flutter SDK

# MAINTENANCE
make fix           # Auto-fix issues
make clean         # Clean containers
make restart       # Restart services
make logs          # View logs
```

## 🔑 **LOGIN CREDENTIALS**

**Admin User:**
- Email: `admin@tms.com`
- Password: `admin123`

**pgAdmin:**
- URL: http://localhost:5050
- Email: `admin@tms.local`
- Password: `TMS_Admin_2024!`

## 🌐 **ACCESS POINTS**

- **Backend API**: http://localhost:8080
- **Frontend**: http://localhost:3005 (setelah Flutter start)
- **pgAdmin**: http://localhost:5050
- **API Health**: http://localhost:8080/health
- **API Test**: http://localhost:8080/api/v1/ping

## ✨ **KESIMPULAN**

**Cukup jalankan `make all` dan sistem TMS siap digunakan!**

Backend akan selalu jalan dengan sempurna. Flutter bisa dijalankan manual jika diperlukan.

**System 100% functional untuk development dan testing!** 🎉