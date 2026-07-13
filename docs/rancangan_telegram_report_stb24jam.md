# 📋 Rancangan Integrasi Report STB 24 Jam ke Telegram Bot

> **Status**: 🟡 Rancangan (Belum Diimplementasikan)
> **Tanggal**: 11 Juli 2026
> **Prioritas**: Nice-to-have (Enhancement)

---

## 1. Gambaran Umum

### Apa yang ingin dicapai?
Menambahkan tombol **"📤 Report ke Telegram"** di sebelah tombol "Generate Sheet STB 24 Jam" di halaman Rekap STB 24 Jam. Ketika tombol ini ditekan, sistem akan secara otomatis:

1. Mengambil **screenshot** sheet harian terbaru (misal sheet "11") dari file Excel bulanan
2. Mengambil **screenshot** sheet **TREND** dari file Excel bulanan yang sama
3. Mengirimkan **kedua screenshot** tersebut ke grup Telegram yang telah dikonfigurasi
4. Mengirimkan **file `.xlsx`** bulanan ke grup Telegram yang sama
5. Menyertakan **caption/ringkasan** berupa statistik singkat (jumlah toko OK/NOK)

### Alur Kerja Visual

```
┌─────────────────────────────────────────────────────────────────┐
│                   HALAMAN STB 24 JAM                            │
│                                                                 │
│  ┌──────────────────────────┐  ┌──────────────────────────┐     │
│  │ 🔧 Generate Sheet STB   │  │ 📤 Report ke Telegram    │     │
│  │    24 Jam                │  │                          │     │
│  └──────────────────────────┘  └────────────┬─────────────┘     │
│                                             │                   │
└─────────────────────────────────────────────┼───────────────────┘
                                              │ Klik
                                              ▼
                          ┌───────────────────────────────────┐
                          │  PowerShell Script Baru:          │
                          │  report_stb24jam_telegram.ps1     │
                          │                                   │
                          │  1. Buka file Excel via COM       │
                          │  2. Screenshot sheet harian       │
                          │  3. Screenshot sheet TREND        │
                          │  4. Kirim ke Telegram Bot API     │
                          │  5. Kirim file .xlsx              │
                          └───────────────┬───────────────────┘
                                          │
                                          ▼
                          ┌───────────────────────────────────┐
                          │  Telegram Bot API                 │
                          │                                   │
                          │  POST /sendPhoto   (2x screenshot)│
                          │  POST /sendDocument (file .xlsx)  │
                          │                                   │
                          │  Target: Grup Telegram EDP        │
                          └───────────────────────────────────┘
```

---

## 2. Prasyarat

### 2.1 Membuat Bot Telegram
1. Buka Telegram, cari **@BotFather**
2. Ketik `/newbot` → beri nama (misal: `EDP NetOps Report Bot`)
3. BotFather akan memberikan **Bot Token** (contoh: `7123456789:AAHdqTcv...`)
4. **Simpan token ini** — akan dimasukkan ke konfigurasi aplikasi

### 2.2 Mendapatkan Chat ID Grup
1. Tambahkan bot ke grup Telegram yang diinginkan
2. Kirim pesan apapun ke grup tersebut
3. Buka URL berikut di browser:
   ```
   https://api.telegram.org/bot<TOKEN>/getUpdates
   ```
4. Cari `"chat": { "id": -100xxxxxxxxxx }` — itu adalah **Chat ID** grup
5. **Simpan Chat ID ini** — akan dimasukkan ke konfigurasi aplikasi

### 2.3 Software
- Microsoft Excel (sudah terinstal — digunakan oleh fitur generate saat ini)
- PowerShell 5.1+ (bawaan Windows)
- Koneksi internet (untuk mengirim ke Telegram API)

---

## 3. Arsitektur Teknis

### 3.1 File yang Perlu Dibuat / Diubah

| File | Aksi | Keterangan |
|------|------|------------|
| `assets/report_stb24jam_telegram.ps1` | **[BARU]** | Script PowerShell untuk screenshot Excel & kirim ke Telegram |
| `lib/features/network_tools/stb24jam/data/stb24jam_service.dart` | **[UBAH]** | Tambah method `reportToTelegram()` |
| `lib/features/network_tools/stb24jam/presentation/stb24jam_controller.dart` | **[UBAH]** | Tambah state & method untuk report |
| `lib/features/network_tools/stb24jam/presentation/stb24jam_page.dart` | **[UBAH]** | Tambah tombol "Report ke Telegram" |
| `lib/core/constants/app_constants.dart` | **[UBAH]** | Tambah konstanta Telegram Bot |
| `lib/features/settings/presentation/settings_sections.dart` | **[UBAH]** | Tambah input konfigurasi Bot Token & Chat ID di halaman Settings |

---

### 3.2 Script PowerShell: `report_stb24jam_telegram.ps1`

Script ini adalah inti dari fitur report. Tugasnya:

