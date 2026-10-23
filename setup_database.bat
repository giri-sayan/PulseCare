@echo off
setlocal
cd /d "%~dp0"

where sqlplus >nul 2>&1
if %errorlevel% neq 0 (
    set "PATH=C:\app\coool\product\21c\dbhomeXE\bin;%PATH%"
)

echo ======================================================================
echo   PulseCare - Automated Oracle 21c Database Setup
echo ======================================================================
echo.

set "DB_PASS=PulseCare#2026"

echo Connecting to PULSECARE_DB on XEPDB1 and running master setup...
sqlplus PULSECARE_DB/%DB_PASS%@localhost:1521/XEPDB1 @"%~dp0sql\master_setup.sql"

echo.
echo ======================================================================
echo   Database Setup Script Finished. Press any key to exit.
echo ======================================================================
pause
