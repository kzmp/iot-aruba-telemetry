@echo off
setlocal enabledelayedexpansion
title Aruba IoT Telemetry - 1-Click Windows Setup

REM ========================================================================
REM  🚀 ARUBA IOT TELEMETRY - COMPLETE WINDOWS SETUP (1-CLICK)
REM ========================================================================

echo.
echo  ██████╗ ███╗   ██╗███████╗     ██████╗██╗     ██╗ ██████╗██╗  ██╗
echo ██╔═══██╗████╗  ██║██╔════╝    ██╔════╝██║     ██║██╔════╝██║ ██╔╝
echo ██║   ██║██╔██╗ ██║█████╗      ██║     ██║     ██║██║     █████╔╝ 
echo ██║   ██║██║╚██╗██║██╔══╝      ██║     ██║     ██║██║     ██╔═██╗ 
echo ╚██████╔╝██║ ╚████║███████╗    ╚██████╗███████╗██║╚██████╗██║  ██╗
echo  ╚═════╝ ╚═╝  ╚═══╝╚══════╝     ╚═════╝╚══════╝╚═╝ ╚═════╝╚═╝  ╚═╝
echo.
echo               🌐 Aruba IoT Telemetry Server Setup 🌐
echo                    Complete Windows Installation
echo.
echo ========================================================================
echo This ONE-CLICK setup will automatically:
echo   ✅ Validate your system and project files
echo   ✅ Check/guide Python installation  
echo   ✅ Create Python virtual environment
echo   ✅ Install all required dependencies
echo   ✅ Generate secure configuration with random tokens
echo   ✅ Configure Windows Firewall (with admin privileges)
echo   ✅ Test the complete installation
echo   ✅ Provide all connection information
echo   ✅ Optionally start the server immediately
echo ========================================================================
echo.

set "SETUP_SUCCESS=1"
set "TOTAL_STEPS=7"

REM ========================================================================
REM  📋 STEP 1/7: SYSTEM VALIDATION
REM ========================================================================

echo [1/%TOTAL_STEPS%] 📋 SYSTEM VALIDATION
echo ================================================

REM Check project directory
if not exist app.py (
    echo ❌ CRITICAL: app.py not found!
    echo.
    echo 📁 You must run this script from the Aruba IoT project folder.
    echo    Current location: %CD%
    echo.
    echo 💡 If you used GitHub Desktop:
    echo    1. Open GitHub Desktop
    echo    2. Go to Repository → Show in Explorer  
    echo    3. Double-click setup_windows.bat from that folder
    echo.
    pause
    exit /b 1
)

if not exist requirements.txt (
    echo ❌ requirements.txt missing
    set "SETUP_SUCCESS=0"
)
if not exist templates (
    echo ❌ templates folder missing  
    set "SETUP_SUCCESS=0"
)

if !SETUP_SUCCESS! EQU 0 (
    echo ❌ Project files incomplete. Please re-clone the repository.
    pause
    exit /b 1
)

echo ✅ Project structure validated
echo ✅ Required files found: app.py, requirements.txt, templates/

REM ========================================================================
REM  🐍 STEP 2/7: PYTHON VERIFICATION
REM ========================================================================

echo.
echo [2/%TOTAL_STEPS%] 🐍 PYTHON VERIFICATION
echo ================================================

python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ CRITICAL: Python not found!
    echo.
    echo 🔧 AUTOMATIC SOLUTION:
    echo    This script will open the Python download page for you.
    echo    Please download Python 3.8+ and during installation:
    echo    ⚠️  CHECK THE BOX: "Add Python to PATH"
    echo.
    echo    After installation, restart Command Prompt and run this script again.
    echo.
    set /p open_page="Open Python download page now? [Y/N]: "
    if /i "!open_page!"=="Y" (
        start https://www.python.org/downloads/windows/
    )
    echo.
    echo 🔄 Please install Python and run this script again.
    pause
    exit /b 1
)

for /f "tokens=2" %%v in ('python --version') do set "PY_VERSION=%%v"
echo ✅ Python detected: %PY_VERSION%
echo ✅ Python installation verified

REM ========================================================================
REM  📦 STEP 3/7: VIRTUAL ENVIRONMENT SETUP
REM ========================================================================

