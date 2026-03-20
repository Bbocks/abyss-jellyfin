@echo off
setlocal EnableDelayedExpansion

if "%1"=="1" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\install.ps1"
    exit /b
)
if "%1"=="2" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\uninstall.ps1"
    exit /b
)

cls
echo.
echo  ================================================
echo   Abyss Theme Setup
echo   https://github.com/AumGupta/abyss-jellyfin
echo  ================================================
echo.
echo   What would you like to do?
echo.
echo   [1] Install        [2] Uninstall
echo.
set /p CHOICE="  Enter 1 or 2: "

if "!CHOICE!"=="1" (
    echo.
    echo Requesting administrator privileges...
    powershell -Command "Start-Process -FilePath '%~f0' -ArgumentList '1' -Verb RunAs"
) else if "!CHOICE!"=="2" (
    echo.
    echo Requesting administrator privileges...
    powershell -Command "Start-Process -FilePath '%~f0' -ArgumentList '2' -Verb RunAs"
) else (
    echo.
    echo  [X] Invalid choice. Please enter 1 or 2.
    echo.
    pause
)