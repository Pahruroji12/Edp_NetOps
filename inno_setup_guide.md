# Panduan & Strategi Pengemasan Installer (Inno Setup)
> [!NOTE]
> Panduan ini disusun untuk memberikan gambaran arsitektur, alur kerja, dan contoh konfigurasi untuk mengemas aplikasi **EDP NetOps** beserta background worker Node.js, Winbox, dan VNC Viewer ke dalam satu installer `.exe` terpadu menggunakan **Inno Setup**.

---

## 1. Penggabungan Background Worker (`worker-ticket-sync`)

**Ya, file worker sangat bisa digabungkan ke dalam installer!** Ini adalah praktik terbaik agar pengguna tidak perlu mengunduh file worker secara terpisah.

### a. Struktur Folder Hasil Instalasi di Komputer Pengguna:
Ketika installer dijalankan, Inno Setup akan mengekstrak semua file ke folder default (misalnya `C:\Program Files\EDP NetOps\`). Strukturnya akan menjadi seperti ini:

```
C:\Program Files\EDP NetOps\
├── edp_netops.exe (Aplikasi Flutter utama)
├── flutter_windows.dll (Library pendukung)
├── data/ (File bawaan Flutter)
└── worker/ (Folder worker Node.js)
    ├── dist/
    │   └── main.js (File JS yang sudah dicompile)
    ├── node_modules/ (Dependencies NodeJS)
    ├── package.json
    └── start_hidden.vbs
```

### b. Konfigurasi Script Inno Setup (`.iss`):
Di dalam file konfigurasi Inno Setup, kita cukup menyertakan folder worker hasil kompilasi ke dalam bagian `[Files]`:

```iss
[Files]
; Salin aplikasi utama Flutter
Source: "D:\DartProject\edp_netops\build\windows\x64\runner\Release\edp_netops.exe"; DestDir: "{app}"; Flags: ignoreversion

; Salin folder worker Node.js secara rekursif
Source: "D:\DartProject\edp_netops\worker-ticket-sync\*"; DestDir: "{app}\worker"; Flags: recursesubdirs createallsubdirs ignoreversion
```

---

## 2. Mengubah Path Menjadi Dinamis (Menghilangkan `D:\Edp NetOps`)

Saat ini, path file masih di-hardcode ke `D:\Edp NetOps`. Jika aplikasi diinstal di `C:\Program Files\EDP NetOps\`, aplikasi akan gagal menemukan file tersebut.

### Solusi Dinamis di Flutter:
Kita dapat menggunakan properti `Platform.resolvedExecutable` di Dart untuk mendapatkan lokasi file `.exe` yang sedang berjalan secara dinamis saat runtime, lalu mencari folder `worker` di sekitarnya.

#### Contoh implementasi pendeteksian folder worker dinamis:
```dart
import 'dart:io';

Future<String> getDynamicWorkerPath() async {
  // Mengambil path lengkap file exe yang sedang berjalan
  // Contoh: "C:\Program Files\EDP NetOps\edp_netops.exe"
  final String exePath = Platform.resolvedExecutable;
  
  // Mengambil folder tempat exe berada
  // Contoh: "C:\Program Files\EDP NetOps"
  final String appDir = File(exePath).parent.path;
  
  // Mengarahkan ke sub-folder worker
  // Contoh: "C:\Program Files\EDP NetOps\worker"
  return '$appDir\\worker';
}
```

---

## 3. Sistem Auto-Detection untuk Winbox & VNC Viewer

Untuk Winbox dan VNC Viewer, kita bisa membuat sistem **Pencarian Bertingkat (Multi-Layer Detection)**. Aplikasi akan mencari file secara otomatis dengan urutan prioritas berikut:

```
[Layer 1: Bundled Folder] ──► Cek apakah winbox/vnc ada di folder instalasi aplikasi kita
         │ (Tidak ketemu)
         ▼
[Layer 2: System PATH] ─────► Jalankan perintah 'where winbox' untuk cek environment PATH
         │ (Tidak ketemu)
         ▼
[Layer 3: Default Install] ─► Cek di folder Program Files default (misal: UltraVNC)
         │ (Tidak ketemu)
         ▼
[Layer 4: User Manual] ─────► Biarkan user memilih file secara manual via File Picker & simpan di Settings
```

### a. Detail Implementasi Deteksi Bertingkat:

#### Layer 1: Lokasi Bundled (Direkomendasikan)
Kita bisa memasukkan `winbox.exe` dan `vncviewer.exe` langsung ke dalam installer Inno Setup di folder `tools`. Jadi, user tidak perlu men-download lagi!
*   **Inno Setup Config:**
    ```iss
    Source: "D:\Edp NetOps\winbox.exe"; DestDir: "{app}\tools"; Flags: ignoreversion
    Source: "D:\Edp NetOps\vncviewer.exe"; DestDir: "{app}\tools"; Flags: ignoreversion
    ```
*   **Flutter Code:**
    ```dart
    final String appDir = File(Platform.resolvedExecutable).parent.path;
    final String bundledWinbox = '$appDir\\tools\\winbox.exe';
    if (await File(bundledWinbox).exists()) {
      return bundledWinbox; // Ketemu!
    }
    ```

#### Layer 2: Deteksi via Windows System PATH
Jika user sudah menginstal Winbox secara global di komputernya, kita bisa mencarinya menggunakan CLI perintah `where` bawaan Windows:
```dart
Future<String?> findInSystemPath(String executableName) async {
  try {
    final result = await Process.run('where', [executableName]);
    if (result.exitCode == 0) {
      // Mengambil baris pertama hasil output path
      return result.stdout.toString().split('\r\n').first.trim();
    }
  } catch (_) {}
  return null;
}
// Cara pakai: String? winbox = await findInSystemPath('winbox.exe');
```

#### Layer 3: Deteksi di Folder Instalasi Umum (Default Directory)
Untuk VNC Viewer (seperti UltraVNC atau RealVNC), mereka biasanya terinstal di folder default Windows:
```dart
Future<String?> findInProgramFiles() async {
  final List<String> commonPaths = [
    r'C:\Program Files\UltraVNC\vncviewer.exe',
    r'C:\Program Files (x86)\UltraVNC\vncviewer.exe',
    r'C:\Program Files\RealVNC\VNC Viewer\vncviewer.exe',
  ];
  
  for (final path in commonPaths) {
    if (await File(path).exists()) {
      return path; // Ketemu!
    }
  }
  return null;
}
```

#### Layer 4: Fallback ke Pengaturan Kustom (Custom Settings)
Jika ketiga cara di atas gagal menemukan file, kita sediakan halaman **Settings** di aplikasi Flutter di mana user dapat mengklik tombol "Cari File Manual" yang akan membuka *File Picker*. Path terpilih akan disimpan di penyimpanan lokal (`SharedPreferences`).

```dart
// Mengambil path dari SharedPreferences
final prefs = await SharedPreferences.getInstance();
String? userCustomWinboxPath = prefs.getString('custom_winbox_path');
```

---

## 4. Keuntungan Pendekatan Ini

1.  **Pengalaman Pengguna Sangat Premium (Zero Configuration):** Begitu pengguna selesai menginstal aplikasi via `.exe` installer, aplikasi langsung siap digunakan. Pengguna tidak perlu memindahkan file manual, mengatur PATH, atau mengunduh tool tambahan.
2.  **Bebas Eror Path:** Menghapus ketergantungan kaku pada drive `D:\` (yang mana tidak semua komputer memiliki drive D).
3.  **Kemudahan Update:** Jika versi baru dirilis, installer baru tinggal di-run, dan semua tools pendukung (worker, winbox, vnc) akan otomatis diperbarui secara rapi ke versi terbaru.

---

## 5. Strategi Deployment Multi-Client: Versi Host vs Client

> [!IMPORTANT]
> **Ide Anda Sangat Brilian & 100% Benar Secara Arsitektur Sistem!**
> Menjalankan background worker IMAP sync di banyak komputer cabang sekaligus adalah **kesalahan fatal** karena:
> 1.  **Email Polling Conflict:** Multi-koneksi IMAP dari beberapa PC dengan akun email yang sama akan memicu pemblokiran login (lockout) oleh mail server provider karena aktivitas mencurigakan.
> 2.  **Redundancy Data:** Semua PC akan berebut memperbarui baris database Supabase yang sama, mengakibatkan konflik state dan pemborosan bandwidth internet cabang.
> 3.  **Pemborosan Resource:** Komputer client (staff/kasir) yang umumnya berspesifikasi rendah tidak perlu dibebani RAM/CPU ekstra untuk proses NodeJS worker di latar belakang.

Oleh karena itu, membedakan instalasi antara **Host (Komputer Utama)** dan **Client (Komputer Monitoring/Staff)** adalah langkah paling tepat.

Kita memiliki dua cara utama untuk mengimplementasikan skenario ini di **Inno Setup**:

---

### Opsi A: Satu Installer Tunggal dengan Pilihan Komponen (Sangat Direkomendasikan)
Daripada memelihara dua file installer terpisah, kita membuat **satu installer saja** (`EDP_NetOps_Setup.exe`), namun saat proses instalasi berjalan, user diberikan pilihan jenis instalasi (Client atau Host) via halaman pilihan komponen.

```
┌──────────────────────────────────────────────┐
│             PILIH JENIS INSTALASI            │
│                                              │
│  [x] EDP NetOps Client (Aplikasi Utama)      │
│  [ ] Background Worker (Hanya Komputer Host) │
│                                              │
└──────────────────────────────────────────────┘
```

#### Skrip Inno Setup (`.iss`) untuk Opsi A:
```iss
[Types]
Name: "client"; Description: "Instalasi Client (Standar)"; Flags: iscustom
Name: "host"; Description: "Instalasi Host (Komputer Utama)"; Flags: iscustom

[Components]
Name: "app"; Description: "Aplikasi Utama EDP NetOps"; Types: client host; Flags: fixed
Name: "worker"; Description: "Background Ticket Sync Worker (Node.js)"; Types: host

[Files]
; Aplikasi utama selalu diinstal baik di client maupun host
Source: "D:\DartProject\edp_netops\build\windows\x64\runner\Release\edp_netops.exe"; DestDir: "{app}"; Components: app; Flags: ignoreversion

; Folder tools pendukung (Winbox, VNC) selalu diinstal di kedua tipe
Source: "D:\Edp NetOps\winbox.exe"; DestDir: "{app}\tools"; Components: app; Flags: ignoreversion
Source: "D:\Edp NetOps\vncviewer.exe"; DestDir: "{app}\tools"; Components: app; Flags: ignoreversion

; File worker HANYA disalin jika user memilih komponen 'worker' (Instalasi Host)
Source: "D:\DartProject\edp_netops\worker-ticket-sync\*"; DestDir: "{app}\worker"; Components: worker; Flags: recursesubdirs createallsubdirs ignoreversion
```

---

### Opsi B: Dua File Installer Terpisah (`.exe`)
Jika Anda ingin file instalasi client berukuran sangat kecil (karena tidak menyertakan modul NodeJS), kita bisa memisahkan proyek menjadi dua file skrip Inno Setup yang berbeda:

1.  **`EDP_NetOps_Client_Setup.iss`** (Tanpa menyertakan baris file worker). Hasil output: **`EDP_NetOps_Client_Setup.exe`** (ukuran kecil, hanya ~15-20MB).
2.  **`EDP_NetOps_Host_Setup.iss`** (Menyertakan folder worker NodeJS utuh). Hasil output: **`EDP_NetOps_Host_Setup.exe`** (ukuran lebih besar karena berisi folder `node_modules`).

---

### Logika Pendeteksian Worker di Flutter (Runtime Safe)
Untuk mencegah eror pada versi Client (di mana folder `worker` tidak diinstal), di dalam kode Flutter [ticket_controller.dart](file:///d:/DartProject/edp_netops/lib/features/ticket/presentation/ticket_controller.dart), aplikasi akan secara otomatis memverifikasi keberadaan folder worker sebelum memicu proses:

```dart
  static Future<void> autoStartWorkerIfNeeded() async {
    if (kIsWeb) return;

    final workerDir = await getWorkerPath(); // Mendapatkan C:\Program Files\EDP NetOps\worker secara dinamis
    
    // VERIFIKASI KEBERADAAN FOLDER WORKER
    if (!await Directory(workerDir).exists()) {
      debugPrint('[Background Worker] Komputer ini diinstal sebagai CLIENT (folder worker tidak ada). Auto-start ditiadakan.');
      return; // Langsung keluar dengan aman tanpa melempar error crash
    }
    
    // ... lanjutkan proses startup worker jika ada di komputer Host ...
  }
```

Dengan logika di atas, file build Flutter Anda **tetap murni satu codebase (satu binary exe yang sama)**, tetapi perilakunya akan menyesuaikan secara cerdas berdasarkan apakah folder `worker` ditemukan di sistem komputer tersebut atau tidak. Ini adalah cara kerja level senior yang sangat efisien dan mudah dikelola!

