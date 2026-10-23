@echo off
title PulseCare Hospital Management System - Standalone Application
cd /d "%~dp0"

REM Ensure Python 3.12 is in PATH
set "PATH=%LOCALAPPDATA%\Programs\Python\Python312;%LOCALAPPDATA%\Programs\Python\Python312\Scripts;%PATH%"

echo =====================================================================
echo Starting PulseCare Standalone Enterprise Application...
echo =====================================================================
echo.
echo Launching background server and standalone desktop window...

REM Start Streamlit in background
start /min cmd /c "python -m streamlit run app/main.py --server.headless=true --server.port=8501"

REM Wait 3 seconds for server startup
timeout /t 3 /nobreak >nul

REM Launch standalone desktop window via Edge or Chrome
start msedge --app=http://localhost:8501 || start chrome --app=http://localhost:8501 || start http://localhost:8501

echo.
echo Standalone Application launched!
echo (To access on Mobile: connect to the same Wi-Fi and open the Network URL displayed by Streamlit)
echo.
pause
