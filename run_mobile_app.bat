@echo off
title PulseCare Mobile Smartphone Application
cd /d "%~dp0"

REM Ensure Python 3.12 is in PATH
set "PATH=%LOCALAPPDATA%\Programs\Python\Python312;%LOCALAPPDATA%\Programs\Python\Python312\Scripts;%PATH%"

echo ======================================================================
echo   PulseCare - Smart Hospital Mobile Application (PWA)
echo   Course: BCSE302P - Database Systems Laboratory
echo   Student: Sayan Giri (24BCT0281)
echo ======================================================================
echo.

REM Start Flask Mobile API Server
start "PulseCare Mobile Server" cmd /k "cd /d ""%~dp0"" && set ""PATH=%LOCALAPPDATA%\Programs\Python\Python312;%LOCALAPPDATA%\Programs\Python\Python312\Scripts;%PATH%"" && python mobile/server.py"

REM Give server 3 seconds to initialize
timeout /t 3 /nobreak >nul

REM Find Local IPv4 Address
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /i "IPv4"') do (
    set "LOCAL_IP=%%a"
    goto :found_ip
)
:found_ip
set "LOCAL_IP=%LOCAL_IP: =%"

echo [1/2] Mobile Application Server Running!
echo [INFO] Local PC View  : http://localhost:5000
echo [INFO] Smartphone URL : http://%LOCAL_IP%:5000
echo.
echo ======================================================================
echo   TO OPEN ON YOUR PHONE:
echo   1. Ensure phone is on the same Wi-Fi (or Laptop Hotspot)
echo   2. Open browser on phone and type: http://%LOCAL_IP%:5000
echo   3. Tap 'Install PulseCare' or 'Add to Home Screen'
echo ======================================================================
echo.
echo [2/2] Opening Smartphone Sized App Window on Laptop...

REM Launch in native phone aspect ratio (412 x 820)
start msedge --app=http://localhost:5000 --window-size=412,820 || start chrome --app=http://localhost:5000 --window-size=412,820 || start http://localhost:5000

pause
