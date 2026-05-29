<div align="center">

<img src="assets/logo.png" alt="EDP NetOps Logo" width="120" height="120" style="border-radius: 24px; box-shadow: 0 8px 24px rgba(0,0,0,0.15);"/>

# EDP NetOps

**Pusat Kendali IT Support & Network Operations Departemen EDP**

*Sebuah platform terintegrasi yang dirancang khusus untuk memantau infrastruktur jaringan, mengelola data toko secara dinamis, mengotomatisasi sinkronisasi tiket gangguan, dan mempercepat tindakan operasional lapangan dalam satu dasbor modern.*

---

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.9.2-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-2.12.x-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.3.x-3178C6?style=for-the-badge&logo=typescript&logoColor=white)](https://www.typescriptlang.org/)
[![NodeJS](https://img.shields.io/badge/Node.js-20.x-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)](https://nodejs.org)
[![Platform](https://img.shields.io/badge/Platform-Windows%20Desktop-0078D6?style=for-the-badge&logo=windows&logoColor=white)](https://flutter.dev/desktop)

</div>

---

## 📋 Daftar Isi

1. [Deskripsi Project](#-deskripsi-project)
2. [Fitur Utama](#-fitur-utama)
3. [Arsitektur Sistem & Alur Kerja](#%EF%B8%8F-arsitektur-sistem--alur-kerja)
4. [Teknologi yang Digunakan](#-teknologi-yang-digunakan)
5. [Struktur Folder Project](#-struktur-folder-project)
6. [Konfigurasi Database & Environment](#%EF%B8%8F-konfigurasi-database--environment)
7. [Panduan Instalasi & Menjalankan Project](#-panduan-instalasi--menjalankan-project)
8. [Panduan Build & Deploy](#-panduan-build--deploy)
9. [Troubleshooting & Solusi](#-troubleshooting--solusi)
10. [Kebijakan Keamanan (Security Notes)](#-kebijakan-keamanan-security-notes)
11. [Rencana Pengembangan (Future Improvements)](#-rencana-pengembangan-future-improvements)
12. [Kontribusi](#-kontribusi)
13. [Lisensi](#-lisensi)
14. [Author & Developer](#-author--developer)

---

## 📖 Deskripsi Project

**EDP NetOps** adalah solusi sistem manajemen internal berskala enterprise yang dirancang khusus untuk memfasilitasi kebutuhan **IT Support & Network Operations di Departemen EDP**. Platform ini dikembangkan secara modular untuk menjamin efisiensi tinggi dalam memantau kesehatan jaringan ratusan toko, merespons kendala secara real-time, serta mengotomatisasi pencatatan tiket kendala provider.

Sistem ini terbagi menjadi dua komponen utama yang saling berkolaborasi:
1. **EDP NetOps Client Application**: Aplikasi desktop native Windows berbasis **Flutter** yang menyajikan antarmuka visual (dashboard) interaktif, monitoring status perangkat toko, tool operasional (Winbox, VNC, Telnet, Ping), serta manajemen tiket gangguan.
2. **EDP NetOps IMAP Ticket Sync Worker**: Layanan background daemon berbasis **TypeScript & Node.js** yang bertugas memantau email masuk (IMAP) dari berbagai provider internet ISP (Astinet, ICON, Fiberstar), mengekstrak nomor tiket dan kode toko secara otomatis menggunakan algoritma parsing regex cerdas, lalu menyinkronkannya langsung ke database **Supabase**.

---

## ✨ Fitur Utama

### 🖥️ Dasbor Utama & Monitoring Toko
* **Real-time Overview**: Menampilkan total toko aktif secara visual beserta pembagian jenis koneksi utama yang digunakan (Fiber Optik, VSAT, GSM, XL).
* **Smart Search & Filter**: Pencarian toko dengan respon instan berdasarkan kode toko, nama toko, tipe koneksi, atau status online/offline.
* **Informasi Perangkat Toko**: Menyimpan data teknis krusial secara lengkap (IP Gateway Mikrotik, IP VSAT, RB WDCP, Station 1-5, STB Kasir, iKiosk, Timbangan, CCTV).
* **Integrasi Remote Tool**: Akses remote cepat ke Winbox, VNC, dan Telnet langsung dari aplikasi melalui path utility eksternal yang dapat disesuaikan.
* **Export Data Dinamis**: Fitur export seluruh daftar dan detail data toko ke format spreadsheet Excel (`.xlsx`) dengan penataan tabel yang rapi.

### 🎫 Manajemen Tiket Gangguan (History Ticket)
* **Pencatatan Otomatis & Manual**: Tiket dapat dibuat secara manual melalui UI interaktif atau di-ingest secara otomatis dari inbox email provider oleh sistem Worker.
* **Sistem Filter Komprehensif**: Filter tiket berdasarkan status (`Open`, `In Progress`, `Resolved`), ISP Provider, serta filter waktu (Bulan & Tahun).
* **Analisis Data & Ranking**: Menyajikan peringkat (ranking) toko yang paling sering mengalami gangguan sebagai bahan evaluasi stabilitas jaringan toko.
* **Email Notifikasi Otomatis**: Integrasi SMTP Mailer untuk mengirimkan notifikasi eskalasi tiket gangguan secara langsung ke email provider ISP.
* **Export Laporan Multi-Sheet**: Export data tiket historis langsung ke dokumen Excel dengan pemisahan sheet laporan detail dan sheet rangkuman analitik.

### 🌐 Network Tools (Windows Desktop Native)
* **Ping Scanner Massal**: Mesin pemindai ICMP berbasis multi-threaded untuk memeriksa status koneksi IP Gateway, kasir (Station 1-5), STB, RB WDCP, hingga CCTV di seluruh toko secara cepat.
* **Scheduled Auto-Ping STB**: Fitur pemantauan terjadwal khusus untuk STB toko pada shift malam (00:00 - 03:59), berguna mendeteksi perangkat offline sebelum jam operasional dimulai.
* **Integrasi Mikrotik WDCP via API**:
  * Membaca *Registration Table* (melihat daftar perangkat kasir yang terhubung secara nirkabel).
  * Manajemen *Access List* (menambah/menghapus whitelist MAC Address perangkat kasir).
  * Pengaturan *Default Authentication* (aktif/nonaktif keamanan koneksi dasar).
  * Pemantauan resource Routerboard (CPU Load, Free Memory, Uptime).

### 👤 Administrasi, Keamanan & Pengaturan
* **Manajemen Profil Pengguna**: Fitur ganti kata sandi dengan enkripsi hash SHA-256 yang aman di sisi klien.
* **Kontrol Panel Administrator**: Halaman khusus admin untuk memantau performa tim EDP, serta mengelola akun (tambah/hapus user).
* **Audit Trail (Activity Logger)**: Pencatatan otomatis setiap aktivitas penting yang dilakukan pengguna (Login, Logout, Ping Scanner, Export Data) ke tabel log Supabase untuk kebutuhan audit.
* **Konfigurasi Fleksibel**: Pengaturan parameter aplikasi seperti kredensial SMTP Email provider dan path binary software eksternal (Winbox, VNC, Telnet) yang disimpan persisten per perangkat.
* **Dual Theme Engine**: Dukungan penuh tema Gelap (Dark Mode) dan Terang (Light Mode) yang nyaman di mata dan tersimpan secara otomatis antar-sesi.

---

## ⚙️ Arsitektur Sistem & Alur Kerja

Platform EDP NetOps menerapkan arsitektur modular yang tersegregasi secara rapi. Aplikasi Flutter Client dibangun dengan pola **Feature-based Layered Architecture** (Clean Architecture) guna memisahkan urusan UI, logika bisnis, dan pengambilan data.

### 🔄 Alur Integrasi Tiket Otomatis

```
  [ Provider ISP ] ─── Sending Email ───► [ Email Server (IMAP) ]
                                                   │
                                            Fetched by IMAP
                                                   │
                                                   ▼
                                      ┌────────────────────────┐
                                      │  IMAP Sync Worker TS   │
                                      │   - Parse Email Content│
                                      │   - Match Store Code   │
                                      │   - Extract Ticket No  │
                                      └───────────┬────────────┘
                                                  │
                                             Syncs Data
                                                  │
                                                  ▼
                                      ┌────────────────────────┐
                                      │   Supabase Database    │
                                      │   (Real-time State)    │
                                      └───────────┬────────────┘
                                                  │
                                            Stream Updates
                                                  │
                                                  ▼
                                      ┌────────────────────────┐
                                      │  EDP NetOps Client     │
                                      │  (Flutter Desktop App) │
                                      └────────────────────────┘
```

### 🏛️ Detail Lapisan Aplikasi Client (Flutter)

* **Presentation Layer**: Terdiri dari berkas *Page*, *Widget*, dan *Controller*. Logika tampilan dipisahkan menggunakan pola `ChangeNotifier` / `Controller` yang dipantau oleh `ListenableBuilder` pada berkas UI.
* **Domain Layer**: Berisi pemodelan data (*Model*) serta manajemen state global (seperti `auth_state.dart`).
* **Data Layer**: Berisi implementasi *Repository* dan *Service* yang berinteraksi langsung dengan REST API/Websocket Supabase dan sistem operasi lokal.
* **Core Layer**: Menyimpan aset tema global, komponen UI pakai ulang (*custom widgets*), helper utilitas enkripsi, ekspor file, dan kelas utilitas platform.

---

## 🛠️ Teknologi yang Digunakan

### 📱 EDP NetOps Client (Flutter App)

| Komponen / Library | Kegunaan Utama | Versi |
| :--- | :--- | :--- |
| **Flutter SDK** | Framework Utama (Cross-Platform) | `^3.x` |
| **Dart SDK** | Bahasa Pemrograman | `^3.9.2` |
| **Supabase Flutter** | Database Backend, Real-time Stream & Authentication | `^2.12.0` |
| **Go Router** | Sistem Navigasi Deklaratif & Route Guarding | `^17.2.0` |
| **Window Manager** | Kontrol Ukuran, Posisi & Frame Jendela Windows | `^0.5.1` |
| **Teledart** | Integrasi Pengiriman Notifikasi via Telegram Bot | `^0.6.1` |
| **Excel** | Pembuatan Dokumen Spreadsheets XLSX secara Native | `^4.0.6` |
| **FTP Connect** | Client Protokol FTP untuk Transfer Berkas | `^2.0.10` |
| **Dart Ping** | Utilitas Eksekusi Perintah ICMP Ping Native | `^9.0.1` |
| **Mailer** | Pengiriman Email SMTP ke Pihak Ketiga (Provider) | `^7.1.0` |
| **Google Fonts** | Pengaturan Tipografi UI yang Elegan & Konsisten | `^8.0.2` |

### ⚙️ Background Ticket Sync Worker (TypeScript)

| Library / Tool | Kegunaan Utama | Versi |
| :--- | :--- | :--- |
| **TypeScript** | Bahasa Pemrograman Utama (Typed JavaScript) | `^5.3.3` |
| **Node.js** | Environment Runtime Eksekusi Worker | `v20.x` |
| **Supabase JS Client** | Koneksi Client Database & Manipulasi Data Tabel | `^2.39.8` |
| **ImapFlow** | Client IMAP Modern dengan Dukungan Async/Await | `^1.0.155` |
| **Mailparser** | Parser Berkas Email IMAP Menjadi Struktur JSON | `^3.7.1` |
| **TSX** | Eksekutor & Live Reloader TypeScript File secara Cepat | `^4.7.0` |

---

## 📁 Struktur Folder Project

Struktur berkas dan direktori dirancang dengan sangat rapi untuk memisahkan logika desktop client dengan background worker:

```text
edp_netops/
├── assets/                          # Aset gambar & logo aplikasi
│   └── logo.png                     # Logo utama EDP NetOps
├── android/                         # Konfigurasi platform Android
├── ios/                             # Konfigurasi platform iOS
├── web/                             # Konfigurasi platform Flutter Web
├── windows/                         # Konfigurasi native platform Windows Desktop
├── lib/                             # Kode Sumber Flutter Client
│   ├── main.dart                    # Entry point aplikasi (Inisialisasi dasar saja)
│   ├── app/                         # Konfigurasi aplikasi tingkat atas (App Widget, Router)
│   │   ├── app.dart                 # Root MaterialApp.router & Setup Tema
│   │   └── app_router.dart          # Konfigurasi rute GoRouter & AuthGuard
│   ├── core/                        # Modul pendukung global (Shared Core)
│   │   ├── constants/               # Konstanta global aplikasi
│   │   ├── env/                     # Loader berkas konfigurasi .env
│   │   ├── guards/                  # Proteksi akses rute berdasarkan izin
│   │   ├── theme/                   # Pengaturan warna & ThemeData (Dark/Light)
│   │   ├── utils/                   # Helper enkripsi, export Excel, dll.
│   │   └── widgets/                 # Reusable widget seperti Custom Snackbar, dll.
│   ├── layout/                      # Tata letak antarmuka utama (Sidebar & Base Layout)
│   └── features/                    # Direktori fitur utama aplikasi (Clean Architecture)
│       ├── auth/                    # Modul Login, Autentikasi, & State Akun
│       ├── dashboard/               # Modul Dasbor Utama & List Toko Ringkas
│       ├── network_tools/           # Modul Alat Jaringan (Ping Scanner, FTP, Mikrotik WDCP)
│       ├── store/                   # Modul Manajemen & CRUD Data Toko Lengkap
│       ├── ticket/                  # Modul Pencatatan Tiket & Email Provider
│       ├── profile/                 # Halaman detail akun & admin panel control
│       └── settings/                # Halaman pengaturan SMTP & path software remote
│
└── worker-ticket-sync/              # Kode Sumber Background IMAP Sync Worker
    ├── src/                         # Berkas Utama TypeScript
    │   ├── main.ts                  # Entry point scheduler & inisialisasi server worker
    │   ├── config.ts                # Loader parameter lingkungan .env worker
    │   ├── server.ts                # Server HTTP minimal untuk REST monitoring & status
    │   ├── imapClient.ts            # Client penghubung ke Mailbox IMAP
    │   ├── supabaseClient.ts        # Client koneksi terpusat ke database Supabase
    │   ├── syncTicketEmail.ts       # Mesin logika sinkronisasi email-ke-tabel
    │   ├── ticketParser.ts          # Algoritma ekstraksi kode toko & nomor tiket
    │   ├── workerStatusService.ts   # Updater detak jantung status worker ke database
    │   └── types.ts                 # Definisi tipe data & antarmuka TypeScript
    ├── package.json                 # Skrip NPM & dependensi Node.js worker
    ├── tsconfig.json                # Konfigurasi kompilasi TypeScript Compiler
    └── .env.example                 # Contoh templat konfigurasi variabel worker
```

---

## 🖥️ Konfigurasi Database & Environment

### 1. Setup Variabel Lingkungan (.env)

Buatlah berkas bernama `.env` pada folder root project untuk konfigurasi **Flutter Client**:

```env
SUPABASE_URL=https://id-project-anda.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

Buat juga berkas `.env` di dalam sub-direktori `worker-ticket-sync/` untuk konfigurasi **Background Worker**:

```env
# Kredensial Supabase (Wajib menggunakan Service Role Key untuk bypass RLS)
SUPABASE_URL=https://id-project-anda.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Port Server HTTP Monitoring
PORT=8080

# Interval Auto-Sync (dalam satuan menit)
SYNC_INTERVAL_MINUTES=10

# Jam Operasional Sync Worker (Format Desimal, contoh 22.5 = 22:30 WIB)
WORKING_HOUR_START=6
WORKING_HOUR_END=22.5

# Konfigurasi Akun IMAP (Opsional, dapat diletakkan di tabel app_settings Supabase)
IMAP_HOST=imap.example.com
IMAP_PORT=993
IMAP_USER=support-netops@example.com
IMAP_PASS=password-email-anda
IMAP_SECURE=true
```

> [!WARNING]
> Jangan pernah mengunggah (*commit*) berkas `.env` ke repositori publik seperti GitHub karena berisi kredensial sensitif. Berkas tersebut sudah otomatis dikecualikan lewat berkas `.gitignore`.

### 2. Skema Tabel Database Supabase

Untuk mendukung fungsionalitas penuh aplikasi EDP NetOps, pastikan tabel-tabel berikut telah dikonfigurasi di PostgreSQL database Supabase Anda:

#### Tabel `profiles`
Menyimpan data otorisasi dan profil dari staf operasional EDP.
* `id` (`uuid`, Primary Key, Foreign Key ke `auth.users`)
* `nik` (`text`, Nomor Induk Karyawan unik)
* `nama` (`text`, Nama lengkap staf)
* `role` (`text`, Hak akses: `user` / `admin` / `administrator`)
* `is_online` (`boolean`, Menandakan status aktif di aplikasi)
* `last_active` (`timestamp with time zone`, Detak waktu aktif terakhir)

#### Tabel `stores`
Menyimpan parameter teknis infrastruktur jaringan di masing-masing lokasi toko.
* `id` (`uuid`, Primary Key)
* `store_code` (`text`, Kode toko unik, contoh: `T567` atau `TGPJ`)
* `store_name` (`text`, Nama lengkap toko)
* `is_online` (`boolean`, Status jaringan toko saat pemindaian terakhir)
* `connection_type` (`text`, Jalur koneksi utama: `FO` / `VSAT` / `GSM` / `XL`)
* `connection_backup` (`text`, Jalur koneksi cadangan)
* `ip_gateway` (`text`, IP Router Mikrotik)
* `ip_rb_wdcp` (`text`, IP Router Board Wireless)
* `ip_vsat` (`text`, IP modem VSAT)
* `ip_station_1` s.d `ip_station_5` (`text`, IP komputer kasir/backoffice)
* `ip_stb` (`text`, IP Set Top Box media)
* `ip_ikiosk` (`text`, IP perangkat informasi harga)
* `ip_timbangan` (`text`, IP timbangan digital toko)
* `ip_cctv_1` s.d `ip_cctv_2` (`text`, IP kamera CCTV pemantau)

#### Tabel `ticket_logs`
Menyimpan riwayat tiket gangguan jaringan ISP untuk analisis performa penyedia internet.
* `id` (`uuid`, Primary Key)
* `store_code` (`text`, Kode toko terdampak)
* `store_name` (`text`, Nama toko terdampak)
* `provider` (`text`, ISP bersangkutan: `Astinet` / `ICON` / `Fiberstar`)
* `nomor_tiket` (`text`, Nomor resmi tiket pelaporan gangguan)
* `status` (`text`, Status penanganan: `Open` / `In Progress` / `Resolved`)
* `created_by` (`text`, Staf pembuat tiket / `System Worker`)
* `created_at` (`timestamp with time zone`, Waktu pembukaan tiket)

#### Tabel `activity_logs`
Merekam jejak audit keamanan seluruh aktivitas pengguna sistem.
* `id` (`uuid`, Primary Key)
* `user_name` (`text`, Staf pelaku aktivitas)
* `user_role` (`text`, Role dari pelaku)
* `action_type` (`text`, Jenis aksi: `LOGIN`, `LOGOUT`, `PING SCAN`, `EXPORT`, dll.)
* `description` (`text`, Rincian deskripsi mengenai tindakan yang dilakukan)
* `created_at` (`timestamp with time zone`, Waktu terjadinya log)

#### Tabel `app_settings`
Menyimpan konfigurasi aplikasi global secara dinamis dan aman.
* `key` (`text`, Nama kunci konfigurasi, Primary Key)
* `value` (`text`, Nilai string konfigurasi)

---

## 🚀 Panduan Instalasi & Menjalankan Project

### Prerequisites
Sebelum memulai, pastikan lingkungan pengembangan Anda telah terpasang perkakas berikut:
* **Flutter SDK** (Versi minimal `3.22.x` direkomendasikan)
* **Dart SDK** (Versi minimal `3.9.2` atau bawaan Flutter)
* **Node.js Runtime** (Versi `v18.x` atau `v20.x` LTS)
* **Visual Studio 2022** (dengan beban kerja *Desktop Development with C++* aktif, untuk build aplikasi desktop di Windows)
* **Git** untuk pengelolaan repositori

---

### A. Konfigurasi & Menjalankan Flutter Client

```bash
# 1. Clone repositori ke penyimpanan lokal Anda
git clone https://github.com/Pahruroji12/edp_netops.git
cd edp_netops

# 2. Ambil seluruh pustaka dependensi Flutter
flutter pub get

# 3. Buat dan sesuaikan berkas .env
cp .env.example .env
# [Lakukan pengeditan pada berkas .env menggunakan editor teks Anda]

# 4. Buat aset ikon peluncur aplikasi (Opsional)
dart run flutter_launcher_icons

# 5. Jalankan aplikasi dalam mode pengembangan (Windows Desktop)
flutter run -d windows
```

Untuk meluncurkan proses pengembangan dengan debugger aktif dan fitur *Hot Reload* penuh:
```bash
flutter run -d windows --debug
```

---

### B. Konfigurasi & Menjalankan Background Ticket Sync Worker

```bash
# 1. Navigasi masuk ke direktori background worker
cd worker-ticket-sync

# 2. Pasang seluruh pustaka dependensi Node.js
npm install

# 3. Buat dan sesuaikan berkas .env milik worker
cp .env.example .env
# [Buka berkas .env worker dan lengkapi kredensial Supabase & IMAP Anda]

# 4. Jalankan Worker pada lingkungan lokal dalam mode Live Reload (Development)
npm run dev
```

Untuk menjalankan Worker secara langsung tanpa kompilasi manual dalam mode produksi lokal:
```bash
npm run start
```

---

## 📦 Panduan Build & Deploy

### 1. Mengompilasi Rilis Flutter Client (Windows Desktop)

Untuk mendistribusikan aplikasi EDP NetOps ke staf EDP di lapangan, kompilasi aplikasi ke dalam bentuk file binary executable:

```bash
# Kompilasi ke binary rilis Windows
flutter build windows --release
```

Hasil kompilasi final yang siap didistribusikan akan berada di direktori:
`build/windows/x64/runner/Release/`

> [!TIP]
> Agar distribusi ke staf operasional lebih profesional, Anda dapat membungkus seluruh isi folder `Release/` menjadi satu installer berkas tunggal (.exe) menggunakan alat bantu pembuat installer pihak ketiga seperti **Inno Setup** atau **Advanced Installer**.

---

### 2. Mengompilasi & Menyebarkan Ticket Sync Worker

Untuk menyebarkan worker ke server lokal atau VPS Windows/Linux agar berjalan terus menerus secara independen:

```bash
# 1. Masuk ke direktori worker
cd worker-ticket-sync

# 2. Kompilasi kode TypeScript menjadi JavaScript murni (CommonJS)
npm run build

# 3. Jalankan aplikasi hasil kompilasi dari folder dist/
npm run serve
```

Agar proses di server tetap hidup meskipun terminal ditutup, Anda direkomendasikan menjalankan worker menggunakan manager proses seperti **PM2**:
```bash
# Daftarkan dan jalankan worker dengan PM2
pm2 start dist/main.js --name "edp-ticket-worker"

# Menyimpan konfigurasi agar otomatis berjalan saat server restart/reboot
pm2 save
pm2 startup
```

---

## 🔍 Troubleshooting & Solusi

### ❌ Masalah 1: Kesalahan Kompilasi "Windows SDK Not Found" atau "Visual Studio C++ Desktop workload"
* **Penyebab**: Perangkat Anda belum terpasang compiler C++ yang dibutuhkan untuk mengompilasi kode program C++ milik engine Flutter Windows.
* **Solusi**: Buka *Visual Studio Installer*, klik modify pada versi Visual Studio Anda, lalu centang bagian **Desktop development with C++**. Pastikan juga *Windows 10/11 SDK* terpilih di panel detail sebelah kanan, kemudian selesaikan instalasi/pembaruan.

### ❌ Masalah 2: Gagal Melakukan Operasi Ping pada Mesin Pemindai Jaringan (STB Offline / Timeout)
* **Penyebab**: Sistem operasi Windows memerlukan izin khusus (Privilege ICMP) untuk mengirim paket ICMP ping massal atau firewall lokal toko memblokir permintaan ICMP masuk.
* **Solusi**:
  1. Pastikan Anda menjalankan aplikasi EDP NetOps dengan hak akses administrator (*Run as Administrator*).
  2. Pastikan alamat IP perangkat (STB/CCTV) berada dalam segmen jaringan VPN/SD-WAN yang sama dan tidak diblokir oleh rules Mikrotik internal.

### ❌ Masalah 3: Autentikasi Supabase Gagal / Mengalami Loop di Halaman Login
* **Penyebab**: Konfigurasi kunci URL atau anon key pada `.env` salah, atau proyek Supabase Anda sedang dalam mode ditangguhkan (*paused*) oleh platform.
* **Solusi**: Periksa kembali berkas `.env` di folder utama aplikasi. Pastikan isi parameter URL dan kunci publik anonim sesuai dengan yang tertera di menu *Settings > API* pada dashboard Supabase Anda.

### ❌ Masalah 4: Sync Worker Tidak Menarik Email Apapun dari Mailbox
* **Penyebab**: Waktu eksekusi worker berada di luar rentang operasional yang diizinkan (parameter `WORKING_HOUR_START` dan `WORKING_HOUR_END`), atau port IMAP diblokir oleh firewall server Anda.
* **Solusi**: Sesuaikan jam operasional pada berkas `.env` worker agar mencakup jam pengetesan Anda saat ini. Pastikan pula konfigurasi port IMAP Anda adalah `993` (untuk SSL/TLS aman) atau `143` (tanpa SSL).

---

## 🔒 Kebijakan Keamanan (Security Notes)

1. **Proteksi Kredensial Desktop (.env)**: Pada platform Windows Desktop, berkas konfigurasi `.env` dibaca secara dinamis dari folder eksternal aplikasi saat runtime, bukan dibungkus secara permanen di dalam binary rilis. Hal ini mencegah dekompilasi aplikasi yang dapat membocorkan kredensial Supabase.
2. **Supabase Row Level Security (RLS)**: Sangat direkomendasikan untuk mengaktifkan RLS pada seluruh tabel di dashboard Supabase. Gunakan aturan otorisasi berbasis peran user (`profiles.role`) agar staf dengan peran biasa (`user`) tidak dapat menghapus atau merusak data konfigurasi sistem (`app_settings`).
3. **Bypass RLS Khusus Worker**: Worker tiket berjalan di lingkungan server tertutup, menggunakan kunci tingkat tinggi `SUPABASE_SERVICE_ROLE_KEY` untuk memungkinkan pencatatan log tiket secara otomatis bypass filter RLS demi efisiensi tinggi. Jaga kerahasiaan kunci ini di tingkat server.
4. **Enkripsi Data Kredensial**: Data kata sandi SMTP email dan data konfigurasi sensitif yang disimpan pada tabel database telah dienkripsi secara aman untuk menghindari akses tidak sah langsung ke server email internal perusahaan.

---

## 🚀 Rencana Pengembangan (Future Improvements)

* [ ] **Riverpod State Management**: Rencana migrasi penuh manajemen state dari `ChangeNotifier` ke `Riverpod` guna mempermudah pengujian unit (*Unit Testing*) jika tim pengembang bertambah besar.
* [ ] **In-App Auto Update**: Integrasi modul pendeteksi pembaruan otomatis untuk mengunduh versi rilis aplikasi terbaru langsung dari server penyimpanan internal.
* [ ] **Visualisasi Dashboard Grafik (Dashboard Chart)**: Menambahkan visualisasi tren grafik gangguan ISP mingguan/bulanan memanfaatkan pustaka grafik `fl_chart`.
* [ ] **Mode Luring (Offline Mode Cache)**: Implementasi penyimpanan lokal terenkripsi (SQLite/Hive) agar data toko tetap dapat dibaca untuk kebutuhan darurat saat jaringan internet internal padam.
* [ ] **Penyusunan Paket Installer Otomatis**: Memasukkan proses pengemasan *Inno Setup* ke dalam pipa otomatis CI/CD GitHub Actions.

---

## 🤝 Kontribusi

Kontribusi dari seluruh tim IT Support & Network Operations sangat dihargai untuk menyempurnakan kegunaan sistem ini:

1. Buat salinan repositori ini (*Fork*).
2. Buat cabang fitur baru Anda (`git checkout -b fitur/fitur-keren-anda`).
3. Lakukan penyimpanan perubahan kode Anda (`git commit -m 'Menambahkan fitur baru yang luar biasa'`).
4. Unggah cabang baru Anda ke repositori asal (`git push origin fitur/fitur-keren-anda`).
5. Buat permohonan penarikan kode baru (*Pull Request*) di GitHub untuk kami tinjau bersama.

---

## 📄 Lisensi

Proyek perangkat lunak ini dirilis secara **Private** dan eksklusif untuk kebutuhan operasional internal **Departemen EDP**. Dilarang mendistribusikan, mempublikasikan ulang, atau menjual kembali kode sumber ini di luar izin resmi manajemen departemen.

---

## 👨‍💻 Author & Developer

<div align="center">

**Pahru Roji**  
*Senior IT Support & Network Operations — Departemen EDP*

[![GitHub](https://img.shields.io/badge/GitHub-Pahruroji12-181717?style=flat-square&logo=github&logoColor=white)](https://github.com/Pahruroji12)

---

**EDP NetOps Platform v2.7.0** — *Built with Professional Passion using Flutter & TypeScript*  
© 2026 Departemen EDP. Hak Cipta Dilindungi Undang-Undang.

</div>