#### Parameter Input:
```powershell
param(
    [string]$MonthlyFile,      # Path file .xlsx bulanan
    [string]$SheetName,        # Nama sheet harian (misal: "11")
    [string]$BotToken,         # Telegram Bot Token
    [string]$ChatId,           # Telegram Group Chat ID
    [string]$TempFolder        # Folder sementara untuk menyimpan screenshot
)
```

#### Langkah Kerja Script:

```
┌────────────────────────────────────────────────────────────────┐
│ STEP 1: Buka File Excel via COM                                │
│         $excel = New-Object -ComObject Excel.Application       │
│         $workbook = $excel.Workbooks.Open($MonthlyFile)        │
└────────────────────────────┬───────────────────────────────────┘
                             ▼
┌────────────────────────────────────────────────────────────────┐
│ STEP 2: Screenshot Sheet Harian                                │
│         - Pilih sheet harian (misal "11")                      │
│         - Select range data yang terisi (A1 s/d kolom terakhir)│
│         - CopyPicture ke clipboard                             │
│         - Paste ke ChartObject sementara                       │
│         - Export chart sebagai file gambar PNG                  │
└────────────────────────────┬───────────────────────────────────┘
                             ▼
┌────────────────────────────────────────────────────────────────┐
│ STEP 3: Screenshot Sheet TREND                                 │
│         - Sama seperti Step 2 tapi untuk sheet "TREND"         │
└────────────────────────────┬───────────────────────────────────┘
                             ▼
┌────────────────────────────────────────────────────────────────┐
│ STEP 4: Kirim Screenshot ke Telegram                           │
│         - POST ke https://api.telegram.org/bot<TOKEN>/sendPhoto│
│         - Kirim gambar sheet harian + caption ringkasan        │
│         - Kirim gambar sheet TREND                             │
└────────────────────────────┬───────────────────────────────────┘
                             ▼
┌────────────────────────────────────────────────────────────────┐
│ STEP 5: Kirim File .xlsx ke Telegram                           │
│         - POST ke https://api.telegram.org/bot<TOKEN>/sendDoc  │
│         - Kirim file Excel bulanan (.xlsx)                     │
└────────────────────────────┬───────────────────────────────────┘
                             ▼
┌────────────────────────────────────────────────────────────────┐
│ STEP 6: Cleanup & Output JSON                                  │
│         - Tutup Excel COM                                      │
│         - Hapus file gambar sementara                          │
│         - Output JSON sukses/gagal ke stdout                   │
└────────────────────────────────────────────────────────────────┘
```

#### Contoh Kode Inti Screenshot Excel:

```powershell
# Ambil range data sheet harian
$sheet = $workbook.Worksheets.Item($SheetName)
$lastRow = $sheet.Cells.Item($sheet.Rows.Count, 2).End(-4162).Row
$lastCol = $sheet.Cells.Item(2, $sheet.Columns.Count).End(-4159).Column
$range = $sheet.Range($sheet.Cells.Item(1, 1), $sheet.Cells.Item($lastRow, $lastCol))

# Copy range sebagai gambar
$range.CopyPicture(1, 2)  # 1 = xlScreen, 2 = xlPicture

# Buat chart sementara sebagai "kanvas" untuk paste gambar
$chartObj = $sheet.ChartObjects.Add(0, 0, $range.Width, $range.Height)
$chartObj.Chart.Paste()

# Export sebagai PNG
$imgPath = "$TempFolder\sheet_$SheetName.png"
$chartObj.Chart.Export($imgPath, "PNG")
$chartObj.Delete()
```

#### Contoh Kode Kirim ke Telegram:

```powershell
# Kirim foto ke Telegram
$uri = "https://api.telegram.org/bot$BotToken/sendPhoto"
$form = @{
    chat_id = $ChatId
    caption = "📊 Rekap STB 24 Jam - Tanggal $SheetName`n✅ OK: $totalOk | ❌ NOK: $totalNok"
}
$fileBytes = [System.IO.File]::ReadAllBytes($imgPath)
# Gunakan multipart form-data via .NET HttpClient
```

---

### 3.3 Perubahan di Flutter (Dart)

#### `app_constants.dart` — Tambah Konstanta:
```dart
// ── Telegram Bot ─────────────────────────────────────────────
static const String telegramBotTokenKey = 'telegram_bot_token';
static const String telegramChatIdKey = 'telegram_chat_id';
```

#### `stb24jam_service.dart` — Tambah Method:
```dart
Future<GenerateResult> reportToTelegram({
  required DateTime tanggal,
  required String botToken,
  required String chatId,
}) async {
  final scriptPath = _resolveReportScriptPath();
  final monthlyPath = getMonthlyFilePath(tanggal);

  final result = await Process.run('powershell.exe', [
    '-ExecutionPolicy', 'Bypass',
    '-File', scriptPath,
    '-MonthlyFile', monthlyPath,
    '-SheetName', tanggal.day.toString(),
    '-BotToken', botToken,
    '-ChatId', chatId,
    '-TempFolder', Directory.systemTemp.path,
  ]);

  // Parse JSON output...
}
```

#### `stb24jam_page.dart` — Tambah Tombol:
```dart
// Di sebelah tombol Generate (baris ~216-250)
Row(
  children: [
    Expanded(child: _buildGenerateButton()),
    const SizedBox(width: 12),
    Expanded(child: _buildReportTelegramButton()),
  ],
)
```

---

## 4. Contoh Hasil di Telegram

Ketika tombol "Report ke Telegram" ditekan, grup Telegram akan menerima 3 pesan berurutan:

### Pesan 1: Screenshot Sheet Harian
```
📊 Rekap STB 24 Jam — 11 Juli 2026
━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Total OK    : 180 toko
❌ Total NOK   : 22 toko
📋 Total Toko  : 202 toko
━━━━━━━━━━━━━━━━━━━━━━━━━
🤖 Dikirim otomatis oleh EDP NetOps v2.9.0

