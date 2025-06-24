@echo off
REM Start Aruba IoT Telemetry Server on Windows

echo 🚀 Starting Aruba IoT Telemetry Server...
echo ========================================

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

REM Check if .env file exists
if not exist .env (
    echo ❌ Configuration file (.env) not found!
    echo Please run setup_windows.bat first
    pause
    exit /b 1
)

REM Display network information
echo.
echo 🌐 Server will be available at:
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr "IPv4"') do (
    set "ip=%%a"
    setlocal enabledelayedexpansion
    echo    Web Dashboard: http://!ip::= !:9090
    echo    WebSocket: ws://!ip::= !:9191/aruba?token=YOUR_TOKEN
    endlocal
)

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
