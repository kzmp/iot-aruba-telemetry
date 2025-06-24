@echo off
REM Aruba IoT Telemetry Server - One-Click Windows Setup with Debug
REM This script automates the complete installation process with error handling

SETLOCAL EnableDelayedExpansion EnableExtensions

echo.
echo 🚀 Aruba IoT Telemetry Server - One-Click Windows Setup (DEBUG MODE)
echo ================================================================
echo This script will automatically:
echo ✅ Check Python installation
echo ✅ Create virtual environment
echo ✅ Install all dependencies
echo ✅ Configure environment variables
echo ✅ Setup Windows Firewall
echo ✅ Test the installation
echo ✅ Start the server
echo.
echo 🐛 DEBUG MODE: Detailed error reporting enabled
echo.

REM Create debug log file
set "DEBUG_LOG=%CD%\setup_debug.log"
echo [%DATE% %TIME%] Setup started > "%DEBUG_LOG%"

REM Set colors for better output
for /F %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
set "GREEN=%ESC%[92m"
set "RED=%ESC%[91m"
set "YELLOW=%ESC%[93m"
set "BLUE=%ESC%[94m"
set "CYAN=%ESC%[96m"
set "RESET=%ESC%[0m"

REM Initialize variables
set "SETUP_ERROR=0"
set "PYTHON_OK=0"
set "VENV_OK=0"
set "DEPS_OK=0"
set "CONFIG_OK=0"
set "FIREWALL_OK=0"
set "STEP_COUNT=0"

REM Debug function
:DEBUG_LOG
echo [%DATE% %TIME%] %~1 >> "%DEBUG_LOG%"
echo %CYAN%[DEBUG]%RESET% %~1
goto :eof

echo %BLUE%Step 1: Checking prerequisites...%RESET%
echo ==========================================
set /a STEP_COUNT=1
call :DEBUG_LOG "Step 1: Starting prerequisite checks"

REM Try-Catch: Check if we're in the right directory
call :DEBUG_LOG "Checking for app.py in current directory: %CD%"
if not exist app.py (
    call :DEBUG_LOG "ERROR: app.py not found in %CD%"
    echo %RED%❌ app.py not found in current directory!%RESET%
    echo Please make sure you're running this script from the project folder
    echo.
    echo If you cloned with GitHub Desktop, the folder should be something like:
    echo C:\Users\%USERNAME%\Documents\GitHub\iot-aruba-telemetry
    echo.
    echo Current directory: %CD%
    echo Directory contents:
    dir /b
    call :DEBUG_LOG "Directory contents: "
    dir /b >> "%DEBUG_LOG%"
    
    echo.
    echo %YELLOW%Would you like to navigate to the correct folder? (y/n)%RESET%
    set /p navigate="Enter your choice: "
    if /i "!navigate!"=="y" (
        echo Please enter the full path to your iot-aruba-telemetry folder:
        set /p project_path="Path: "
        call :DEBUG_LOG "User provided path: !project_path!"
        if exist "!project_path!\app.py" (
            cd /d "!project_path!"
            call :DEBUG_LOG "Successfully changed to directory: !project_path!"
            echo %GREEN%✅ Changed to correct directory%RESET%
        ) else (
            call :DEBUG_LOG "ERROR: app.py not found in user-provided path: !project_path!"
            echo %RED%❌ app.py not found in specified directory%RESET%
            echo Available files in that directory:
            dir "!project_path!" /b 2>nul || echo "Directory not accessible"
            set "SETUP_ERROR=1"
            goto :error_summary
        )
    ) else (
        call :DEBUG_LOG "User chose not to navigate to correct folder"
        set "SETUP_ERROR=1"
        goto :error_summary
    )
) else (
    call :DEBUG_LOG "SUCCESS: app.py found in current directory"
    echo %GREEN%✅ Project directory verified%RESET%
)

REM Try-Catch: Check if Python is installed
call :DEBUG_LOG "Checking Python installation"
echo.
echo Checking Python installation...
python --version >nul 2>&1
set "PYTHON_EXIT_CODE=!ERRORLEVEL!"
call :DEBUG_LOG "Python version check exit code: !PYTHON_EXIT_CODE!"

