@echo off
REM Aruba IoT Telemetry - Windows Troubleshooting Script

echo 🔍 Aruba IoT Telemetry - Windows Troubleshooting
echo ==============================================
echo.

echo 📋 System Information:
echo ======================
echo OS: %OS%
echo Computer: %COMPUTERNAME%
echo User: %USERNAME%
echo Current Directory: %CD%
echo.

echo 🐍 Python Check:
echo ================
python --version 2>nul
if errorlevel 1 (
    echo ❌ Python not found in PATH
    echo Please install Python from https://www.python.org/downloads/
    echo Make sure to check "Add Python to PATH" during installation
) else (
    echo ✅ Python found
    python -c "import sys; print('Python path:', sys.executable)"
)
echo.

echo 📁 Project Files Check:
echo =======================
if exist app.py (
    echo ✅ app.py found
) else (
    echo ❌ app.py NOT found - are you in the right directory?
)

if exist requirements.txt (
    echo ✅ requirements.txt found
) else (
    echo ❌ requirements.txt NOT found
)

if exist .env (
    echo ✅ .env configuration file found
) else (
    echo ❌ .env configuration file NOT found - run setup_windows.bat
)

if exist .venv (
    echo ✅ Virtual environment folder found
    if exist .venv\Scripts\activate.bat (
        echo ✅ Virtual environment activation script found
    ) else (
        echo ❌ Virtual environment activation script NOT found
    )
) else (
    echo ❌ Virtual environment NOT found - run setup_windows.bat
)
echo.

echo 🌐 Network Information:
echo =======================
echo Available IP addresses:
ipconfig | findstr "IPv4"
echo.

echo 🔥 Firewall Check:
echo ==================
echo Checking Windows Firewall rules for Aruba IoT...

REM Check if firewall rules exist
netsh advfirewall firewall show rule name="Aruba IoT Web Dashboard" >nul 2>&1
if errorlevel 1 (
    echo ❌ Web Dashboard firewall rule NOT found
    echo   Port 9090 may be blocked for external connections
) else (
    echo ✅ Web Dashboard firewall rule found
)

netsh advfirewall firewall show rule name="Aruba IoT WebSocket Server" >nul 2>&1
if errorlevel 1 (
    echo ❌ WebSocket Server firewall rule NOT found
    echo   Port 9191 may be blocked for external connections
) else (
    echo ✅ WebSocket Server firewall rule found
)

REM Check if ports are in use
echo.
echo Checking if ports are accessible...
netstat -an | findstr ":9090" >nul 2>&1
if errorlevel 1 (
    echo ❌ Port 9090 not listening (server not running)
) else (
    echo ✅ Port 9090 is listening
)

netstat -an | findstr ":9191" >nul 2>&1
if errorlevel 1 (
    echo ❌ Port 9191 not listening (server not running)
) else (
    echo ✅ Port 9191 is listening
)
echo.

echo 📦 Dependencies Check:
echo ======================
if exist .venv\Scripts\activate.bat (
    call .venv\Scripts\activate.bat
    echo Testing Python packages...
    python -c "import flask; print('✅ Flask:', flask.__version__)" 2>nul || echo "❌ Flask not installed"
    python -c "import flask_socketio; print('✅ Flask-SocketIO:', flask_socketio.__version__)" 2>nul || echo "❌ Flask-SocketIO not installed"
    python -c "import websockets; print('✅ WebSockets:', websockets.__version__)" 2>nul || echo "❌ WebSockets not installed"
    python -c "import dotenv; print('✅ Python-dotenv available')" 2>nul || echo "❌ Python-dotenv not installed"
) else (
    echo ❌ Cannot check dependencies - virtual environment not found
)
echo.

echo 🔧 Common Solutions:
echo ====================
echo 1. If Python is not found:
echo    - Download and install Python from https://www.python.org/downloads/
echo    - Make sure to check "Add Python to PATH" during installation
echo    - Restart Command Prompt after installation
echo.
echo 2. If virtual environment is missing:
echo    - Run: setup_windows.bat
echo.
echo 3. If dependencies are missing:
echo    - Run: setup_windows.bat
echo    - Or manually: .venv\Scripts\activate.bat ^&^& pip install -r requirements.txt
echo.
echo 4. If firewall rules are missing:
echo    - Run: configure_firewall.bat (as Administrator)
echo    - Or run: setup_windows.bat (as Administrator)
echo    - Or manually configure Windows Firewall for ports 9090 and 9191
echo.
echo 5. If ports are blocked:
echo    - Make sure Windows Firewall allows the application
echo    - Check if antivirus software is blocking the ports
echo    - Verify no other applications are using ports 9090 or 9191
echo.
echo 5. If app.py is not found:
echo    - Make sure you're in the correct project directory
echo    - The directory should contain app.py, requirements.txt, etc.
echo.
echo 6. If external connections fail:
echo    - Run: configure_firewall.bat (as Administrator)
echo    - Check router/network firewall settings
echo    - Verify the correct IP address is being used
echo.

echo 📞 Still having issues?
echo =======================
echo Check the documentation:
echo - README.md
echo - DEPLOYMENT_GUIDE.md
echo - ARUBA_CONNECTION_GUIDE.md
echo.
echo Or visit: https://github.com/kzmp/iot-aruba-telemetry
echo.

pause
