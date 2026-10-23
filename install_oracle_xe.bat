@echo off
setlocal
echo ======================================================================
echo   PulseCare - Oracle Database 21c Express Edition Automated Installer
echo ======================================================================
echo.

set "SETUP_DIR=C:\Users\coool\Downloads\OracleXE_Setup"
set "RSP_FILE=%SETUP_DIR%\XEInstall.rsp"
set "LOG_FILE=%SETUP_DIR%\setup.log"

if not exist "%SETUP_DIR%\setup.exe" (
    echo [ERROR] setup.exe not found in %SETUP_DIR%
    pause
    exit /b 1
)

echo [1/3] Preparing Oracle 21c XE Silent Installation...
echo [INFO] Response file: %RSP_FILE%
echo [INFO] Installation log: %LOG_FILE%
echo.
echo [2/3] Starting installer with administrative privileges...
echo (If a Windows UAC prompt appears asking 'Do you want to allow this app to make changes', click YES)
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%SETUP_DIR%\setup.exe' -ArgumentList '/S /v\"\"\"RSP_FILE=%RSP_FILE% /qn /L*v %LOG_FILE%\"\"\"' -Verb RunAs"

echo [3/3] Installation process launched in background.
echo Monitor progress in: %LOG_FILE%
echo.
pause