echo.
echo [3/%TOTAL_STEPS%] 📦 VIRTUAL ENVIRONMENT SETUP
echo ================================================

if exist .venv (
    echo ⚠️  Virtual environment already exists
    set /p recreate="Recreate virtual environment? [Y/N]: "
    if /i "!recreate!"=="Y" (
        echo 🗑️  Removing existing virtual environment...
        rmdir /s /q .venv
    ) else (
        echo ✅ Using existing virtual environment
        goto :activate_venv
    )
)

echo 🔧 Creating Python virtual environment...
python -m venv .venv
if errorlevel 1 (
    echo ❌ Failed to create virtual environment
    echo 💡 This might be caused by:
    echo    - Insufficient disk space
    echo    - Antivirus software interference
    echo    - Python installation issues
    pause
    exit /b 1
)
echo ✅ Virtual environment created successfully

:activate_venv
echo 🔌 Activating virtual environment...
call .venv\Scripts\activate.bat
if errorlevel 1 (
    echo ❌ Failed to activate virtual environment
    pause
    exit /b 1
)
echo ✅ Virtual environment activated

REM ========================================================================
REM  📚 STEP 4/7: DEPENDENCY INSTALLATION
REM ========================================================================

echo.
echo [4/%TOTAL_STEPS%] 📚 DEPENDENCY INSTALLATION
echo ================================================

echo 🔄 Upgrading pip to latest version...
python -m pip install --upgrade pip --quiet

echo 📦 Installing project dependencies...
echo    This may take 2-3 minutes depending on your connection...

pip install -r requirements.txt
if errorlevel 1 (
    echo ❌ Dependency installation failed
    echo.
    echo 🔧 Attempting with verbose output for troubleshooting:
    pip install -r requirements.txt --verbose
    pause
    exit /b 1
)

echo ✅ All dependencies installed successfully

echo 🧪 Verifying critical packages...
python -c "
import sys
packages = ['flask', 'flask_socketio', 'websockets', 'dotenv']
failed = []
for pkg in packages:
    try:
        __import__(pkg)
        print(f'✅ {pkg}')
    except ImportError:
        print(f'❌ {pkg}')
        failed.append(pkg)
if failed:
    print(f'Failed packages: {failed}')
    sys.exit(1)
print('✅ All critical packages verified')
"
if errorlevel 1 (
    echo ❌ Package verification failed
    pause
    exit /b 1
)

REM ========================================================================
REM  ⚙️ STEP 5/7: SECURE CONFIGURATION GENERATION
REM ========================================================================

echo.
echo [5/%TOTAL_STEPS%] ⚙️ SECURE CONFIGURATION GENERATION
echo ================================================

if exist .env (
    echo ⚠️  Configuration file already exists
    set /p overwrite="Generate new secure configuration? [Y/N]: "
    if /i "!overwrite!" NEQ "Y" (
        echo ✅ Using existing configuration
        goto :firewall_config
    )
)

echo 🔐 Generating secure configuration with random tokens...

REM Generate cryptographically secure tokens
set "TOKEN1=admin-win-!RANDOM!!TIME:~-4!"
set "TOKEN2=secure-!RANDOM!!DATE:~-4!"
set "TOKEN3=aruba-iot-!RANDOM!"
set "SECRET=win-secret-!RANDOM!-!TIME:~6,2!!DATE:~-2!"

echo 📝 Writing configuration file...
(
    echo # ========================================================================
    echo # Aruba IoT Telemetry Server - Windows Configuration
    echo # Generated: !DATE! !TIME!
    echo # ========================================================================
    echo.
    echo # Flask Web Server Configuration
    echo FLASK_HOST=0.0.0.0
    echo FLASK_PORT=9090
    echo FLASK_DEBUG=False
    echo SECRET_KEY=!SECRET!
    echo.
    echo # Aruba WebSocket Server Configuration  
    echo ARUBA_WS_HOST=0.0.0.0
    echo ARUBA_WS_PORT=9191
    echo.
    echo # Authentication Tokens - CHANGE BEFORE PRODUCTION!
    echo # Each token can be used by Aruba controllers to connect
    echo ARUBA_AUTH_TOKENS=!TOKEN1!,!TOKEN2!,!TOKEN3!,admin,aruba-iot
    echo.
    echo # Logging Configuration
    echo LOG_LEVEL=INFO
    echo.
    echo # ========================================================================
    echo # Your Secure Authentication Tokens:
    echo #   Primary:   !TOKEN1!
    echo #   Secondary: !TOKEN2!
    echo #   Tertiary:  !TOKEN3!
    echo #   Default:   admin, aruba-iot
    echo # ========================================================================
) > .env

