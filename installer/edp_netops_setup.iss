; ═══════════════════════════════════════════════════════════════════
;  EDP NetOps — Inno Setup Installer Script
; ═══════════════════════════════════════════════════════════════════
;
;  Satu installer tunggal dengan pilihan komponen:
;    - Client (Standar)  : Aplikasi utama + Tools (Winbox, VNC)
;
;  NOTE: Worker sudah dipisahkan ke server terpisah (tidak lagi di-bundle).
;
;  Cara Compile:
;    1. Install Inno Setup dari https://jrsoftware.org/isdl.php
;    2. Buka file ini di Inno Setup Compiler
;    3. Klik Build > Compile (Ctrl+F9)
;    4. File output installer akan muncul di folder 'installer_output'
;
;  PENTING: Sebelum compile, pastikan Anda sudah menjalankan:
;    flutter build windows --release
;
; ═══════════════════════════════════════════════════════════════════

#define MyAppName "EDP NetOps"
#define MyAppVersion "3.1.0"
#define MyAppPublisher "NetOps Dev"
#define MyAppExeName "edp_netops.exe"

; Path ke hasil build Flutter (sesuaikan jika berbeda)
#define FlutterBuildDir "D:\DartProject\edp_netops\build\windows\x64\runner\Release"
; Worker sudah dipisahkan ke server — tidak lagi di-bundle dalam installer
#define ToolsDir "D:\Edp NetOps"
#define AssetsDir "D:\DartProject\edp_netops\assets"

[Setup]
AppId={{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} v{#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=installer_output
OutputBaseFilename=EDP_NetOps_Setup_v{#MyAppVersion}
; Gunakan logo aplikasi sebagai ikon installer
SetupIconFile={#AssetsDir}\logo.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\{#MyAppExeName}

; ═══════════════════════════════════════════════════════════════════
;  TIPE INSTALASI & KOMPONEN
; ═══════════════════════════════════════════════════════════════════

[Types]
Name: "client"; Description: "Instalasi Client — Standar"
Name: "custom"; Description: "Kustom"; Flags: iscustom

[Components]
; Aplikasi utama (wajib, tidak bisa di-uncheck)
Name: "app"; Description: "Aplikasi Utama EDP NetOps"; Types: client custom; Flags: fixed
; Tools pendukung (Winbox & VNC Viewer)
Name: "tools"; Description: "Tools Pendukung (Winbox, VNC Viewer)"; Types: client custom

; ═══════════════════════════════════════════════════════════════════
;  DAFTAR FILE YANG DISALIN
; ═══════════════════════════════════════════════════════════════════

[Files]
; ── Aplikasi Utama Flutter (Selalu Disalin) ─────────────────────
Source: "{#FlutterBuildDir}\{#MyAppExeName}"; DestDir: "{app}"; Components: app; Flags: ignoreversion
Source: "{#FlutterBuildDir}\*.dll"; DestDir: "{app}"; Components: app; Flags: ignoreversion
Source: "{#FlutterBuildDir}\data\*"; DestDir: "{app}\data"; Components: app; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "{#AssetsDir}\*.ps1"; DestDir: "{app}\assets"; Components: app; Flags: ignoreversion
Source: "D:\DartProject\edp_netops\dist\sla_scraper.exe"; DestDir: "{app}\tools"; Components: app; Flags: ignoreversion

; ── File Konfigurasi Lingkungan (.env) ──────────────────────────
; PENTING: File .env berisi credentials Supabase.
; Untuk keamanan, file ini disalin ke folder Documents pengguna,
; BUKAN ke folder Program Files agar tidak ikut ter-bundle ke Git.
Source: "D:\DartProject\edp_netops\.env"; DestDir: "{userdocs}\Edp NetOps"; Components: app; Flags: ignoreversion onlyifdoesntexist

; ── Tools Pendukung (Winbox & VNC Viewer) ───────────────────────
Source: "{#ToolsDir}\winbox.exe"; DestDir: "{app}\tools"; Components: tools; Flags: ignoreversion
Source: "{#ToolsDir}\vncviewer.exe"; DestDir: "{app}\tools"; Components: tools; Flags: ignoreversion

; ── Worker sudah TIDAK di-bundle ────────────────────────────────
; Worker di-deploy terpisah ke komputer server via Task Scheduler.

; ═══════════════════════════════════════════════════════════════════
;  SHORTCUT DI START MENU & DESKTOP
; ═══════════════════════════════════════════════════════════════════

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{commondesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Buat shortcut di Desktop"; GroupDescription: "Shortcut Tambahan:"; Flags: checkedonce

; ═══════════════════════════════════════════════════════════════════
;  FOLDER KERJA (Dibuat Otomatis Saat Instalasi)
; ═══════════════════════════════════════════════════════════════════

[Dirs]
; Folder untuk menyimpan hasil output ping
Name: "{userdocs}\Edp NetOps\Hasil Ping"

; ═══════════════════════════════════════════════════════════════════
;  AKSI SETELAH INSTALASI SELESAI
; ═══════════════════════════════════════════════════════════════════

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Jalankan {#MyAppName} sekarang"; Flags: nowait postinstall skipifsilent
Filename: "{app}\{#MyAppExeName}"; Flags: nowait; Check: IsSilent

; ═══════════════════════════════════════════════════════════════════
;  PEMBERSIHAN SAAT UNINSTALL
; ═══════════════════════════════════════════════════════════════════

; Hapus folder worker lama saat upgrade (bersihkan dari instalasi sebelumnya)
[InstallDelete]
Type: filesandordirs; Name: "{app}\worker"

[UninstallDelete]
Type: filesandordirs; Name: "{app}\tools"
Type: filesandordirs; Name: "{app}\data"
Type: filesandordirs; Name: "{app}\assets"

; ═══════════════════════════════════════════════════════════════════
;  KODE PASCAL CUSTOM
; ═══════════════════════════════════════════════════════════════════

[Code]
function IsSilent: Boolean;
begin
  Result := WizardSilent;
end;