[gambar screenshot sheet harian]
```

### Pesan 2: Screenshot Sheet TREND
```
📈 Trend Bulanan STB 24 Jam — JULI 2026

[gambar screenshot sheet TREND]
```

### Pesan 3: File Excel
```
📎 File Rekap Bulanan
STB 24 JAM JULI.xlsx
```

---

## 5. Konfigurasi di Halaman Settings

Perlu ditambahkan section baru di halaman **Settings** agar user bisa memasukkan Bot Token dan Chat ID tanpa hardcode:

```
┌─────────────────────────────────────────┐
│ 🤖 TELEGRAM BOT                        │
│                                         │
│ Bot Token                               │
│ ┌─────────────────────────────────────┐ │
│ │ 7123456789:AAHdqTcv...              │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ Chat ID Grup                            │
│ ┌─────────────────────────────────────┐ │
│ │ -100123456789                       │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ [🔔 Test Kirim]                         │
│                                         │
│ Catatan: Pastikan bot sudah ditambahkan │
│ ke grup dan memiliki izin mengirim      │
│ pesan & file.                           │
└─────────────────────────────────────────┘
```

Nilai-nilai ini disimpan secara lokal menggunakan mekanisme settings yang sudah ada (`SettingsRepository`), sehingga bersifat **per-komputer** dan **tidak diunggah ke Supabase** (karena token bersifat sensitif).

---

## 6. Keamanan

| Aspek | Penanganan |
|-------|-----------|
| **Bot Token** | Disimpan lokal di `settings.json`, **TIDAK** diunggah ke Supabase/cloud |
| **Chat ID** | Disimpan lokal di `settings.json` |
| **File .xlsx** | Dikirim langsung ke Telegram, tidak disimpan di server perantara |
| **Screenshot** | Dibuat di folder `%TEMP%`, dihapus setelah pengiriman selesai |
| **Koneksi** | Menggunakan HTTPS ke `api.telegram.org` (terenkripsi) |

---

## 7. Keterbatasan & Catatan Penting

1. **Ukuran file Telegram**: Telegram Bot API membatasi pengiriman file maksimal **50 MB**. File `.xlsx` bulanan biasanya jauh di bawah batas ini.
2. **Ukuran gambar**: Screenshot sheet dengan banyak baris bisa menghasilkan gambar yang sangat panjang. Perlu dibatasi resolusi atau dipecah jika terlalu besar.
3. **Koneksi internet**: Fitur ini memerlukan koneksi internet aktif. Jika offline, akan menampilkan pesan error yang jelas.
4. **Excel harus terinstal**: Sama seperti fitur generate, screenshot juga menggunakan Excel COM Automation.
5. **Waktu eksekusi**: Proses screenshot + upload mungkin memakan waktu 10-30 detik tergantung ukuran file dan kecepatan internet.

---

## 8. Estimasi Waktu Implementasi

| Komponen | Estimasi |
|----------|----------|
| Script PowerShell (`report_stb24jam_telegram.ps1`) | 2–3 jam |
| Perubahan di `stb24jam_service.dart` | 30 menit |
| Perubahan di `stb24jam_controller.dart` | 30 menit |
| UI tombol + dialog di `stb24jam_page.dart` | 1 jam |
| Konfigurasi di halaman Settings | 1 jam |
| Testing & debugging | 1–2 jam |
| **Total** | **~6–8 jam kerja** |

---

## 9. Checklist Implementasi (Nanti)

- [ ] Buat script `assets/report_stb24jam_telegram.ps1`
- [ ] Tambah method `reportToTelegram()` di `stb24jam_service.dart`
- [ ] Tambah state reporting di `stb24jam_controller.dart`
- [ ] Tambah tombol "Report ke Telegram" di `stb24jam_page.dart`
- [ ] Tambah section konfigurasi Telegram di halaman Settings
- [ ] Tambah tombol "Test Kirim" untuk verifikasi token & chat ID
- [ ] Testing end-to-end dengan bot & grup Telegram asli
- [ ] Tambahkan ke panduan Inno Setup (bundle script baru ke installer)
