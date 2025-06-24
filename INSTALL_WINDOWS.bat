@echo off
title Aruba IoT Telemetry - Windows Installation

REM ========================================================================
REM  🎯 ARUBA IOT TELEMETRY - WINDOWS INSTALLER LAUNCHER
REM ========================================================================

echo.
echo ╔═══════════════════════════════════════════════════════════════════════╗
echo ║                    🌐 ARUBA IOT TELEMETRY SERVER 🌐                   ║
echo ║                         Windows Quick Installer                       ║
echo ╚═══════════════════════════════════════════════════════════════════════╝
echo.
echo Welcome! This installer will set up the Aruba IoT Telemetry Server
echo on your Windows computer in just a few clicks.
echo.
echo What this installer does:
echo  ✅ Checks your Python installation
echo  ✅ Sets up the application environment  
echo  ✅ Installs all required components
echo  ✅ Configures Windows Firewall
echo  ✅ Creates secure authentication tokens
echo  ✅ Tests the installation
echo  ✅ Starts the server (optional)
echo.

REM Check if we're in the right location
if not exist app.py (
    echo ❌ ERROR: Installation files not found!
    echo.
    echo This installer must be run from the Aruba IoT project folder.
    echo.
    echo 💡 If you downloaded from GitHub:
    echo    1. Extract the ZIP file completely
    echo    2. Open the extracted folder
    echo    3. Look for this file: setup_windows_oneclick.bat
    echo    4. Double-click it to run the installer
    echo.
    echo Current location: %CD%
    echo Looking for: app.py, requirements.txt, templates folder
    echo.
    pause
    exit /b 1
)

echo ✅ Installation files found
echo.

REM Check if Python is available
python --version >nul 2>&1
if errorlevel 1 (
    echo ⚠️  PYTHON NOT DETECTED
    echo.
    echo The Aruba IoT Telemetry Server requires Python 3.8 or higher.
    echo.
    echo 🔧 AUTOMATIC SOLUTION:
    echo 1. Click 'Yes' to open the Python download page
    echo 2. Download Python (click the big yellow button)
    echo 3. During installation, CHECK: "Add Python to PATH"
    echo 4. After installation, run this installer again
    echo.
    set /p download="Open Python download page? [Y/N]: "
    if /i "!download!"=="Y" (
        echo Opening Python download page...
        start https://www.python.org/downloads/windows/
    )
    echo.
    echo Please install Python and run this installer again.
    pause
    exit /b 1
)

for /f "tokens=2" %%v in ('python --version') do set "PYTHON_VER=%%v"
echo ✅ Python detected: %PYTHON_VER%
echo.

echo 🚀 READY TO INSTALL
echo ===================
echo The installation will begin when you press Enter.
echo This process typically takes 2-5 minutes.
echo.

set /p proceed="Press ENTER to start the installation (or type 'exit' to cancel): "
if /i "!proceed!"=="exit" (
    echo Installation cancelled.
    pause
    exit /b 0
)

echo.
echo 🔄 Starting installation...
echo.

REM Run the comprehensive setup
call setup_windows_oneclick.bat

echo.
echo 👋 Installation process completed.
echo Check the messages above for the results.
echo.
pause