if !PYTHON_EXIT_CODE! neq 0 (
    call :DEBUG_LOG "Python not found in PATH, attempting to locate"
    echo %RED%❌ Python is not installed or not in PATH%RESET%
    echo.
    echo Current PATH: %PATH%
    call :DEBUG_LOG "Current PATH: %PATH%"
    
    echo %YELLOW%Option 1: Download and Install Python%RESET%
    echo =====================================
    echo 1. Go to https://www.python.org/downloads/windows/
    echo 2. Download Python 3.8 or newer
    echo 3. During installation, CHECK "Add Python to PATH"
    echo 4. Restart this script after installation
    echo.
    echo %YELLOW%Option 2: Try to detect Python in common locations%RESET%
    echo =================================================
    
    REM Try to find Python in common locations
    set "PYTHON_FOUND=0"
    call :DEBUG_LOG "Searching for Python in common locations"
    
    for %%p in (
        "C:\Python3*\python.exe"
        "C:\Program Files\Python3*\python.exe" 
        "C:\Program Files (x86)\Python3*\python.exe"
        "%LOCALAPPDATA%\Programs\Python\Python3*\python.exe"
        "%USERPROFILE%\AppData\Local\Programs\Python\Python3*\python.exe"
        "%APPDATA%\Python\Python3*\python.exe"
    ) do (
        call :DEBUG_LOG "Checking path: %%p"
        for /f "delims=" %%f in ('dir "%%p" /b 2^>nul') do (
            set "PYTHON_PATH=%%~dpf%%f"
            call :DEBUG_LOG "Found Python at: !PYTHON_PATH!"
            echo Found Python at: !PYTHON_PATH!
            set "PYTHON_FOUND=1"
            goto :python_found
        )
    )
    
    :python_found
    if !PYTHON_FOUND!==1 (
        echo %YELLOW%Found Python installation. Testing accessibility...%RESET%
        for %%i in ("!PYTHON_PATH!") do set "PYTHON_DIR=%%~dpi"
        call :DEBUG_LOG "Python directory: !PYTHON_DIR!"
        set "PATH=!PYTHON_DIR!;!PYTHON_DIR!Scripts;!PATH!"
        call :DEBUG_LOG "Updated PATH: !PATH!"
        
        python --version >nul 2>&1
        set "PYTHON_TEST_EXIT=!ERRORLEVEL!"
        call :DEBUG_LOG "Python test after PATH update exit code: !PYTHON_TEST_EXIT!"
        
        if !PYTHON_TEST_EXIT!==0 (
            echo %GREEN%✅ Python is now accessible%RESET%
            set "PYTHON_OK=1"
            python --version
        ) else (
            call :DEBUG_LOG "ERROR: Python still not accessible after PATH update"
            echo %RED%❌ Python found but not accessible%RESET%
        )
    )
    
    if !PYTHON_OK!==0 (
        call :DEBUG_LOG "FATAL: Could not find or access Python"
        echo %RED%❌ Could not find or access Python%RESET%
        echo.
        echo Debugging information:
        echo - Windows version: 
        ver
        echo - Current user: %USERNAME%
        echo - Current directory: %CD%
        echo - Available drives:
        wmic logicaldisk get size,freespace,caption
        set "SETUP_ERROR=1"
        goto :error_summary
    )
) else (
    set "PYTHON_OK=1"
    call :DEBUG_LOG "SUCCESS: Python found in PATH"
    echo %GREEN%✅ Python found:%RESET%
    python --version
    python --version >> "%DEBUG_LOG%"
)

echo.
echo %BLUE%Step 2: Creating Python virtual environment...%RESET%
echo ==============================================

if exist .venv (
    echo %YELLOW%⚠️  Virtual environment already exists%RESET%
    echo Would you like to recreate it? (recommended) (y/n)
    set /p recreate="Enter your choice: "
    if /i "!recreate!"=="y" (
        echo Removing existing virtual environment...
        rmdir /s /q .venv 2>nul
    )
)

if not exist .venv (
    echo Creating virtual environment...
    python -m venv .venv
    if errorlevel 1 (
        echo %RED%❌ Failed to create virtual environment%RESET%
        set "SETUP_ERROR=1"
        goto :error_summary
    ) else (
        echo %GREEN%✅ Virtual environment created successfully%RESET%
        set "VENV_OK=1"
    )
) else (
    echo %GREEN%✅ Using existing virtual environment%RESET%
    set "VENV_OK=1"
)

echo.
echo %BLUE%Step 3: Installing dependencies...%RESET%
echo ==================================

echo Activating virtual environment...
call .venv\Scripts\activate.bat
if errorlevel 1 (
    echo %RED%❌ Failed to activate virtual environment%RESET%
    set "SETUP_ERROR=1"
    goto :error_summary
)

