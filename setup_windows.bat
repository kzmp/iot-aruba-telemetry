@echo off
setlocal enabledelayedexpansion

REM ========================================================================
REM  Aruba IoT Telemetry Server - Complete Windows Setup (1-Click)
REM ========================================================================

title Aruba IoT Telemetry Server - Windows Setup

echo.
echo 🚀 Aruba IoT Telemetry Server - Complete Windows Setup
echo =====================================================
echo This script will automatically:
echo   ✓ Check Python installation
echo   ✓ Create virtual environment
echo   ✓ Install all dependencies
echo   ✓ Configure environment settings
echo   ✓ Setup Windows Firewall
echo   ✓ Test the installation
echo   ✓ Provide connection information
echo.

set "SETUP_ERROR=0"

REM ========================================================================
REM  Step 1: Validate Environment
REM ========================================================================

echo 📋 Step 1/7: Validating environment...
echo =====================================

REM Check if we're in the right directory
if not exist app.py (
    echo ❌ CRITICAL ERROR: app.py not found in current directory!
    echo.
    echo This script must be run from the Aruba IoT project folder.
    echo Current directory: %CD%
    echo.
    echo Expected files: app.py, requirements.txt, templates folder
    echo.
    echo If you used GitHub Desktop:
    echo   1. Open GitHub Desktop
    echo   2. Go to Repository ^> Show in Explorer
    echo   3. Run this script from that folder
    echo.
    pause
    exit /b 1
)

REM Verify required files exist
if not exist requirements.txt (
    echo ❌ requirements.txt not found
    set "SETUP_ERROR=1"
)
if not exist templates (
    echo ❌ templates folder not found
    set "SETUP_ERROR=1"
)

if !SETUP_ERROR! EQU 1 (
    echo ❌ Missing required project files
    pause
    exit /b 1
)

echo ✅ Project files validated

REM Check Python installation
echo.
echo � Checking Python installation...
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ CRITICAL ERROR: Python is not installed or not in PATH
    echo.
    echo AUTOMATED SOLUTION:
    echo ===================
    echo 1. This script will open the Python download page
    echo 2. Download Python 3.8 or higher
    echo 3. During installation, CHECK "Add Python to PATH"
    echo 4. After installation, restart Command Prompt
    echo 5. Run this script again
    echo.
    set /p choice="Press Y to open Python download page, N to exit [Y/N]: "
    if /i "!choice!"=="Y" (
        echo Opening Python download page...
        start https://www.python.org/downloads/windows/
    )
    echo.
    echo Please install Python and run this script again.
    pause
    exit /b 1
)

echo ✅ Python found: 
python --version
echo.

REM Check Python version
for /f "tokens=2" %%i in ('python --version 2^>^&1') do set "PYTHON_VERSION=%%i"
echo Python version: %PYTHON_VERSION%

REM ========================================================================
REM  Step 2: Virtual Environment Setup
REM ========================================================================

echo 📦 Step 2/7: Setting up Python virtual environment...
echo ===================================================

if exist .venv (
    echo ⚠️  Virtual environment already exists
    set /p choice="Delete and recreate? [Y/N]: "
    if /i "!choice!"=="Y" (
        echo Removing existing virtual environment...
        rmdir /s /q .venv
    )
)

if not exist .venv (
    echo Creating new virtual environment...
    python -m venv .venv
    if errorlevel 1 (
        echo ❌ Failed to create virtual environment
        echo This might be due to:
        echo   - Insufficient disk space
        echo   - Antivirus blocking Python
        echo   - Corrupted Python installation
        pause
        exit /b 1
    )
    echo ✅ Virtual environment created
) else (
    echo ✅ Using existing virtual environment
)

REM Activate virtual environment
echo Activating virtual environment...
call .venv\Scripts\activate.bat
if errorlevel 1 (
    echo ❌ Failed to activate virtual environment
    pause
    exit /b 1
)

echo ✅ Virtual environment activated

REM ========================================================================
REM  Step 3: Dependency Installation
REM ========================================================================

echo.
echo � Step 3/7: Installing dependencies...
echo ======================================

echo Upgrading pip...
python -m pip install --upgrade pip --quiet

echo Installing required packages...
echo This may take a few minutes...

pip install -r requirements.txt --quiet
if errorlevel 1 (
    echo ❌ Failed to install dependencies
    echo.
    echo Trying with verbose output for debugging:
    pip install -r requirements.txt
    pause
    exit /b 1
)

echo ✅ All dependencies installed successfully

REM Verify critical packages
echo.
echo 🧪 Verifying package installation...
python -c "import flask, flask_socketio, websockets; print('✅ Core packages verified')" 2>nul
if errorlevel 1 (
    echo ❌ Package verification failed
    echo Attempting to reinstall critical packages...
    pip install flask flask-socketio websockets python-dotenv
)

REM ========================================================================
REM  Step 4: Configuration Setup
REM ========================================================================

echo.
echo ⚙️ Step 4/7: Creating configuration...
echo ====================================

if exist .env (
    echo ⚠️  Configuration file (.env) already exists
    set /p choice="Overwrite with new configuration? [Y/N]: "
    if /i "!choice!" NEQ "Y" (
        echo Using existing configuration
        goto :firewall_setup
    )
)

echo Creating secure configuration file...

REM Generate random tokens
set "TOKEN1=admin-!RANDOM!"
set "TOKEN2=secure-!TIME:~6,2!!RANDOM!"
set "TOKEN3=aruba-iot-!RANDOM!"
set "SECRET_KEY=windows-secret-!RANDOM!-!TIME:~6,2!"

(
    echo # Flask Configuration
    echo FLASK_HOST=0.0.0.0
    echo FLASK_PORT=9090
    echo FLASK_DEBUG=False
    echo SECRET_KEY=!SECRET_KEY!
    echo.
    echo # Aruba WebSocket Server Configuration
    echo ARUBA_WS_HOST=0.0.0.0
    echo ARUBA_WS_PORT=9191
    echo.
    echo # Authentication Configuration
    echo # CHANGE THESE TOKENS BEFORE PRODUCTION USE!
    echo ARUBA_AUTH_TOKENS=!TOKEN1!,!TOKEN2!,!TOKEN3!,admin,aruba-iot
    echo.
    echo # Logging Configuration
    echo LOG_LEVEL=INFO
    echo.
    echo # Generated on: !DATE! !TIME!
    echo # Your secure tokens:
    echo #   Token 1: !TOKEN1!
    echo #   Token 2: !TOKEN2!  
    echo #   Token 3: !TOKEN3!
) > .env

echo ✅ Configuration file created with secure random tokens

:firewall_setup
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
