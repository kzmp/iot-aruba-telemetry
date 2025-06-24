@echo off
REM Start Aruba IoT Telemetry Server on Windows

echo 🚀 Starting Aruba IoT Telemetry Server...
echo ========================================

REM Check if we're in the right directory
if not exist app.py (
    echo ❌ app.py not found in current directory!
    echo Please make sure you're running this script from the project folder
    echo Current directory: %CD%
    pause
    exit /b 1
)

REM Check if Python is available
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Python is not installed or not in PATH!
    echo Please install Python from https://www.python.org/downloads/
    pause
    exit /b 1
)

echo ✅ Python found:
python --version

REM Check if virtual environment exists
if not exist .venv\Scripts\activate.bat (
    echo ❌ Virtual environment not found!
    echo Please run setup_windows.bat first
    pause
    exit /b 1
)

REM Activate virtual environment
echo 🔧 Activating virtual environment...
call .venv\Scripts\activate.bat
if errorlevel 1 (
    echo ❌ Failed to activate virtual environment
    pause
    exit /b 1
)

REM Check if .env file exists
if not exist .env (
    echo ❌ Configuration file (.env) not found!
    echo Please run setup_windows.bat first
    pause
    exit /b 1
)

REM Test if required packages are installed
echo 🧪 Testing dependencies...
python -c "import flask, flask_socketio, websockets" >nul 2>&1
if errorlevel 1 (
    echo ❌ Required packages not installed properly
    echo Please run setup_windows.bat again
    pause
    exit /b 1
)

echo ✅ Dependencies OK

REM Display network information
echo.
echo 🌐 Server will be available at:
echo    Web Dashboard: http://localhost:9090
echo    WebSocket: ws://localhost:9191/aruba?token=YOUR_TOKEN
echo.
echo 📍 Your IP addresses:
ipconfig | findstr "IPv4" | findstr /v "127.0.0.1"

echo.
echo 🔐 Check .env file for authentication tokens
echo 📖 See ARUBA_CONNECTION_GUIDE.md for connection details
echo.
echo ⚠️  Press Ctrl+C to stop the server
echo.

REM Start the application
python app.py

echo.
echo 🛑 Server stopped
pause
