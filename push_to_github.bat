@echo off
title Push PulseCare to GitHub
echo ============================================================
echo   Pushing PulseCare to https://github.com/giri-sayan/PulseCare
echo ============================================================
echo.
"%LOCALAPPDATA%\Programs\Git\cmd\git.exe" push -u origin main
echo.
if %ERRORLEVEL% EQU 0 (
    echo ============================================================
    echo   SUCCESS! All files pushed to GitHub successfully!
    echo   View repository at: https://github.com/giri-sayan/PulseCare
    echo ============================================================
) else (
    echo ============================================================
    echo   Push encountered an error or needs authentication.
    echo ============================================================
)
echo.
pause
