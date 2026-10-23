@echo off
title PulseCare Hospital Management System - Web App
cd /d "%~dp0"

REM Ensure Python 3.12 is in PATH for this session
set "PATH=%LOCALAPPDATA%\Programs\Python\Python312;%LOCALAPPDATA%\Programs\Python\Python312\Scripts;%PATH%"

echo =====================================================================
echo Starting PulseCare Hospital Management System (Streamlit Web App)...
echo Course: BCSE302P - Database Systems Laboratory
echo Student: Sayan Giri (24BCT0281)
echo =====================================================================
echo Opening PulseCare web dashboard...
python -m streamlit run app/main.py
pause
