@echo off
REM Aruba IoT Telemetry - Windows Installer (Ultra Simple)
REM Just double-click this file after cloning with GitHub Desktop

echo.
echo 🎯 Aruba IoT Telemetry - Simple Windows Installer
echo ===============================================
echo.

REM Check if we're in the right place
if not exist app.py (
    echo ❌ Please make sure you're running this from the project folder
    echo   (the folder that contains app.py)
    echo.
    pause
    exit /b 1
)

echo ✅ Project folder found
echo.

REM Check Python
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Python not found!
    echo.
    echo Please install Python from: https://www.python.org/downloads/
    echo ⚠️  IMPORTANT: Check "Add Python to PATH" during installation
    echo.
    echo After installing Python, run this script again.
    pause
    exit /b 1
)

echo ✅ Python found
echo.

REM Quick setup
echo 🔧 Setting up environment...
python -m venv .venv
call .venv\Scripts\activate.bat
pip install -r requirements.txt --quiet

REM Create basic config
if not exist .env (
    echo Creating configuration...
    (
        echo FLASK_HOST=0.0.0.0
        echo FLASK_PORT=9090
        echo FLASK_DEBUG=False
        echo SECRET_KEY=simple-setup-%RANDOM%
        echo ARUBA_WS_HOST=0.0.0.0
        echo ARUBA_WS_PORT=9191
        echo ARUBA_AUTH_TOKENS=admin,test-token,aruba-iot
        echo LOG_LEVEL=INFO
    ) > .env
)

echo.
echo ✅ Setup complete!
echo.
echo 🚀 Starting server...
echo   Web Dashboard: http://localhost:9090
echo   WebSocket: ws://localhost:9191/aruba?token=admin
echo.
echo ⚠️  Press Ctrl+C to stop the server
echo.

python app.py

echo.
echo Server stopped.
pause
