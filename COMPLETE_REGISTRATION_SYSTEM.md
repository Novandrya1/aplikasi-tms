# Sistem Registrasi Armada Lengkap - TMS

## 🎯 Overview

Sistem registrasi armada yang telah diperbaiki sekarang menampilkan **data secara real** dengan alur lengkap:

1. **Pengguna registrasi armada** → Mengirim data lengkap + dokumen
2. **Data masuk ke sistem admin** → Admin melihat semua data dan file
3. **Admin verifikasi** → Proses verifikasi dengan dokumen lengkap
4. **Data lengkap tersimpan** → Semua gambar dan file terintegrasi

## 🔧 Perbaikan yang Dilakukan

### 1. Backend Services Baru

#### `CompleteVehicleRegistration` Service
- **File**: `backend/internal/services/complete_registration_service.go`
- **Fungsi**: Menangani registrasi lengkap dengan dokumen real
- **Features**:
  - ✅ Upload file gambar (base64 dan multipart)
  - ✅ Simpan data pemilik lengkap
  - ✅ Auto-validation sistem
  - ✅ Notifikasi real-time ke admin

#### `AdminVerificationService` Service  
- **File**: `backend/internal/services/admin_verification_service.go`
- **Fungsi**: Dashboard admin dengan data lengkap
- **Features**:
  - ✅ Dashboard verifikasi komprehensif
  - ✅ Detail kendaraan dengan semua dokumen
  - ✅ Riwayat verifikasi lengkap
  - ✅ Cross-check dan inspeksi

### 2. Database Schema Lengkap

#### Migration Baru
- **File**: `migrations/011_complete_registration_system.sql`
- **Tabel Baru/Updated**:
  - `vehicle_attachments` - Menyimpan semua file dokumen
  - `verification_history` - Riwayat verifikasi lengkap
  - `vehicle_inspections` - Jadwal dan hasil inspeksi
  - `user_documents` - Dokumen pengguna

### 3. Frontend Admin Dashboard

#### Screen Detail Kendaraan
- **File**: `frontend/aplikasi_tms/lib/screens/admin_vehicle_detail_screen.dart`
- **Features**:
  - ✅ Tampilan data kendaraan lengkap
  - ✅ Informasi pemilik detail
  - ✅ Daftar dokumen dengan status
  - ✅ Riwayat verifikasi
  - ✅ Aksi admin (setujui/tolak/perbaikan)

## 📋 Alur Registrasi Lengkap

### 1. Registrasi Pengguna Armada

```json
POST /api/v1/fleet/vehicles
{
  "registration_number": "B 1234 XYZ",
  "vehicle_type": "Truk",
  "brand": "Mitsubishi",
  "model": "Canter",
  "year": 2022,
  "chassis_number": "CHASSIS123456",
  "engine_number": "ENGINE789012",
  "color": "Putih",
  "capacity_weight": 3500.0,
  "owner_data": {
    "name": "Budi Santoso",
    "ktp_number": "3171234567890123",
    "address": "Jl. Raya No. 123",
    "phone": "081234567890",
    "email": "budi@example.com",
    "company_name": "PT Transport Maju",
    "npwp": "12.345.678.9-012.000"
  },
  "documents": {
    "ktp_file": "data:image/jpeg;base64,/9j/4AAQ...",
    "selfie_file": "data:image/jpeg;base64,/9j/4AAQ...",
    "stnk_file": "data:image/jpeg;base64,/9j/4AAQ...",
    "bpkb_file": "data:image/jpeg;base64,/9j/4AAQ...",
    "tax_file": "data:image/jpeg;base64,/9j/4AAQ...",
    "insurance_file": "data:image/jpeg;base64,/9j/4AAQ...",
    "vehicle_photos": [
      "data:image/jpeg;base64,/9j/4AAQ...",
      "data:image/jpeg;base64,/9j/4AAQ...",
      "data:image/jpeg;base64,/9j/4AAQ..."
    ]
  }
}
```

### 2. Data Masuk ke Admin

Admin melihat di dashboard:
- ✅ **Data kendaraan lengkap** (semua field terisi)
- ✅ **Informasi pemilik detail** (nama, KTP, alamat, dll)
- ✅ **Semua dokumen terlampir** (KTP, STNK, BPKB, foto kendaraan)
- ✅ **Status upload** setiap dokumen
- ✅ **Ukuran file** dan tanggal upload

### 3. Proses Verifikasi Admin

```json
PUT /api/v1/admin/vehicles/{id}/verify
{
  "status": "approved",
  "notes": "Semua dokumen lengkap dan valid",
  "requires_inspection": false,
  "validation_checks": {
    "documents_complete": true,
    "data_valid": true,
    "no_duplicates": true
  }
}
```