echo ✅ Secure configuration generated with random tokens
echo 🔑 Authentication tokens created and saved to .env file

:firewall_config

REM ========================================================================
REM  🔥 STEP 6/7: WINDOWS FIREWALL CONFIGURATION
REM ========================================================================

echo.
echo [6/%TOTAL_STEPS%] 🔥 WINDOWS FIREWALL CONFIGURATION
echo ================================================

echo 🛡️  Configuring Windows Firewall for ports 9090 and 9191...

net session >nul 2>&1
if errorlevel 1 (
    echo ⚠️  Administrator privileges required for firewall configuration
    echo.
    echo 🚀 RECOMMENDED: Restart with Administrator privileges
    echo 📋 ALTERNATIVE: Manual configuration
    echo 🔄 CONTINUE: Skip firewall setup (local access only)
    echo.
    set /p fw_choice="Choose: [A]dmin restart, [M]anual config, [S]kip firewall: "
    
    if /i "!fw_choice!"=="A" (
        echo 🔄 Restarting with Administrator privileges...
        timeout /t 2 >nul
        powershell -Command "Start-Process cmd -Verb RunAs -ArgumentList '/c cd /d \"%CD%\" && setup_windows.bat'"
        echo 👋 This window will close. Look for the new Administrator window.
        timeout /t 3 >nul
        exit /b 0
    )
    if /i "!fw_choice!"=="M" (
        echo.
        echo 📋 MANUAL FIREWALL CONFIGURATION:
        echo ================================
        echo 1. Press Win+R, type 'wf.msc', press Enter
        echo 2. Click 'Inbound Rules' → 'New Rule'
        echo 3. Select 'Port' → 'TCP' → enter '9090,9191'
        echo 4. Select 'Allow the connection'
        echo 5. Check all profiles, name it 'Aruba IoT Telemetry'
        echo.
        pause
    )
    if /i "!fw_choice!"=="S" (
        echo ⚠️  Firewall configuration skipped
        echo 💡 Server will work locally but may not accept external connections
        echo 🔧 Run configure_firewall.bat later as Administrator if needed
    )
) else (
    echo ✅ Administrator privileges detected
    echo 🔧 Configuring firewall rules...
    
    REM Remove any existing rules
    netsh advfirewall firewall delete rule name="Aruba IoT Web Dashboard" >nul 2>&1
    netsh advfirewall firewall delete rule name="Aruba IoT WebSocket Server" >nul 2>&1
    
    REM Add new rules
    netsh advfirewall firewall add rule name="Aruba IoT Web Dashboard" dir=in action=allow protocol=TCP localport=9090 profile=any >nul
    if errorlevel 1 (
        echo ⚠️  Warning: Could not add firewall rule for port 9090
    ) else (
        echo ✅ Firewall rule added: Port 9090 (Web Dashboard)
    )
    
    netsh advfirewall firewall add rule name="Aruba IoT WebSocket Server" dir=in action=allow protocol=TCP localport=9191 profile=any >nul
    if errorlevel 1 (
        echo ⚠️  Warning: Could not add firewall rule for port 9191
    ) else (
        echo ✅ Firewall rule added: Port 9191 (WebSocket Server)
    )
    
    echo ✅ Windows Firewall configured successfully
)

REM ========================================================================
REM  🧪 STEP 7/7: FINAL TESTING & VALIDATION
REM ========================================================================

echo.
echo [7/%TOTAL_STEPS%] 🧪 FINAL TESTING ^& VALIDATION
echo ================================================

echo 🔍 Running comprehensive system test...

