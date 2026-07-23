@echo off
echo ============================================
echo   EDP NetOps Worker - Install Windows Service
echo ============================================
echo.
echo Pastikan Anda menjalankan script ini sebagai Administrator!
echo.

REM Cek apakah nssm.exe ada di folder ini atau di PATH
if exist "%~dp0nssm.exe" (
    set "NSSM=%~dp0nssm.exe"
) else (
    where nssm >nul 2>nul
    if %errorlevel% neq 0 (
        echo [!] nssm.exe tidak ditemukan.
        echo.
        echo     Cara install:
        echo     1. Download dari: https://nssm.cc/download
        echo     2. Extract file zip
        echo     3. Copy nssm.exe ^(dari folder win64^) ke folder ini
        echo     4. Jalankan ulang script ini
        echo.
        pause
        exit /b 1
    )
    set "NSSM=nssm"
)

REM Cek apakah dist/main.js ada (sudah di-build)
if not exist "%~dp0dist\main.js" (
    echo [!] File dist\main.js tidak ditemukan.
    echo     Jalankan 'npm run build' terlebih dahulu.
    pause
    exit /b 1
)

REM Cek apakah run_worker.bat ada
if not exist "%~dp0run_worker.bat" (
    echo [!] File run_worker.bat tidak ditemukan.
    pause
    exit /b 1
)

echo [*] Menginstall service 'EdpNetOpsWorker'...

REM Buat folder logs jika belum ada
if not exist "%~dp0logs" mkdir "%~dp0logs"

set "WRAPPER=%~dp0run_worker.bat"

echo.
echo   Wrapper : %WRAPPER%
echo.

REM Install service — nssm jalankan wrapper .bat (bukan node.exe langsung)
"%NSSM%" install EdpNetOpsWorker "%WRAPPER%"
"%NSSM%" set EdpNetOpsWorker AppDirectory "%~dp0"
"%NSSM%" set EdpNetOpsWorker DisplayName "EDP NetOps Ticket Sync Worker"
"%NSSM%" set EdpNetOpsWorker Description "Background worker untuk sinkronisasi tiket dari email IMAP ke Supabase"
"%NSSM%" set EdpNetOpsWorker Start SERVICE_AUTO_START
"%NSSM%" set EdpNetOpsWorker AppStdout "%~dp0logs\service.log"
"%NSSM%" set EdpNetOpsWorker AppStderr "%~dp0logs\service.log"
"%NSSM%" set EdpNetOpsWorker AppRotateFiles 1
"%NSSM%" set EdpNetOpsWorker AppRotateBytes 5242880
"%NSSM%" set EdpNetOpsWorker AppRestartDelay 5000

echo.
echo [*] Menjalankan service...
"%NSSM%" start EdpNetOpsWorker

echo.
echo ============================================
echo   INSTALASI SELESAI!
echo ============================================
echo.
echo   Service Name  : EdpNetOpsWorker
echo   Status        : Cek di services.msc
echo   Log File      : %~dp0logs\service.log
echo   Auto-Start    : Ya (saat komputer nyala)
echo   Auto-Restart  : Ya (jika crash, delay 5 detik)
echo.
pause