echo Upgrading pip...
python -m pip install --upgrade pip --quiet

echo Installing required packages...
pip install -r requirements.txt --quiet
if errorlevel 1 (
    echo %RED%❌ Failed to install dependencies%RESET%
    echo Trying with verbose output...
    pip install -r requirements.txt
    set "SETUP_ERROR=1"
    goto :error_summary
) else (
    echo %GREEN%✅ Dependencies installed successfully%RESET%
    set "DEPS_OK=1"
)

echo.
echo %BLUE%Step 4: Configuring environment...%RESET%
echo ===================================

if exist .env (
    echo %YELLOW%⚠️  Configuration file already exists%RESET%
    echo Would you like to recreate it? (y/n)
    set /p recreate_env="Enter your choice: "
    if /i "!recreate_env!"=="y" (
        del .env
        goto :create_env
    ) else (
        echo %GREEN%✅ Using existing configuration%RESET%
        set "CONFIG_OK=1"
        goto :skip_env
    )
)

:create_env
echo Creating configuration file...
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
    echo # Authentication Configuration - CHANGE THESE IN PRODUCTION!
    echo ARUBA_AUTH_TOKENS=admin-windows-%RANDOM%,secure-token-%RANDOM%,aruba-iot,production-key-%RANDOM%
    echo.
    echo # Logging Configuration
    echo LOG_LEVEL=INFO
) > .env

if exist .env (
    echo %GREEN%✅ Configuration file created successfully%RESET%
    set "CONFIG_OK=1"
) else (
    echo %RED%❌ Failed to create configuration file%RESET%
    set "SETUP_ERROR=1"
)

:skip_env

echo.
echo %BLUE%Step 5: Configuring Windows Firewall...%RESET%
echo ============================================

REM Check if running as administrator
net session >nul 2>&1
if errorlevel 1 (
    echo %YELLOW%⚠️  Administrator privileges required for firewall configuration%RESET%
    echo.
    echo %YELLOW%Attempting to restart with administrator privileges...%RESET%
    echo If UAC prompt appears, please click "Yes"
    
    REM Create a temporary script to continue setup with admin privileges
    (
        echo @echo off
        echo cd /d "%CD%"
        echo call .venv\Scripts\activate.bat
        echo echo.
        echo echo %BLUE%Continuing firewall configuration...%RESET%
        echo netsh advfirewall firewall delete rule name="Aruba IoT Web Dashboard" ^>nul 2^>^&1
        echo netsh advfirewall firewall delete rule name="Aruba IoT WebSocket Server" ^>nul 2^>^&1
        echo netsh advfirewall firewall add rule name="Aruba IoT Web Dashboard" dir=in action=allow protocol=TCP localport=9090 profile=any
        echo if errorlevel 1 ^(
        echo     echo %RED%❌ Failed to add firewall rule for port 9090%RESET%
        echo ^) else ^(
        echo     echo %GREEN%✅ Added firewall rule for port 9090%RESET%
        echo ^)
        echo netsh advfirewall firewall add rule name="Aruba IoT WebSocket Server" dir=in action=allow protocol=TCP localport=9191 profile=any
        echo if errorlevel 1 ^(
        echo     echo %RED%❌ Failed to add firewall rule for port 9191%RESET%
        echo ^) else ^(
        echo     echo %GREEN%✅ Added firewall rule for port 9191%RESET%
        echo ^)
        echo echo.
        echo echo %GREEN%Firewall configuration completed%RESET%
        echo echo Press any key to continue...
        echo pause ^>nul
        echo del "%%~f0"
    ) > temp_firewall_setup.bat
    
    powershell -Command "Start-Process 'temp_firewall_setup.bat' -Verb RunAs -Wait" 2>nul
    if errorlevel 1 (
        echo %YELLOW%⚠️  Could not configure firewall automatically%RESET%
        echo You can configure it manually later using: configure_firewall.bat
        set "FIREWALL_OK=0"
    ) else (
        echo %GREEN%✅ Firewall configured successfully%RESET%
        set "FIREWALL_OK=1"
    )
) else (
    echo %GREEN%✅ Administrator privileges detected%RESET%
    echo Adding firewall rules...
    
    netsh advfirewall firewall delete rule name="Aruba IoT Web Dashboard" >nul 2>&1
    netsh advfirewall firewall delete rule name="Aruba IoT WebSocket Server" >nul 2>&1
    
    netsh advfirewall firewall add rule name="Aruba IoT Web Dashboard" dir=in action=allow protocol=TCP localport=9090 profile=any >nul 2>&1
    if errorlevel 1 (
        echo %RED%❌ Failed to add firewall rule for port 9090%RESET%
    ) else (
        echo %GREEN%✅ Added firewall rule for port 9090%RESET%
    )
    
    netsh advfirewall firewall add rule name="Aruba IoT WebSocket Server" dir=in action=allow protocol=TCP localport=9191 profile=any >nul 2>&1
    if errorlevel 1 (
        echo %RED%❌ Failed to add firewall rule for port 9191%RESET%
    ) else (
        echo %GREEN%✅ Added firewall rule for port 9191%RESET%
        set "FIREWALL_OK=1"
    )
)

