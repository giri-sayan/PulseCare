@echo off
title PulseCare Application Full Verification Suite
cd /d "%~dp0"

REM Ensure Python 3.12 is in PATH
set "PATH=%LOCALAPPDATA%\Programs\Python\Python312;%LOCALAPPDATA%\Programs\Python\Python312\Scripts;%PATH%"

echo =====================================================================
echo Running PulseCare Complete End-to-End Functionality Verification...
echo =====================================================================
echo.

python verify_mobile_app.py

echo.
pause
