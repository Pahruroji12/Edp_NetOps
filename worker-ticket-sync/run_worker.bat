@echo off
REM Debug wrapper — tulis log sendiri sebelum jalankan node
set "LOGFILE=D:\Worker email\worker-ticket-sync\logs\debug.log"

echo ============================== >> "%LOGFILE%"
echo %date% %time% - Starting worker... >> "%LOGFILE%"

cd /d "D:\Worker email\worker-ticket-sync"
echo Working Dir: %cd% >> "%LOGFILE%"

echo Running node... >> "%LOGFILE%"
"C:\Program Files\nodejs\node.exe" "dist\main.js" >> "%LOGFILE%" 2>&1

echo Node exited with code: %errorlevel% >> "%LOGFILE%"
