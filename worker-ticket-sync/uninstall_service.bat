@echo off
echo ============================================
echo   EDP NetOps Worker - Uninstall Service
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
        pause
        exit /b 1
    )
    set "NSSM=nssm"
)

echo [*] Menghentikan service 'EdpNetOpsWorker'...
"%NSSM%" stop EdpNetOpsWorker

echo [*] Menghapus service 'EdpNetOpsWorker'...
"%NSSM%" remove EdpNetOpsWorker confirm

echo.
echo [OK] Service 'EdpNetOpsWorker' berhasil dihapus.
echo.
pause