echo.
echo %BLUE%Step 6: Testing installation...%RESET%
echo ===============================

echo Testing Python package imports...
python -c "import flask, flask_socketio, websockets, dotenv; print('All packages imported successfully')" 2>nul
if errorlevel 1 (
    echo %RED%❌ Package import test failed%RESET%
    set "SETUP_ERROR=1"
) else (
    echo %GREEN%✅ Package import test passed%RESET%
)

echo Testing app.py syntax...
python -m py_compile app.py >nul 2>&1
if errorlevel 1 (
    echo %RED%❌ app.py syntax check failed%RESET%
    set "SETUP_ERROR=1"
) else (
    echo %GREEN%✅ app.py syntax check passed%RESET%
)

if !SETUP_ERROR!==1 goto :error_summary

echo.
echo %GREEN%🎉 Installation completed successfully!%RESET%
echo =====================================

REM Display network information
echo.
echo %BLUE%Network Information:%RESET%
echo ===================
echo Your server will be accessible at:
echo 📍 Web Dashboard: http://localhost:9090
echo 📍 WebSocket: ws://localhost:9191/aruba?token=YOUR_TOKEN
echo.
echo Your IP addresses for external access:
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr "IPv4" ^| findstr /v "127.0.0.1"') do (
    set "ip=%%a"
    set "ip=!ip: =!"
    echo 📍 Web Dashboard: http://!ip!:9090
    echo 📍 WebSocket: ws://!ip!:9191/aruba?token=YOUR_TOKEN
)

echo.
echo %BLUE%Authentication Tokens:%RESET%
echo ====================
echo Your authentication tokens are in the .env file:
type .env | findstr "ARUBA_AUTH_TOKENS"

echo.
echo %BLUE%Quick Start:%RESET%
echo ===========
echo To start the server now:
echo 1. Keep this window open
echo 2. Press any key to start the server
echo 3. Or close this window and run: start_windows.bat
echo.
echo %YELLOW%Press any key to start the server, or Ctrl+C to exit...%RESET%
pause >nul

echo.
echo %GREEN%🚀 Starting Aruba IoT Telemetry Server...%RESET%
echo =============================================
echo.
echo %YELLOW%⚠️  Press Ctrl+C to stop the server%RESET%
echo.

REM Start the application
python app.py

goto :end

:error_summary
echo.
echo %RED%❌ Setup encountered errors!%RESET%
echo ============================
echo.
echo Setup Status:
if !PYTHON_OK!==1 (echo %GREEN%✅ Python%RESET%) else (echo %RED%❌ Python%RESET%)
if !VENV_OK!==1 (echo %GREEN%✅ Virtual Environment%RESET%) else (echo %RED%❌ Virtual Environment%RESET%)
if !DEPS_OK!==1 (echo %GREEN%✅ Dependencies%RESET%) else (echo %RED%❌ Dependencies%RESET%)
if !CONFIG_OK!==1 (echo %GREEN%✅ Configuration%RESET%) else (echo %RED%❌ Configuration%RESET%)
if !FIREWALL_OK!==1 (echo %GREEN%✅ Firewall%RESET%) else (echo %YELLOW%⚠️  Firewall%RESET%)
echo.
echo %YELLOW%Troubleshooting:%RESET%
echo ===============
echo 1. Run: troubleshoot_windows.bat
echo 2. Check: DEPLOYMENT_GUIDE.md
echo 3. Visit: https://github.com/kzmp/iot-aruba-telemetry

:end
echo.
echo %BLUE%Setup script completed%RESET%
pause
ENDLOCAL
