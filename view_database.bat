@echo off
title "PulseCare Database Overview"
cd /d "%~dp0"

where sqlplus >nul 2>&1
if %errorlevel% neq 0 (
    set "PATH=C:\app\coool\product\21c\dbhomeXE\bin;%PATH%"
)

echo =====================================================================
echo Connecting to Oracle 21c XE and displaying Master Database Overview...
echo =====================================================================
sqlplus PULSECARE_DB/PulseCare#2026@localhost:1521/XEPDB1 @"%~dp0sql\overview.sql"
echo.
pause