### 4. Data Tersimpan Lengkap

Database menyimpan:
- ✅ **File fisik** di folder `./uploads/`
- ✅ **Metadata dokumen** di tabel `vehicle_attachments`
- ✅ **Riwayat verifikasi** di tabel `verification_history`
- ✅ **Data pemilik lengkap** di tabel `fleet_owners`

## 🚀 Cara Menjalankan Sistem Lengkap

### 1. Quick Start

```bash
# Jalankan sistem lengkap dengan migration
./run-complete-system.sh
```

### 2. Manual Setup

```bash
# 1. Stop existing services
make down

# 2. Build fresh images
make build

# 3. Start database
make database

# 4. Run migration
docker compose exec postgres psql -U tms_user -d tms_db -f /migrations/011_complete_registration_system.sql

# 5. Start all services
make start
```

### 3. Akses Sistem

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8080
- **pgAdmin**: http://localhost:5050

## 📊 Fitur Lengkap yang Tersedia

### ✅ Registrasi Armada Real
- Upload dokumen dengan file gambar asli
- Data pemilik lengkap (individu/perusahaan)
- Validasi otomatis dokumen
- Notifikasi real-time

### ✅ Dashboard Admin Komprehensif
- Daftar kendaraan dengan status lengkap
- Detail kendaraan dengan semua dokumen
- Riwayat verifikasi step-by-step
- Aksi verifikasi (setujui/tolak/perbaikan)

### ✅ Sistem File Management
- Upload file base64 dan multipart
- Penyimpanan file fisik di server
- Metadata dokumen lengkap
- Validasi jenis dan ukuran file

### ✅ Workflow Verifikasi
- Status bertingkat (pending → review → approved/rejected)
- Permintaan perbaikan dengan detail
- Jadwal inspeksi fisik
- Cross-check dengan database eksternal

## 📁 Struktur File Baru

```
aplikasi-tms/
├── backend/internal/services/
│   ├── complete_registration_service.go    # Service registrasi lengkap
│   └── admin_verification_service.go       # Service verifikasi admin
├── frontend/aplikasi_tms/lib/screens/
│   └── admin_vehicle_detail_screen.dart    # Screen detail admin
├── migrations/
│   └── 011_complete_registration_system.sql # Migration lengkap
├── uploads/                                 # Folder file upload
└── run-complete-system.sh                  # Script startup lengkap
```

## 🔍 Testing Alur Lengkap

### 1. Test Registrasi Armada

```bash
# Login sebagai fleet owner
curl -X POST http://localhost:8080/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{"email":"fleet@tms.com","password":"fleet123"}'

# Registrasi kendaraan dengan dokumen
curl -X POST http://localhost:8080/api/v1/fleet/vehicles \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d @sample_vehicle_registration.json
```

### 2. Test Admin Verification

```bash
# Login sebagai admin
curl -X POST http://localhost:8080/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@tms.com","password":"admin123"}'

# Lihat dashboard verifikasi
curl -X GET http://localhost:8080/api/v1/admin/verification-dashboard \
  -H "Authorization: Bearer ADMIN_TOKEN"

# Lihat detail kendaraan
curl -X GET http://localhost:8080/api/v1/admin/vehicles/1 \
  -H "Authorization: Bearer ADMIN_TOKEN"
```

## 🎯 Hasil Akhir

Sekarang sistem menampilkan **data secara real** dengan:

1. ✅ **Registrasi lengkap** - Pengguna kirim data + file asli
2. ✅ **Data masuk admin** - Admin lihat semua data dan dokumen
3. ✅ **Verifikasi real** - Admin proses dengan dokumen lengkap
4. ✅ **File terintegrasi** - Gambar dan dokumen tersimpan dan dapat diakses

Sistem sekarang benar-benar menangani alur registrasi armada yang **real dan lengkap** sesuai kebutuhan bisnis transportasi.

## 🔧 Troubleshooting

### File Upload Issues
```bash
# Pastikan folder uploads ada dan writable
mkdir -p ./uploads
chmod 755 ./uploads
```

### Database Migration Issues
```bash
# Reset database jika perlu
make clean
make start
```

### Service Connection Issues
```bash
# Check service status
make status

# View logs
make logs-backend
make logs-frontend
```

## 📞 Support

Jika ada masalah dengan sistem registrasi lengkap:
1. Cek logs dengan `make logs`
2. Pastikan semua service running dengan `make status`
3. Test API endpoints dengan script yang disediakan