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
echo ========================================
echo The application needs to allow incoming connections on:
echo - Port 9090 (Web Dashboard)
echo - Port 9191 (WebSocket Server)
echo.

REM Check if running as administrator
net session >nul 2>&1
if errorlevel 1 (
    echo ⚠️  Administrator privileges required for firewall configuration
    echo.
    echo Option 1: Run as Administrator (Recommended)
    echo -----------------------------------------
    echo 1. Right-click on Command Prompt and select "Run as administrator"
    echo 2. Navigate to this folder and run setup_windows.bat again
    echo.
    echo Option 2: Manual Firewall Configuration
    echo -------------------------------------
    echo 1. Open Windows Defender Firewall with Advanced Security
    echo 2. Click "Inbound Rules" ^> "New Rule"
    echo 3. Select "Port" ^> "TCP" ^> enter "9090,9191"
    echo 4. Select "Allow the connection"
    echo 5. Apply to all profiles and name it "Aruba IoT Telemetry"
    echo.
    echo Option 3: Continue without firewall changes (Local use only)
    echo ----------------------------------------------------------
    echo The application will work locally but won't accept external connections
    echo.
    set /p choice="Press 1 to restart as admin, 2 for manual setup, 3 to continue [1/2/3]: "
    
    if "%choice%"=="1" (
        echo Restarting as administrator...
        powershell -Command "Start-Process cmd -Verb RunAs -ArgumentList '/c cd /d \"%CD%\" && setup_windows.bat && pause'"
        exit /b 0
    )
    if "%choice%"=="2" (
        echo Please configure firewall manually as described above
        echo Press any key when done...
        pause >nul
    )
    if "%choice%"=="3" (
        echo ⚠️  Continuing without firewall configuration
        echo External connections will be blocked
    )
) else (
    echo ✅ Administrator privileges detected
    echo Adding firewall rules for ports 9090 and 9191...
    
    REM Add firewall rules using netsh (more reliable than PowerShell)
    netsh advfirewall firewall add rule name="Aruba IoT Web Dashboard" dir=in action=allow protocol=TCP localport=9090 >nul 2>&1
    if errorlevel 1 (
        echo ⚠️  Failed to add rule for port 9090
    ) else (
        echo ✅ Added firewall rule for port 9090 (Web Dashboard)
    )
    
    netsh advfirewall firewall add rule name="Aruba IoT WebSocket Server" dir=in action=allow protocol=TCP localport=9191 >nul 2>&1
    if errorlevel 1 (
        echo ⚠️  Failed to add rule for port 9191
    ) else (
        echo ✅ Added firewall rule for port 9191 (WebSocket Server)
    )
    
    REM Verify the rules were added
    echo.
    echo 🔍 Verifying firewall rules...
    netsh advfirewall firewall show rule name="Aruba IoT Web Dashboard" >nul 2>&1
    if errorlevel 1 (
        echo ❌ Web Dashboard firewall rule not found
    ) else (
        echo ✅ Web Dashboard firewall rule active
    )
    
    netsh advfirewall firewall show rule name="Aruba IoT WebSocket Server" >nul 2>&1
    if errorlevel 1 (
        echo ❌ WebSocket Server firewall rule not found
    ) else (
        echo ✅ WebSocket Server firewall rule active
    )
)

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