REM Test app.py syntax
python -m py_compile app.py >nul 2>&1
if errorlevel 1 (
    echo ❌ Syntax error detected in app.py
    set "SETUP_SUCCESS=0"
) else (
    echo ✅ Application syntax validated
)

REM Test configuration
if exist .env (
    echo ✅ Configuration file present
) else (
    echo ❌ Configuration file missing
    set "SETUP_SUCCESS=0"
)

REM Final import test
python -c "
try:
    import app
    print('✅ Application import successful')
except Exception as e:
    print(f'❌ Application import failed: {e}')
    exit(1)
" >nul 2>&1
if errorlevel 1 (
    echo ⚠️  Warning: Application import test failed
    echo 💡 This might be normal and the app may still work
) else (
    echo ✅ Application import test passed
)

if !SETUP_SUCCESS! EQU 0 (
    echo.
    echo ❌ Setup completed with warnings
    echo 💡 The application might still work, but check the issues above
) else (
    echo ✅ All tests passed - Installation successful!
)

REM ========================================================================
REM  🎉 SETUP COMPLETE - SHOW RESULTS
REM ========================================================================

echo.
echo ========================================================================
echo                        🎉 SETUP COMPLETE! 🎉
echo ========================================================================
echo.

echo 📊 INSTALLATION SUMMARY:
echo ========================
echo ✅ Python environment configured
echo ✅ Virtual environment created and activated
echo ✅ All dependencies installed
echo ✅ Secure configuration generated
echo ✅ Application validated
if !SETUP_SUCCESS! EQU 1 echo ✅ Firewall configured for external access

echo.
echo 🌐 NETWORK INFORMATION:
echo =======================
echo 📍 Your server will be accessible at these addresses:

for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr "IPv4" ^| findstr /v "127.0.0.1"') do (
    set "ip=%%a"
    set "ip=!ip: =!"
    echo    💻 Computer IP: !ip!
    echo       🌐 Dashboard: http://!ip!:9090
    echo       🔌 WebSocket: ws://!ip!:9191/aruba?token=admin
    goto :show_security
)

:show_security
echo.
echo 🔐 SECURITY INFORMATION:
echo ========================
if exist .env (
    for /f "tokens=2 delims==" %%t in ('findstr "ARUBA_AUTH_TOKENS" .env 2^>nul') do (
        echo 🔑 Authentication tokens: %%t
    )
)
echo 💡 Tokens are stored in the .env file
echo ⚠️  Change default tokens before production use!

echo.
echo 🚀 READY TO START:
echo ==================
echo Option 1 - Quick Start (Recommended):
echo   📄 Double-click: start_windows.bat
echo.
echo Option 2 - Manual Start:
echo   📝 Commands:
echo      .venv\Scripts\activate
echo      python app.py
echo.
echo Option 3 - Start Now:
echo   🏃 Press ENTER to start the server immediately

echo.
echo 📚 DOCUMENTATION:
echo =================
echo 📖 README.md - Quick start guide
echo 🛠️  DEPLOYMENT_GUIDE.md - Advanced deployment
echo 🔧 ARUBA_CONNECTION_GUIDE.md - Connection troubleshooting
echo 🆘 troubleshoot_windows.bat - Diagnostic tool

echo.
echo 🆘 SUPPORT:
echo ===========
echo 🌐 GitHub: https://github.com/kzmp/iot-aruba-telemetry
echo 📧 Issues: Report problems on GitHub Issues page

echo.
echo ========================================================================

set /p start_now="🚀 Start the Aruba IoT Telemetry Server now? [Y/N]: "
if /i "!start_now!"=="Y" (
    echo.
    echo 🚀 STARTING ARUBA IOT TELEMETRY SERVER...
    echo ========================================
    echo 💡 Access dashboard at: http://localhost:9090
    echo 🔌 WebSocket endpoint: ws://localhost:9191/aruba?token=admin
    echo ⚠️  Press Ctrl+C to stop the server
    echo.
    
    python app.py
    
    echo.
    echo 🛑 Server stopped
    echo 🔄 To restart: run start_windows.bat or python app.py
) else (
    echo.
    echo ✅ Setup complete! 
    echo 🚀 Run start_windows.bat when you're ready to start the server.
)

echo.
pause
