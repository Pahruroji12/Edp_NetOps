<div align="center">

<img src="assets/logo.png" alt="EDP NetOps Logo" width="80" height="80" style="border-radius:16px"/>

# EDP NetOps

**Aplikasi IT Support & Network Operations Departemen EDP**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.9.2-0175C2?style=flat-square&logo=dart)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-2.x-3ECF8E?style=flat-square&logo=supabase)](https://supabase.com)
[![Platform](https://img.shields.io/badge/Platform-Windows%20Desktop-0078D6?style=flat-square&logo=windows)](https://flutter.dev/desktop)
[![Version](https://img.shields.io/badge/Version-2.7.0-success?style=flat-square)](https://github.com)
[![License](https://img.shields.io/badge/License-Private-red?style=flat-square)](LICENSE)

> Pusat kendali infrastruktur IT dan jaringan toko dalam satu platform terintegrasi.

</div>

---

## 📋 Daftar Isi

- [Deskripsi](#-deskripsi)
- [Fitur Utama](#-fitur-utama)
- [Teknologi](#-teknologi)
- [Arsitektur](#-arsitektur-project)
- [Struktur Folder](#-struktur-folder)
- [Prerequisites](#-prerequisites)
- [Instalasi](#-instalasi)
- [Menjalankan Aplikasi](#-menjalankan-aplikasi)
- [Environment Setup](#-environment-setup)
- [Flow Aplikasi](#-flow-aplikasi)
- [Database Schema](#-database-schema)
- [Dependency Utama](#-dependency-utama)
- [Build Desktop](#-build-desktop)
- [Troubleshooting](#-troubleshooting)
- [Security Notes](#-security-notes)
- [Future Improvement](#-future-improvement)
- [Author](#-author)

---

## 📖 Deskripsi

**EDP NetOps** adalah aplikasi Flutter Desktop yang dirancang khusus untuk tim IT Support & Network Operations Departemen EDP. Aplikasi ini menjadi pusat kendali untuk memantau infrastruktur jaringan toko, mengelola tiket gangguan, mengoperasikan perangkat jaringan (Mikrotik/WDCP), serta melakukan monitoring konektivitas secara real-time.

Aplikasi ini berjalan secara native di **Windows Desktop** dan terhubung ke backend **Supabase** (PostgreSQL + Auth) untuk manajemen data yang aman dan real-time.

---

## ✨ Fitur Utama

### 🖥️ Dashboard
- Statistik ringkasan jaringan (Total Toko, FO, VSAT, GSM, XL)
- Clock real-time dengan informasi tanggal
- Daftar toko dengan filter dan pencarian
- Welcome section dengan informasi user yang login

### 🏪 Manajemen Data Toko
- CRUD lengkap data toko (tambah, edit, hapus)
- Detail toko: IP Gateway, VSAT, RB WDCP, Station 1-5, STB, iKiosk, Timbangan, CCTV
- Filter koneksi (FO, VSAT, GSM, XL)
- Export data ke Excel (.xlsx)
- Remote Winbox, VNC, Telnet langsung dari aplikasi

### 🎫 History Ticket
- Pencatatan tiket gangguan jaringan
- Filter by status (Open, In Progress, Resolved)
- Filter by provider (Astinet, ICON, Fiberstar)
- Filter by bulan
- Ranking toko yang sering gangguan
- Export laporan tiket ke Excel (2 sheet)
- Kirim email notifikasi tiket ke provider

### 🌐 Network Tools (Windows Only)
- **Ping Scanner**: Ping massal ke IP Gateway, Station, STB, RB WDCP, CCTV semua toko
- **Auto-Ping STB**: Ping otomatis setiap hari jam 00:00–03:59 (Shift 3)
- **Scan RbWDCP**: Koneksi langsung ke Mikrotik via API
  - Lihat Registration Table (client terhubung)
  - Kelola Access List (whitelist MAC)
  - Toggle Default Authentication
  - Monitor resource sistem router

### 👤 Profil & Manajemen User
- Ganti password pribadi
- Daftar tim EDP (pencarian nama/NIK)
- Delete user (khusus Administrator)

### ⚙️ Pengaturan (Admin/Administrator)
- Konfigurasi SMTP email (host, port, user, password)
- Konfigurasi path aplikasi (Winbox, VNC, Telnet)
- Log aktivitas pengguna sistem
- Control Center admin

### 🌙 Tema
- Dark Mode & Light Mode
- Tema persisten antar session

---

## 🛠️ Teknologi

| Kategori | Teknologi | Versi |
|----------|-----------|-------|
| Framework | Flutter | 3.x |
| Language | Dart | 3.9.2+ |
| Backend | Supabase (PostgreSQL + Auth) | 2.12.x |
| Routing | GoRouter | 17.x |
| Fonts | Google Fonts | 8.x |
| Window Management | window_manager | 0.5.x |
| Email | mailer | 7.x |
| Telegram Bot | teledart | 0.6.x |
| FTP | ftpconnect | 2.x |
| Export Excel | excel | 4.x |
| File Operations | path_provider, file_picker | - |
| Network | dart_ping | 9.x |
| Crypto | crypto | 3.x |
| Environment | flutter_dotenv | 6.x |

---

## 🏛️ Arsitektur Project

Project menggunakan **Feature-based Layered Architecture** dengan pemisahan `data`, `domain`, dan `presentation` per fitur.

```
┌─────────────────────────────────────────────────────┐
│                  PRESENTATION LAYER                  │
│         Pages  │  Widgets  │  Controllers            │
└──────────────────────┬──────────────────────────────┘
                       │ depends on
┌──────────────────────▼──────────────────────────────┐
│                   DOMAIN LAYER                       │
│           Models  │  State  │  Entities              │
└──────────────────────┬──────────────────────────────┘
                       │ depends on
┌──────────────────────▼──────────────────────────────┐
│                    DATA LAYER                        │
│        Repositories  │  Services  │  Supabase        │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│                    CORE LAYER                        │
│  Theme  │  Widgets  │  Utils  │  Services  │ Globals │
└─────────────────────────────────────────────────────┘
```

**State Management:** `ChangeNotifier` pattern — controller per fitur, di-listen dari page via `ListenableBuilder` atau `AnimatedBuilder`.

**Routing:** GoRouter dengan `ShellRoute` untuk persistent sidebar layout.

---

## 📁 Struktur Folder

```
edp_netops/
├── .env                          # Konfigurasi environment (tidak di-commit)
├── pubspec.yaml                  # Dependencies Flutter
├── assets/
│   └── logo.png                  # Ikon aplikasi
└── lib/
    ├── main.dart                 # Entry point (init only, no UI)
    ├── app/
    │   ├── app.dart              # Root widget (MaterialApp.router)
    │   └── app_router.dart       # Konfigurasi GoRouter & routes
    ├── core/
    │   ├── globals.dart          # GlobalKey (ScaffoldMessenger)
    │   ├── services/
    │   │   └── activity_logger.dart    # Log aktivitas ke Supabase
    │   ├── theme/
    │   │   ├── app_colors.dart   # Color system & BuildContext extensions
    │   │   └── app_theme.dart    # ThemeData (Dark & Light) + themeNotifier
    │   ├── utils/
    │   │   ├── encryption_helper.dart  # SHA-256 hashing utility
    │   │   └── export_helper.dart      # Export data ke Excel (.xlsx)
    │   └── widgets/
    │       ├── custom_snackbar.dart    # Snackbar bergaya konsisten
    │       └── network_action_buttons.dart  # Tombol aksi jaringan
    ├── features/
    │   ├── auth/
    │   │   ├── data/
    │   │   │   └── auth_repository.dart    # Supabase auth operations
    │   │   ├── domain/
    │   │   │   └── auth_state.dart         # Singleton state user login
    │   │   └── presentation/
    │   │       ├── login_controller.dart   # Login logic & state
    │   │       └── login_page.dart         # UI halaman login
    │   ├── dashboard/
    │   │   ├── data/
    │   │   │   └── dashboard_repository.dart   # Fetch & kalkulasi statistik
    │   │   └── presentation/
    │   │       ├── dashboard_controller.dart   # State dashboard & clock
    │   │       ├── dashboard_page.dart          # UI halaman dashboard
    │   │       └── widgets/
    │   │           ├── stats_grid.dart          # Grid kartu statistik
    │   │           ├── store_list_card.dart     # Kartu daftar toko
    │   │           └── welcome_section.dart     # Bagian sambutan
    │   ├── store/
    │   │   ├── data/
    │   │   │   └── store_repository.dart    # CRUD toko + app settings
    │   │   ├── domain/
    │   │   │   └── store_model.dart          # Model data toko
    │   │   └── presentation/
    │   │       ├── controllers/
    │   │       │   ├── store_list_controller.dart    # State daftar toko
    │   │       │   └── store_detail_controller.dart  # State detail toko
    │   │       ├── pages/
    │   │       │   ├── store_list_page.dart     # Halaman daftar toko
    │   │       │   ├── store_detail_page.dart   # Halaman detail toko
    │   │       │   └── store_form_page.dart     # Form tambah/edit toko
    │   │       └── widgets/
    │   │           ├── store_card.dart          # Kartu toko di list
    │   │           └── connection_badge.dart    # Badge tipe koneksi
    │   ├── ticket/
    │   │   ├── data/
    │   │   │   ├── ticket_repository.dart      # CRUD tiket
    │   │   │   └── ticket_email_service.dart   # Kirim email ke provider
    │   │   ├── domain/
    │   │   │   └── ticket_model.dart           # Model data tiket
    │   │   └── presentation/
    │   │       ├── ticket_controller.dart      # State & logic tiket
    │   │       ├── ticket_history_page.dart    # Halaman history tiket
    │   │       ├── dialogs/
    │   │       │   └── ticket_dialog.dart      # Dialog buat/edit tiket
    │   │       └── widgets/
    │   │           ├── ticket_card.dart        # Kartu tiket
    │   │           ├── ticket_dialogs.dart     # Dialog konfirmasi tiket
    │   │           ├── ticket_filter_panel.dart # Panel filter tiket
    │   │           └── ticket_ranking_tab.dart  # Tab ranking toko
    │   ├── network_tools/
    │   │   ├── ping/
    │   │   │   ├── data/
    │   │   │   │   └── ping_service.dart       # Engine ping + auto-ping
    │   │   │   └── presentation/
    │   │   │       ├── ping_controller.dart    # Wrapper ke PingService
    │   │   │       └── ping_page.dart          # Halaman ping scanner
    │   │   ├── ftp/
    │   │   │   ├── data/
    │   │   │   │   ├── ftp_client.dart         # FTP client wrapper
    │   │   │   │   └── ftp_service.dart        # FTP operations
    │   │   │   └── presentation/
    │   │   │       └── ftp_page.dart           # Halaman FTP manager
    │   │   └── wdcp/
    │   │       ├── data/
    │   │       │   ├── mikrotik_api_service.dart   # Mikrotik API protocol
    │   │       │   └── scan_rbwdcp_service.dart    # Scan WDCP di jaringan
    │   │       └── presentation/
    │   │           ├── scan_wdcp_page.dart     # Halaman scan RbWDCP
    │   │           └── wdcp_control_page.dart  # Halaman kontrol WDCP
    │   ├── profile/
    │   │   ├── data/
    │   │   │   └── profile_repository.dart    # Operasi profil user
    │   │   ├── domain/
    │   │   │   └── user_model.dart            # Model data user
    │   │   └── presentation/
    │   │       ├── profile_page.dart          # Halaman profil
    │   │       └── admin_panel_page.dart      # Halaman admin control center
    │   └── settings/
    │       ├── data/
    │       │   └── settings_repository.dart  # Pengaturan aplikasi
    │       └── presentation/
    │           ├── settings_page.dart         # Halaman pengaturan
    │           └── about_page.dart            # Halaman tentang aplikasi
    └── layout/
        ├── main_layout.dart                   # Shell layout (sidebar + content)
        └── app_sidebar.dart                   # Sidebar navigasi utama
```

---

## ✅ Prerequisites

Pastikan sudah terinstall:

```bash
# Flutter SDK (minimal 3.x)
flutter --version

# Dart SDK (minimal 3.9.2)
dart --version

# Git
git --version
```

**Platform requirement:**
- Windows 10/11 (untuk fitur Ping Scanner & WDCP)
- Minimum RAM: 4GB
- Koneksi internet untuk Supabase

---

## 🚀 Instalasi

```bash
# 1. Clone repository
git clone https://github.com/Pahruroji12/edp_netops.git
cd edp_netops

# 2. Install dependencies
flutter pub get

# 3. Setup environment (lihat section Environment Setup)
cp .env.example .env
# Edit .env dengan kredensial Supabase Anda

# 4. Generate launcher icons (opsional)
dart run flutter_launcher_icons
```

---

## 🔧 Environment Setup

Buat file `.env` di root project:

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

> ⚠️ **PENTING:** Jangan commit file `.env` ke repository. Pastikan sudah ada di `.gitignore`.

**Supabase Tables yang dibutuhkan:**
- `profiles` — data user (id, nik, nama, role, is_online, last_active)
- `stores` — data toko beserta semua IP
- `ticket_logs` — history tiket gangguan
- `activity_logs` — log aktivitas user
- `app_settings` — konfigurasi aplikasi (SMTP, path tools)

---

## ▶️ Menjalankan Aplikasi

```bash
# Development mode (Windows Desktop)
flutter run -d windows

# Dengan hot reload
flutter run -d windows --debug

# Lihat semua device yang tersedia
flutter devices
```

---

## 📊 Flow Aplikasi

```
App Start
    │
    ├── main.dart: Initialize
    │   ├── WindowManager (ukuran 1280x800)
    │   ├── dotenv.load('.env')
    │   ├── Supabase.initialize(url, anonKey)
    │   └── PingService.instance.init() ← restore auto-ping state
    │
    └── runApp(MyApp)
        │
        ├── MyApp (app.dart)
        │   └── MaterialApp.router(appRouter)
        │
        └── GoRouter (app_router.dart)
            │
            ├── /login → LoginPage (standalone, no sidebar)
            │   └── Login berhasil → AuthState.instance.setUser(...)
            │                      → navigate to /dashboard
            │
            └── ShellRoute (MainLayout = Sidebar + Content)
                ├── /dashboard  → DashboardPage
                ├── /store-list → StoreListPage → /store-detail/:id
                ├── /ticket-history → TicketHistoryPage
                ├── /ping       → PingPage (Windows only)
                ├── /scan-wdcp  → ScanWdcpPage → WdcpControlPage
                ├── /profile    → ProfilePage
                ├── /settings   → SettingsPage (admin only)
                ├── /admin      → AdminPanelPage (admin only)
                └── /about      → AboutPage
```

---

## 🗄️ Database Schema

### `profiles`
| Column | Type | Description |
|--------|------|-------------|
| id | uuid | FK ke auth.users |
| nik | text | Nomor Induk Karyawan |
| nama | text | Nama lengkap |
| role | text | user / admin / administrator |
| is_online | bool | Status online |
| last_active | timestamptz | Waktu aktif terakhir |

### `stores`
| Column | Type | Description |
|--------|------|-------------|
| id | uuid | Primary key |
| store_code | text | Kode toko (unik) |
| store_name | text | Nama toko |
| is_online | bool | Status koneksi |
| connection_type | text | Koneksi utama |
| connection_backup | text | Koneksi backup |
| ip_gateway | text | IP Mikrotik |
| ip_rb_wdcp | text | IP RB WDCP |
| ip_vsat | text | IP VSAT |
| ip_station_1..5 | text | IP kasir/PC |
| ip_stb | text | IP Set Top Box |
| ip_ikiosk | text | IP Price Checker |
| ip_timbangan | text | IP Timbangan digital |
| ip_cctv_1..2 | text | IP kamera CCTV |

### `ticket_logs`
| Column | Type | Description |
|--------|------|-------------|
| id | uuid | Primary key |
| store_code | text | Kode toko |
| store_name | text | Nama toko |
| provider | text | Provider ISP |
| nomor_tiket | text | Nomor tiket dari ISP |
| status | text | Open / In Progress / Resolved |
| created_by | text | Email user pembuat |
| created_at | timestamptz | Waktu buat |

### `activity_logs`
| Column | Type | Description |
|--------|------|-------------|
| id | uuid | Primary key |
| user_name | text | Nama user |
| user_role | text | Role user |
| action_type | text | LOGIN, LOGOUT, PING, EXPORT, dll |
| description | text | Detail aksi |
| created_at | timestamptz | Waktu log |

### `app_settings`
| Column | Type | Description |
|--------|------|-------------|
| key | text | Nama setting |
| value | text | Nilai setting |

---

## 📦 Dependency Utama

```yaml
dependencies:
  supabase_flutter: ^2.12.0   # Backend & Auth
  go_router: ^17.2.0           # Deklaratif routing
  google_fonts: ^8.0.2         # Typography
  flutter_dotenv: ^6.0.0       # Environment variables
  window_manager: ^0.5.1       # Desktop window control
  mailer: ^7.1.0               # Kirim email SMTP
  teledart: ^0.6.1             # Telegram bot notifikasi
  ftpconnect: ^2.0.10          # FTP client
  excel: ^4.0.6                # Generate file Excel
  file_picker: ^10.3.10        # Pilih file dari sistem
  path_provider: ^2.1.5        # Akses direktori sistem
  share_plus: ^12.0.1          # Share file (mobile)
  dart_ping: ^9.0.1            # ICMP ping
  crypto: ^3.0.7               # SHA-256 & MD5 hashing
  csv: ^6.0.0                  # Generate CSV
  intl: ^0.20.2                # Format tanggal & angka
  image_picker: ^1.2.2         # Ambil gambar
```

---

## 📦 Build Desktop

```bash
# Build release untuk Windows
flutter build windows --release

# Output tersedia di:
# build/windows/x64/runner/Release/

# Untuk distribusi, zip folder Release/ atau buat installer dengan Inno Setup
```

**Minimum Windows Build Requirements:**
- Visual Studio 2022 (dengan Desktop development with C++)
- Windows 10 SDK

---

## 🔒 Security Notes

> ⚠️ **Perhatian untuk Production:**

1. **`.env` sebagai asset** — Saat ini `.env` di-bundle dalam binary. Untuk keamanan lebih, pertimbangkan:
   - Enkripsi file konfigurasi
   - Simpan config di `%AppData%` setelah install pertama
   
2. **Supabase RLS (Row Level Security)** — Pastikan semua tabel memiliki RLS policies yang tepat di Supabase dashboard.

3. **Role-based Access** — Role `administrator` dan `admin` dibedakan di level aplikasi. Pastikan RLS juga mengenforse ini di database.

4. **Auto-Ping** berjalan sebagai background Timer. Pastikan user sudah login sebelum auto-ping diaktifkan.

5. **Mikrotik API** — Username dan password router dikirim via TCP socket. Gunakan jaringan internal yang aman.

---

## 🔍 Troubleshooting

### Build error: Windows SDK not found
```bash
# Install Visual Studio Build Tools
# https://visualstudio.microsoft.com/downloads/
# Pilih: Desktop development with C++
```

### Login gagal / Supabase error
```bash
# Cek .env sudah benar
cat .env

# Pastikan Supabase project aktif dan tidak pause
# Cek di: https://app.supabase.com
```

### Ping tidak berjalan
```bash
# Ping Scanner hanya tersedia di Windows
# Pastikan menjalankan sebagai Administrator jika perlu
```

### Auto-Ping tidak aktif setelah restart
```bash
# Auto-ping state disimpan di SharedPreferences
# Buka halaman Ping → toggle Auto-Ping STB kembali
```

### Export Excel gagal
```bash
# Pastikan folder Downloads ada dan dapat diakses
# Cek permission folder di Windows Explorer
```

### Window tidak muncul
```bash
# Cek apakah ada error di console
flutter run -d windows --verbose
```

---

## 🚀 Future Improvement

- [ ] **Route Guard** — Implementasi auth redirect otomatis via GoRouter `redirect`
- [ ] **Reusable ConfirmDialog** — Centralize semua dialog konfirmasi
- [ ] **PingController refactor** — Pisahkan UI logic dari PingService
- [ ] **Unit Testing** — Coverage untuk repository & controller layer
- [ ] **Riverpod Migration** — Jika team bertambah > 3 developer
- [ ] **Offline Mode** — Cache data toko untuk akses tanpa internet
- [ ] **Push Notification** — Notifikasi real-time via Supabase Realtime
- [ ] **Dashboard Chart** — Visualisasi tren tiket gangguan
- [ ] **Dark/Light Theme per Feature** — Theme persistence ke database
- [ ] **Installer Packaging** — Inno Setup untuk distribusi mudah
- [ ] **Auto Update** — In-app update checker
- [ ] **Audit Trail** — Riwayat perubahan data toko
- [ ] **Export PDF** — Laporan PDF selain Excel

---

## 👨‍💻 Author

<div align="center">

**Pahruroji**  
*IT Support & Network Operations — Departemen EDP*

[![GitHub](https://img.shields.io/badge/GitHub-Pahruroji12-181717?style=flat-square&logo=github)](https://github.com/Pahruroji12)

</div>

---

<div align="center">

**EDP NetOps v2.7.0** — *Built with ❤️ using Flutter & Supabase*

© 2026 Departemen EDP. All Rights Reserved.

</div>
