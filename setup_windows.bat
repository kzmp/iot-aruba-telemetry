@echo off
REM Aruba IoT Telemetry Server - Windows Setup Script
echo.
echo 🚀 Aruba IoT Telemetry Server - Windows Setup
echo ============================================
echo.

REM Check if we're in the right directory
if not exist app.py (
    echo ❌ app.py not found in current directory!
    echo Please make sure you're running this script from the project folder
    echo.
    echo If you cloned with GitHub Desktop, the folder should be something like:
    echo C:\Users\%USERNAME%\Documents\GitHub\iot-aruba-telemetry
    echo.
    echo Current directory: %CD%
    pause
    exit /b 1
)

REM Check if Python is installed
echo 📋 Checking Python installation...
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Python is not installed or not in PATH
    echo.
    echo Please install Python from https://www.python.org/downloads/windows/
    echo ⚠️  IMPORTANT: Make sure to check "Add Python to PATH" during installation
    echo.
    echo After installing Python:
    echo 1. Restart Command Prompt
    echo 2. Run this script again
    pause
    exit /b 1
)

echo ✅ Python found
python --version

REM Create virtual environment
echo.
echo 🔧 Creating Python virtual environment...
python -m venv .venv
if errorlevel 1 (
    echo ❌ Failed to create virtual environment
    pause
    exit /b 1
)

REM Activate virtual environment
echo 🔧 Activating virtual environment...
call .venv\Scripts\activate.bat

REM Upgrade pip
echo 📦 Upgrading pip...
python -m pip install --upgrade pip

REM Install dependencies
echo 📦 Installing dependencies...
pip install -r requirements.txt
if errorlevel 1 (
    echo ❌ Failed to install dependencies
    pause
    exit /b 1
)

REM Create .env file if it doesn't exist
if not exist .env (
    echo ⚙️ Creating environment configuration...
    (
        echo # Flask Configuration
        echo FLASK_HOST=0.0.0.0
        echo FLASK_PORT=9090
        echo FLASK_DEBUG=False
        echo SECRET_KEY=windows-secret-key-%RANDOM%-%TIME:~6,2%
        echo.
        echo # Aruba WebSocket Server Configuration
        echo ARUBA_WS_HOST=0.0.0.0
        echo ARUBA_WS_PORT=9191
        echo.
        echo # Authentication Configuration - CHANGE THESE TOKENS!
        echo ARUBA_AUTH_TOKENS=admin-windows,secure-token-%RANDOM%,aruba-iot
        echo.
        echo # Logging Configuration
        echo LOG_LEVEL=INFO
    ) > .env
    echo ✅ Created .env file with default configuration
) else (
    echo ✅ .env file already exists
)

REM Test installation
echo.
echo 🧪 Testing installation...
python -c "import flask, flask_socketio, websockets; print('✅ All dependencies installed successfully')" 2>nul
if errorlevel 1 (
    echo ❌ Dependency test failed
    pause
    exit /b 1
)

REM Get IP addresses
echo.
echo 🌐 Network Configuration:
echo =========================
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr "IPv4"') do (
    echo 📍%%a
)

REM Create firewall rules
echo.
echo 🔥 Setting up Windows Firewall rules...
echo This requires Administrator privileges. You may see UAC prompts.
powershell -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -Command \"New-NetFirewallRule -DisplayName \"\"Aruba IoT Web\"\" -Direction Inbound -Protocol TCP -LocalPort 9090 -Action Allow -ErrorAction SilentlyContinue; New-NetFirewallRule -DisplayName \"\"Aruba IoT WebSocket\"\" -Direction Inbound -Protocol TCP -LocalPort 9191 -Action Allow -ErrorAction SilentlyContinue; Write-Host \"\"Firewall rules added successfully\"\"\"'"

echo.
echo ✅ Setup Complete!
echo ==================
echo.
echo 🚀 To start the server:
echo    .venv\Scripts\activate
echo    python app.py
echo.
echo 🌐 Access URLs:
echo    Web Dashboard: http://localhost:9090
echo    WebSocket: ws://YOUR_IP:9191/aruba?token=YOUR_TOKEN
echo.
echo 🔐 Your authentication tokens are in the .env file
echo    IMPORTANT: Change the default tokens before production use!
echo.
echo 📖 For detailed instructions, see: DEPLOYMENT_GUIDE.md
echo.
echo Press any key to continue...
pause >nul
