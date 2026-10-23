@echo off
title "PulseCare Trigger and Audit Demonstration Runner"
cd /d "%~dp0"

where sqlplus >nul 2>&1
if %errorlevel% neq 0 (
    set "PATH=C:\app\coool\product\21c\dbhomeXE\bin;%PATH%"
)

echo =====================================================================
echo Connecting to Oracle 21c XE to demonstrate Triggers and Audit Log...
echo =====================================================================
sqlplus PULSECARE_DB/PulseCare#2026@localhost:1521/XEPDB1 @"%~dp0sql\demo_triggers.sql"
echo.
echo =====================================================================
echo Trigger demonstration finished. Press any key to exit.
echo =====================================================================
pause
