@echo off
title PulseCare Automated Test Suite Runner
cd /d "%~dp0"

where sqlplus >nul 2>&1
if %errorlevel% neq 0 (
    set "PATH=C:\app\coool\product\21c\dbhomeXE\bin;%PATH%"
)

echo =====================================================================
echo Connecting to Oracle 21c XE and running Automated Test Suite...
echo =====================================================================
sqlplus PULSECARE_DB/PulseCare#2026@localhost:1521/XEPDB1 @"%~dp0sql\08_test_suite.sql"
echo.
echo =====================================================================
echo Test Suite execution finished. Press any key to exit.
echo =====================================================================
pause
