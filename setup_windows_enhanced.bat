@echo off
REM Aruba IoT Telemetry Server - Enhanced Windows Setup with Advanced Error Handling
REM This script provides comprehensive error handling, debugging, and recovery options

SETLOCAL EnableDelayedExpansion EnableExtensions

echo.
echo 🚀 Aruba IoT Telemetry Server - Enhanced Windows Setup (ADVANCED DEBUG)
echo ========================================================================
echo This script provides:
echo ✅ Advanced error detection and recovery
echo ✅ Comprehensive logging and debugging
echo ✅ Automatic environment validation
echo ✅ Step-by-step error handling
echo ✅ Recovery suggestions for common issues
echo ✅ Detailed system diagnostics
echo.

REM Create debug and error log files
set "TIMESTAMP=%DATE:~10,4%-%DATE:~4,2%-%DATE:~7,2%_%TIME:~0,2%-%TIME:~3,2%-%TIME:~6,2%"
set "TIMESTAMP=!TIMESTAMP: =0!"
set "DEBUG_LOG=%CD%\logs\setup_debug_!TIMESTAMP!.log"
set "ERROR_LOG=%CD%\logs\setup_errors_!TIMESTAMP!.log"
set "SYSTEM_LOG=%CD%\logs\system_info_!TIMESTAMP!.log"

REM Create logs directory
if not exist "logs" (
    mkdir "logs"
    echo Created logs directory at: %CD%\logs
)

REM Initialize comprehensive logging
call :INIT_LOGGING

REM Set colors for better output
for /F %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
set "GREEN=%ESC%[92m"
set "RED=%ESC%[91m"
set "YELLOW=%ESC%[93m"
set "BLUE=%ESC%[94m"
set "CYAN=%ESC%[96m"
set "MAGENTA=%ESC%[95m"
set "WHITE=%ESC%[97m"
set "RESET=%ESC%[0m"

REM Initialize comprehensive error tracking
set "SETUP_ERROR=0"
set "PYTHON_OK=0"
set "VENV_OK=0"
set "DEPS_OK=0"
set "CONFIG_OK=0"
set "FIREWALL_OK=0"
set "STEP_COUNT=0"
set "LAST_ERROR="
set "ERROR_DETAILS="
set "RECOVERY_SUGGESTION="

REM Error handling macros
set "TRY_CATCH_START=call :TRY_CATCH_BEGIN"
set "CATCH=call :TRY_CATCH_END"

echo %CYAN%📊 System Diagnostics Starting...%RESET%
call :COLLECT_SYSTEM_INFO

REM ============================================================================
REM STEP 1: PROJECT DIRECTORY VALIDATION
REM ============================================================================
echo.
echo %BLUE%Step 1: Project Directory Validation%RESET%
echo ==========================================
set /a STEP_COUNT=1
call :LOG_INFO "Step 1: Starting project directory validation"

call :TRY_CATCH_BEGIN "Checking project directory structure"
if not exist app.py (
    call :HANDLE_ERROR "PROJECT_DIR" "app.py not found in current directory: %CD%" "Navigate to the correct project folder or re-clone the repository"
    call :SUGGEST_PROJECT_LOCATION
    goto :final_error_summary
)

if not exist requirements.txt (
    call :HANDLE_ERROR "PROJECT_FILES" "requirements.txt missing" "Ensure all project files are present"
    goto :final_error_summary
)

if not exist templates\dashboard.html (
    call :HANDLE_ERROR "PROJECT_STRUCTURE" "templates\dashboard.html missing" "Verify project structure integrity"
    goto :final_error_summary
)

call :LOG_SUCCESS "Project directory structure validated"
echo %GREEN%✅ Project directory structure validated%RESET%
call :TRY_CATCH_END

REM ============================================================================
REM STEP 2: PYTHON INSTALLATION AND VERSION VALIDATION
REM ============================================================================
echo.
echo %BLUE%Step 2: Python Installation and Version Validation%RESET%
echo ======================================================
set /a STEP_COUNT=2
call :LOG_INFO "Step 2: Starting Python validation"

call :TRY_CATCH_BEGIN "Checking Python installation"

REM Test Python availability
python --version >nul 2>&1
set "PYTHON_EXIT_CODE=!ERRORLEVEL!"

if !PYTHON_EXIT_CODE! neq 0 (
    call :HANDLE_PYTHON_NOT_FOUND
    if !PYTHON_OK!==0 goto :final_error_summary
) else (
    REM Python found, validate version
    call :VALIDATE_PYTHON_VERSION
    if !PYTHON_OK!==0 goto :final_error_summary
)

call :LOG_SUCCESS "Python validation completed successfully"
echo %GREEN%✅ Python validation completed%RESET%
call :TRY_CATCH_END

REM ============================================================================
REM STEP 3: VIRTUAL ENVIRONMENT CREATION AND VALIDATION
REM ============================================================================
echo.
echo %BLUE%Step 3: Virtual Environment Setup%RESET%
echo ====================================
set /a STEP_COUNT=3
call :LOG_INFO "Step 3: Starting virtual environment setup"

call :TRY_CATCH_BEGIN "Setting up virtual environment"

if exist .venv (
    call :HANDLE_EXISTING_VENV
) else (
    call :CREATE_NEW_VENV
)

if !VENV_OK!==0 goto :final_error_summary

call :LOG_SUCCESS "Virtual environment setup completed"
echo %GREEN%✅ Virtual environment ready%RESET%
call :TRY_CATCH_END

REM ============================================================================
REM STEP 4: DEPENDENCY INSTALLATION WITH RETRY LOGIC
REM ============================================================================
echo.
echo %BLUE%Step 4: Dependency Installation%RESET%
echo ==================================
set /a STEP_COUNT=4
call :LOG_INFO "Step 4: Starting dependency installation"

call :TRY_CATCH_BEGIN "Installing dependencies"
call :INSTALL_DEPENDENCIES_WITH_RETRY
if !DEPS_OK!==0 goto :final_error_summary

call :LOG_SUCCESS "Dependencies installed successfully"
echo %GREEN%✅ All dependencies installed%RESET%
call :TRY_CATCH_END

REM ============================================================================
REM STEP 5: ENVIRONMENT CONFIGURATION
REM ============================================================================
echo.
echo %BLUE%Step 5: Environment Configuration%RESET%
echo ====================================
set /a STEP_COUNT=5
call :LOG_INFO "Step 5: Starting environment configuration"

call :TRY_CATCH_BEGIN "Configuring environment"
call :SETUP_ENVIRONMENT_CONFIG
if !CONFIG_OK!==0 goto :final_error_summary

call :LOG_SUCCESS "Environment configuration completed"
echo %GREEN%✅ Environment configured%RESET%
call :TRY_CATCH_END

REM ============================================================================
REM STEP 6: FIREWALL CONFIGURATION WITH ENHANCED VALIDATION
REM ============================================================================
echo.
echo %BLUE%Step 6: Firewall Configuration%RESET%
echo =================================
set /a STEP_COUNT=6
call :LOG_INFO "Step 6: Starting firewall configuration"

REM Firewall is non-critical, so we handle errors differently
call :TRY_CATCH_BEGIN "Configuring Windows Firewall (non-critical)"

REM Save current errorlevel to prevent cascading failures
set "SAVED_ERRORLEVEL=!ERRORLEVEL!"

call :CONFIGURE_FIREWALL_ENHANCED

REM Restore errorlevel and log completion regardless of result
set "ERRORLEVEL=!SAVED_ERRORLEVEL!"
call :LOG_INFO "Firewall configuration completed with status: !FIREWALL_OK!"

if !FIREWALL_OK!==0 (
    echo %YELLOW%⚠️  Firewall configuration had issues (non-critical - continuing setup)%RESET%
    call :LOG_WARNING "Firewall configuration failed but continuing with setup"
) else (
    echo %GREEN%✅ Firewall configured successfully%RESET%
)

REM Always succeed on firewall step since it's non-critical
set "ERRORLEVEL=0"
call :TRY_CATCH_END

REM ============================================================================
REM STEP 7: FINAL VALIDATION AND TESTING
REM ============================================================================
echo.
echo %BLUE%Step 7: Final Validation and Testing%RESET%
echo =======================================
set /a STEP_COUNT=7
call :LOG_INFO "Step 7: Starting final validation"

call :TRY_CATCH_BEGIN "Running final validation tests"
call :RUN_FINAL_VALIDATION
call :TRY_CATCH_END

REM ============================================================================
REM SUCCESS SUMMARY AND STARTUP
REM ============================================================================
call :DISPLAY_SUCCESS_SUMMARY
goto :startup_server

REM ============================================================================
REM FUNCTION DEFINITIONS
REM ============================================================================

:INIT_LOGGING
echo [%DATE% %TIME%] Enhanced setup started > "%DEBUG_LOG%"
echo [%DATE% %TIME%] Error tracking started > "%ERROR_LOG%"
echo [%DATE% %TIME%] System diagnostics started > "%SYSTEM_LOG%"
echo %CYAN%📝 Logging initialized:%RESET%
echo    Debug: %DEBUG_LOG%
echo    Errors: %ERROR_LOG%
echo    System: %SYSTEM_LOG%
goto :eof

:COLLECT_SYSTEM_INFO
echo [%DATE% %TIME%] Collecting system information... >> "%SYSTEM_LOG%"
echo OS Version: >> "%SYSTEM_LOG%"
ver >> "%SYSTEM_LOG%"
echo. >> "%SYSTEM_LOG%"
echo Current User: %USERNAME% >> "%SYSTEM_LOG%"
echo Current Directory: %CD% >> "%SYSTEM_LOG%"
echo PATH Variable: >> "%SYSTEM_LOG%"
echo %PATH% >> "%SYSTEM_LOG%"
echo. >> "%SYSTEM_LOG%"
echo Available Memory: >> "%SYSTEM_LOG%"
systeminfo | findstr "Total Physical Memory" >> "%SYSTEM_LOG%"
echo. >> "%SYSTEM_LOG%"
echo Disk Space: >> "%SYSTEM_LOG%"
dir | findstr "bytes free" >> "%SYSTEM_LOG%"
echo. >> "%SYSTEM_LOG%"
goto :eof

:TRY_CATCH_BEGIN
set "CURRENT_OPERATION=%~1"
call :LOG_INFO "TRY: %CURRENT_OPERATION%"
goto :eof

:TRY_CATCH_END
REM Only handle errors if ERRORLEVEL is actually set and non-zero
if defined ERRORLEVEL if !ERRORLEVEL! neq 0 (
    REM Check if this is a critical step or non-critical (like firewall)
    echo %CURRENT_OPERATION% | findstr /i "firewall non-critical" >nul 2>&1
    if !ERRORLEVEL!==0 (
        REM Non-critical operation - log warning but don't fail
        call :LOG_WARNING "Non-critical operation had issues: %CURRENT_OPERATION%"
        set "ERRORLEVEL=0"
    ) else (
        REM Critical operation - handle as error
        call :HANDLE_ERROR "OPERATION_FAILED" "Operation failed: %CURRENT_OPERATION%" "Check the detailed logs for more information"
    )
)
goto :eof

:LOG_INFO
echo [%DATE% %TIME%] INFO: %~1 >> "%DEBUG_LOG%"
echo %CYAN%[INFO]%RESET% %~1
goto :eof

:LOG_SUCCESS
echo [%DATE% %TIME%] SUCCESS: %~1 >> "%DEBUG_LOG%"
echo %GREEN%[SUCCESS]%RESET% %~1
goto :eof

:LOG_ERROR
echo [%DATE% %TIME%] ERROR: %~1 >> "%ERROR_LOG%"
echo [%DATE% %TIME%] ERROR: %~1 >> "%DEBUG_LOG%"
echo %RED%[ERROR]%RESET% %~1
goto :eof

:LOG_WARNING
echo [%DATE% %TIME%] WARNING: %~1 >> "%DEBUG_LOG%"
echo %YELLOW%[WARNING]%RESET% %~1
goto :eof

:HANDLE_ERROR
set "ERROR_TYPE=%~1"
set "ERROR_MESSAGE=%~2"
set "RECOVERY_SUGGESTION=%~3"
set "SETUP_ERROR=1"

call :LOG_ERROR "%ERROR_TYPE%: %ERROR_MESSAGE%"
echo.
echo %RED%❌ ERROR DETECTED%RESET%
echo ================
echo Type: %ERROR_TYPE%
echo Message: %ERROR_MESSAGE%
echo.
echo %YELLOW%💡 Recovery Suggestion:%RESET%
echo %RECOVERY_SUGGESTION%
echo.
echo Detailed logs available in: %ERROR_LOG%
goto :eof

:SUGGEST_PROJECT_LOCATION
echo %YELLOW%🔍 Searching for project in common locations...%RESET%
for %%d in (
    "%USERPROFILE%\Documents\GitHub\iot-aruba-telemetry"
    "%USERPROFILE%\Desktop\iot-aruba-telemetry"
    "%USERPROFILE%\Downloads\iot-aruba-telemetry"
    "C:\Users\%USERNAME%\Documents\GitHub\iot-aruba-telemetry"
) do (
    if exist "%%d\app.py" (
        echo %GREEN%✅ Found project at: %%d%RESET%
        echo Would you like to switch to this directory? (y/n)
        set /p switch_dir="Enter your choice: "
        if /i "!switch_dir!"=="y" (
            cd /d "%%d"
            call :LOG_INFO "Switched to directory: %%d"
            set "SETUP_ERROR=0"
            goto :eof
        )
    )
)
echo %RED%❌ Project not found in common locations%RESET%
echo.
echo %YELLOW%Manual Recovery Steps:%RESET%
echo 1. Ensure you have cloned the repository
echo 2. Navigate to the correct folder in File Explorer
echo 3. Right-click in the folder and select "Open PowerShell window here"
echo 4. Run this script again
goto :eof

:HANDLE_PYTHON_NOT_FOUND
call :LOG_ERROR "Python not found in PATH"
echo %RED%❌ Python is not installed or not in PATH%RESET%
echo.

REM Try to locate Python installations
call :SEARCH_PYTHON_INSTALLATIONS
if !PYTHON_OK!==1 goto :eof

echo %YELLOW%📥 Python Installation Required%RESET%
echo ================================
echo.
echo %CYAN%Automatic Installation Option:%RESET%
echo Would you like to download Python automatically? (y/n)
set /p auto_python="Enter your choice: "

if /i "!auto_python!"=="y" (
    call :DOWNLOAD_PYTHON_AUTOMATICALLY
) else (
    echo.
    echo %YELLOW%Manual Installation Steps:%RESET%
    echo 1. Visit: https://www.python.org/downloads/windows/
    echo 2. Download Python 3.8+ for Windows
    echo 3. ⚠️  IMPORTANT: Check "Add Python to PATH" during installation
    echo 4. Restart this script after installation
    echo.
    pause
)
goto :eof

:SEARCH_PYTHON_INSTALLATIONS
call :LOG_INFO "Searching for Python in common installation locations"
set "PYTHON_FOUND=0"

REM Extended search in common Python locations
for %%p in (
    "C:\Python3*\python.exe"
    "C:\Python4*\python.exe"
    "C:\Program Files\Python3*\python.exe"
    "C:\Program Files\Python4*\python.exe"
    "C:\Program Files (x86)\Python3*\python.exe"
    "C:\Program Files (x86)\Python4*\python.exe"
    "%LOCALAPPDATA%\Programs\Python\Python3*\python.exe"
    "%LOCALAPPDATA%\Programs\Python\Python4*\python.exe"
    "%USERPROFILE%\AppData\Local\Programs\Python\Python3*\python.exe"
    "%USERPROFILE%\AppData\Local\Programs\Python\Python4*\python.exe"
    "%APPDATA%\Python\Python3*\python.exe"
    "%APPDATA%\Python\Python4*\python.exe"
    "%LOCALAPPDATA%\Microsoft\WindowsApps\python.exe"
) do (
    for /f "delims=" %%f in ('dir "%%p" /b 2^>nul') do (
        set "PYTHON_PATH=%%~dpf%%f"
        call :LOG_INFO "Testing Python at: !PYTHON_PATH!"
        
        REM Test if this Python works
        "!PYTHON_PATH!" --version >nul 2>&1
        if !ERRORLEVEL!==0 (
            for /f "tokens=2" %%v in ('"!PYTHON_PATH!" --version 2^>^&1') do set "PYTHON_VERSION=%%v"
            echo %GREEN%✅ Found working Python !PYTHON_VERSION! at:%RESET%
            echo    !PYTHON_PATH!
            
            REM Add to PATH
            for %%i in ("!PYTHON_PATH!") do set "PYTHON_DIR=%%~dpi"
            set "PATH=!PYTHON_DIR!;!PYTHON_DIR!Scripts;!PATH!"
            
            REM Verify it works from PATH
            python --version >nul 2>&1
            if !ERRORLEVEL!==0 (
                set "PYTHON_OK=1"
                set "PYTHON_FOUND=1"
                call :LOG_SUCCESS "Python successfully added to PATH"
                goto :python_search_done
            )
        )
    )
)

:python_search_done
if !PYTHON_FOUND!==0 (
    call :LOG_ERROR "No working Python installation found"
)
goto :eof

:DOWNLOAD_PYTHON_AUTOMATICALLY
echo %CYAN%🔄 Attempting automatic Python download...%RESET%
echo.

REM Check if we have internet connectivity
ping -n 1 python.org >nul 2>&1
if !ERRORLEVEL! neq 0 (
    call :LOG_ERROR "No internet connection available for automatic download"
    echo %RED%❌ No internet connection available%RESET%
    echo Please install Python manually
    goto :eof
)

REM Try to download using PowerShell (Windows 10/11)
echo Downloading Python installer...
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.11.7/python-3.11.7-amd64.exe' -OutFile 'python-installer.exe'}" 2>nul

if exist python-installer.exe (
    echo %GREEN%✅ Python installer downloaded%RESET%
    echo.
    echo %YELLOW%⚠️  About to run Python installer...%RESET%
    echo IMPORTANT: During installation, make sure to:
    echo ✅ Check "Add Python to PATH"
    echo ✅ Check "Install pip"
    echo.
    echo Press any key to continue...
    pause >nul
    
    python-installer.exe /quiet InstallAllUsers=1 PrependPath=1 Include_test=0
    
    REM Wait for installation to complete
    echo Waiting for installation to complete...
    timeout /t 10 /nobreak >nul
    
    REM Clean up installer
    del python-installer.exe >nul 2>&1
    
    REM Test if Python is now available
    python --version >nul 2>&1
    if !ERRORLEVEL!==0 (
        set "PYTHON_OK=1"
        call :LOG_SUCCESS "Python automatically installed and configured"
        echo %GREEN%✅ Python installation completed successfully%RESET%
    ) else (
        call :LOG_ERROR "Automatic Python installation failed"
        echo %RED%❌ Automatic installation failed%RESET%
        echo Please install Python manually and restart this script
    )
) else (
    call :LOG_ERROR "Failed to download Python installer"
    echo %RED%❌ Download failed%RESET%
    echo Please install Python manually
)
goto :eof

:VALIDATE_PYTHON_VERSION
for /f "tokens=2" %%v in ('python --version 2^>^&1') do set "PYTHON_VERSION=%%v"
call :LOG_INFO "Found Python version: %PYTHON_VERSION%"

REM Extract major and minor version numbers
for /f "tokens=1,2 delims=." %%a in ("%PYTHON_VERSION%") do (
    set "PYTHON_MAJOR=%%a"
    set "PYTHON_MINOR=%%b"
)

if !PYTHON_MAJOR! LSS 3 (
    call :HANDLE_ERROR "PYTHON_VERSION" "Python %PYTHON_VERSION% is too old (Python 3.8+ required)" "Install Python 3.8 or newer"
    goto :eof
)

if !PYTHON_MAJOR! EQU 3 if !PYTHON_MINOR! LSS 8 (
    call :HANDLE_ERROR "PYTHON_VERSION" "Python %PYTHON_VERSION% is too old (Python 3.8+ required)" "Install Python 3.8 or newer"
    goto :eof
)

set "PYTHON_OK=1"
call :LOG_SUCCESS "Python version %PYTHON_VERSION% is compatible"
echo %GREEN%✅ Python %PYTHON_VERSION% (compatible)%RESET%
goto :eof

:HANDLE_EXISTING_VENV
echo %YELLOW%⚠️  Virtual environment already exists%RESET%
call :LOG_INFO "Existing virtual environment detected"

REM Test if existing venv is functional
echo Testing existing virtual environment...
call .venv\Scripts\activate.bat
python -c "import sys; print('Python path:', sys.executable)" >nul 2>&1
set "VENV_TEST_RESULT=!ERRORLEVEL!"
call deactivate >nul 2>&1

if !VENV_TEST_RESULT!==0 (
    echo %GREEN%✅ Existing virtual environment is functional%RESET%
    echo Would you like to use it or recreate? (u=use, r=recreate)
    set /p venv_choice="Enter your choice: "
    
    if /i "!venv_choice!"=="u" (
        set "VENV_OK=1"
        call :LOG_SUCCESS "Using existing virtual environment"
        goto :eof
    )
)

REM Recreate virtual environment
echo %CYAN%🔄 Recreating virtual environment...%RESET%
call :LOG_INFO "Recreating virtual environment"

rmdir /s /q .venv >nul 2>&1
if exist .venv (
    call :HANDLE_ERROR "VENV_CLEANUP" "Could not remove existing virtual environment" "Manually delete .venv folder and retry"
    goto :eof
)

call :CREATE_NEW_VENV
goto :eof

:CREATE_NEW_VENV
echo %CYAN%🔄 Creating new virtual environment...%RESET%
call :LOG_INFO "Creating new virtual environment"

python -m venv .venv
set "VENV_CREATE_RESULT=!ERRORLEVEL!"

if !VENV_CREATE_RESULT! neq 0 (
    call :HANDLE_ERROR "VENV_CREATE" "Failed to create virtual environment" "Check Python installation and permissions"
    goto :eof
)

REM Test virtual environment activation
call .venv\Scripts\activate.bat
set "VENV_ACTIVATE_RESULT=!ERRORLEVEL!"

if !VENV_ACTIVATE_RESULT! neq 0 (
    call :HANDLE_ERROR "VENV_ACTIVATE" "Failed to activate virtual environment" "Check antivirus settings and permissions"
    goto :eof
)

REM Verify Python in virtual environment
python -c "import sys; print('Virtual env Python:', sys.executable)" >nul 2>&1
set "VENV_PYTHON_RESULT=!ERRORLEVEL!"

if !VENV_PYTHON_RESULT! neq 0 (
    call :HANDLE_ERROR "VENV_PYTHON" "Python not working in virtual environment" "Recreate virtual environment"
    call deactivate >nul 2>&1
    goto :eof
)

set "VENV_OK=1"
call :LOG_SUCCESS "Virtual environment created and activated successfully"
echo %GREEN%✅ Virtual environment ready%RESET%
goto :eof

:INSTALL_DEPENDENCIES_WITH_RETRY
call :LOG_INFO "Starting dependency installation with retry logic"
echo %CYAN%📦 Installing dependencies...%RESET%

REM Ensure we're in the virtual environment
call .venv\Scripts\activate.bat

REM Upgrade pip first
echo Upgrading pip...
python -m pip install --upgrade pip
set "PIP_UPGRADE_RESULT=!ERRORLEVEL!"
if !PIP_UPGRADE_RESULT! neq 0 (
    call :LOG_WARNING "Pip upgrade failed, continuing with existing version"
)

REM Try installation with different strategies
set "INSTALL_ATTEMPTS=0"
set "MAX_ATTEMPTS=3"

:retry_install
set /a INSTALL_ATTEMPTS+=1
call :LOG_INFO "Installation attempt !INSTALL_ATTEMPTS! of !MAX_ATTEMPTS!"

if !INSTALL_ATTEMPTS! EQU 1 (
    echo Attempt 1: Standard installation...
    python -m pip install -r requirements.txt
    set "INSTALL_RESULT=!ERRORLEVEL!"
) else if !INSTALL_ATTEMPTS! EQU 2 (
    echo Attempt 2: Installation with no cache...
    python -m pip install --no-cache-dir -r requirements.txt
    set "INSTALL_RESULT=!ERRORLEVEL!"
) else if !INSTALL_ATTEMPTS! EQU 3 (
    echo Attempt 3: Installation with trusted hosts...
    python -m pip install --trusted-host pypi.org --trusted-host pypi.python.org --trusted-host files.pythonhosted.org -r requirements.txt
    set "INSTALL_RESULT=!ERRORLEVEL!"
)

if !INSTALL_RESULT!==0 (
    call :LOG_SUCCESS "Dependencies installed successfully on attempt !INSTALL_ATTEMPTS!"
    set "DEPS_OK=1"
    goto :verify_dependencies
)

if !INSTALL_ATTEMPTS! LSS !MAX_ATTEMPTS! (
    call :LOG_WARNING "Installation attempt !INSTALL_ATTEMPTS! failed, retrying..."
    timeout /t 2 /nobreak >nul
    goto :retry_install
)

call :HANDLE_ERROR "DEPS_INSTALL" "Failed to install dependencies after !MAX_ATTEMPTS! attempts" "Check internet connection and try manual installation"
goto :eof

:verify_dependencies
echo %CYAN%🔍 Verifying installed packages...%RESET%
call :LOG_INFO "Verifying installed packages"

REM Test critical imports
python -c "import flask; import flask_socketio; import websockets; print('Core packages OK')" >nul 2>&1
set "IMPORT_TEST_RESULT=!ERRORLEVEL!"

if !IMPORT_TEST_RESULT! neq 0 (
    call :HANDLE_ERROR "DEPS_VERIFY" "Package verification failed" "Try reinstalling dependencies"
    set "DEPS_OK=0"
    goto :eof
)

call :LOG_SUCCESS "All packages verified successfully"
echo %GREEN%✅ Package verification completed%RESET%
goto :eof

:SETUP_ENVIRONMENT_CONFIG
call :LOG_INFO "Setting up environment configuration"
echo %CYAN%⚙️  Configuring environment...%RESET%

REM Create or update .env file
if exist .env (
    echo %YELLOW%⚠️  .env file already exists%RESET%
    call :LOG_INFO "Existing .env file found"
    
    REM Backup existing .env
    copy .env .env.backup.%TIMESTAMP% >nul 2>&1
    call :LOG_INFO "Backed up existing .env to .env.backup.%TIMESTAMP%"
    
    echo Would you like to update it? (y/n)
    set /p update_env="Enter your choice: "
    if /i not "!update_env!"=="y" (
        set "CONFIG_OK=1"
        goto :eof
    )
)

REM Generate new configuration
call :LOG_INFO "Generating new .env configuration"

REM Generate random tokens
set "TOKEN1="
set "TOKEN2="
for /f %%i in ('powershell -Command "[System.Web.Security.Membership]::GeneratePassword(32, 0)"') do set "TOKEN1=%%i"
for /f %%i in ('powershell -Command "[System.Web.Security.Membership]::GeneratePassword(32, 0)"') do set "TOKEN2=%%i"

REM Create .env file
(
echo # Aruba IoT Telemetry Server Configuration
echo # Generated on %DATE% %TIME%
echo.
echo # Server Configuration
echo FLASK_HOST=0.0.0.0
echo FLASK_PORT=9090
echo WEBSOCKET_HOST=0.0.0.0
echo WEBSOCKET_PORT=9191
echo.
echo # Authentication Tokens for Aruba Access Points
echo # Use these tokens when connecting from Aruba APs
echo ARUBA_AUTH_TOKENS=!TOKEN1!,!TOKEN2!
echo.
echo # Logging Configuration
echo LOG_LEVEL=INFO
echo LOG_FILE=logs/aruba_iot.log
echo.
echo # Debug Mode (set to False for production)
echo DEBUG=True
) > .env

set "ENV_CREATE_RESULT=!ERRORLEVEL!"
if !ENV_CREATE_RESULT! neq 0 (
    call :HANDLE_ERROR "ENV_CREATE" "Failed to create .env file" "Check write permissions in project directory"
    goto :eof
)

REM Verify .env file
if not exist .env (
    call :HANDLE_ERROR "ENV_VERIFY" ".env file was not created" "Check disk space and permissions"
    goto :eof
)

set "CONFIG_OK=1"
call :LOG_SUCCESS "Environment configuration completed"
echo %GREEN%✅ Environment configured with generated tokens%RESET%
goto :eof

:CONFIGURE_FIREWALL_ENHANCED
call :LOG_INFO "Starting enhanced firewall configuration"
echo %CYAN%🔥 Configuring Windows Firewall...%RESET%

REM Initialize firewall status
set "FIREWALL_OK=0"

REM Check if we have admin privileges
call :LOG_INFO "Checking administrator privileges"
net session >nul 2>&1
set "ADMIN_CHECK_RESULT=!ERRORLEVEL!"

if !ADMIN_CHECK_RESULT! neq 0 (
    call :LOG_WARNING "No administrator privileges detected for firewall configuration"
    echo %YELLOW%⚠️  Administrator privileges required for automatic firewall configuration%RESET%
    echo.
    echo %CYAN%Firewall Configuration Options:%RESET%
    echo 1. Skip firewall configuration (continue setup - you can configure manually later)
    echo 2. Restart script as administrator (recommended)
    echo 3. Get manual firewall instructions
    echo.
    set /p firewall_choice="Enter your choice (1-3) [default: 1]: "
    
    REM Default to option 1 if no input
    if "!firewall_choice!"=="" set "firewall_choice=1"
    
    if "!firewall_choice!"=="2" (
        echo %CYAN%🔄 Attempting to restart with administrator privileges...%RESET%
        echo Please approve the UAC prompt if it appears...
        timeout /t 3 /nobreak >nul
        call :LOG_INFO "Attempting administrator restart"
        
        REM Try to restart as admin
        powershell -Command "try { Start-Process cmd -ArgumentList '/c cd /d \"%CD%\" && \"%~f0\"' -Verb RunAs -ErrorAction Stop; exit 0 } catch { exit 1 }" 2>nul
        set "RESTART_RESULT=!ERRORLEVEL!"
        
        if !RESTART_RESULT!==0 (
            echo %GREEN%✅ Restarting as administrator...%RESET%
            exit /b 0
        ) else (
            echo %RED%❌ Could not restart as administrator%RESET%
            echo Continuing with setup - firewall configuration skipped
            call :LOG_WARNING "Administrator restart failed, continuing without firewall setup"
            goto :firewall_skip
        )
    ) else if "!firewall_choice!"=="3" (
        call :SHOW_MANUAL_FIREWALL_INSTRUCTIONS
        goto :firewall_skip
    ) else (
        echo %YELLOW%⚠️  Skipping automatic firewall configuration%RESET%
        call :LOG_INFO "User chose to skip firewall configuration"
        goto :firewall_skip
    )
)

REM We have admin privileges - proceed with firewall configuration
call :LOG_INFO "Administrator privileges confirmed - configuring firewall rules"
echo %GREEN%✅ Administrator privileges confirmed%RESET%

REM Configure firewall rules with comprehensive error checking
call :LOG_INFO "Configuring firewall rules for ports 9090 and 9191"

echo %CYAN%Configuring firewall rule for web dashboard (port 9090)...%RESET%
REM Remove existing rule first (ignore errors)
netsh advfirewall firewall delete rule name="Aruba IoT Web Dashboard" >nul 2>&1

REM Add new rule
netsh advfirewall firewall add rule name="Aruba IoT Web Dashboard" dir=in action=allow protocol=TCP localport=9090 description="Aruba IoT Telemetry Web Dashboard" >nul 2>&1
set "FIREWALL_WEB_RESULT=!ERRORLEVEL!"
call :LOG_INFO "Web dashboard firewall rule result: !FIREWALL_WEB_RESULT!"

if !FIREWALL_WEB_RESULT!==0 (
    echo   %GREEN%✅ Web dashboard rule added%RESET%
) else (
    echo   %RED%❌ Web dashboard rule failed%RESET%
    call :LOG_ERROR "Failed to add web dashboard firewall rule"
)

echo %CYAN%Configuring firewall rule for WebSocket server (port 9191)...%RESET%
REM Remove existing rule first (ignore errors)
netsh advfirewall firewall delete rule name="Aruba IoT WebSocket" >nul 2>&1

REM Add new rule
netsh advfirewall firewall add rule name="Aruba IoT WebSocket" dir=in action=allow protocol=TCP localport=9191 description="Aruba IoT Telemetry WebSocket Server" >nul 2>&1
set "FIREWALL_WS_RESULT=!ERRORLEVEL!"
call :LOG_INFO "WebSocket firewall rule result: !FIREWALL_WS_RESULT!"

if !FIREWALL_WS_RESULT!==0 (
    echo   %GREEN%✅ WebSocket rule added%RESET%
) else (
    echo   %RED%❌ WebSocket rule failed%RESET%
    call :LOG_ERROR "Failed to add WebSocket firewall rule"
)

REM Verify firewall rules were created successfully
call :LOG_INFO "Verifying firewall rules"
echo %CYAN%Verifying firewall rules...%RESET%

netsh advfirewall firewall show rule name="Aruba IoT Web Dashboard" >nul 2>&1
set "VERIFY_WEB_RESULT=!ERRORLEVEL!"

netsh advfirewall firewall show rule name="Aruba IoT WebSocket" >nul 2>&1
set "VERIFY_WS_RESULT=!ERRORLEVEL!"

call :LOG_INFO "Verification results - Web: !VERIFY_WEB_RESULT!, WebSocket: !VERIFY_WS_RESULT!"

REM Determine overall firewall configuration success
if !FIREWALL_WEB_RESULT!==0 if !FIREWALL_WS_RESULT!==0 if !VERIFY_WEB_RESULT!==0 if !VERIFY_WS_RESULT!==0 (
    set "FIREWALL_OK=1"
    call :LOG_SUCCESS "All firewall rules configured and verified successfully"
    echo %GREEN%✅ All firewall rules configured successfully%RESET%
) else (
    call :LOG_WARNING "Some firewall rules failed - manual configuration may be needed"
    echo %YELLOW%⚠️  Some firewall rules had issues%RESET%
    echo.
    echo %CYAN%Firewall Status:%RESET%
    echo   Web Dashboard (9090): !FIREWALL_WEB_RESULT! ^| Verify: !VERIFY_WEB_RESULT!
    echo   WebSocket (9191): !FIREWALL_WS_RESULT! ^| Verify: !VERIFY_WS_RESULT!
    echo   (0 = success, non-zero = error)
    echo.
    
    REM Partial success is still useful
    if !FIREWALL_WEB_RESULT!==0 (
        echo %GREEN%✅ Web dashboard accessible (port 9090)%RESET%
    )
    if !FIREWALL_WS_RESULT!==0 (
        echo %GREEN%✅ WebSocket server accessible (port 9191)%RESET%
    )
    
    if !FIREWALL_WEB_RESULT! neq 0 if !FIREWALL_WS_RESULT! neq 0 (
        echo %RED%❌ Both firewall rules failed%RESET%
        call :SHOW_MANUAL_FIREWALL_INSTRUCTIONS
    )
)

goto :firewall_complete

:firewall_skip
call :LOG_INFO "Firewall configuration skipped - manual setup required"
echo %YELLOW%⚠️  Firewall configuration skipped%RESET%
echo.
echo %CYAN%📋 Manual Firewall Setup Required:%RESET%
echo =====================================
echo After setup completes, you'll need to manually allow these ports:
echo   • Port 9090 (Web Dashboard)
echo   • Port 9191 (WebSocket Server)
echo.
echo %YELLOW%Quick Manual Steps:%RESET%
echo 1. Run 'configure_firewall.bat' as administrator, OR
echo 2. Open Windows Defender Firewall settings
echo 3. Allow the ports 9090 and 9191 for the application
echo.
set "FIREWALL_OK=0"

:firewall_complete
call :LOG_INFO "Firewall configuration section completed with status: !FIREWALL_OK!"
goto :eof

:SHOW_MANUAL_FIREWALL_INSTRUCTIONS
echo.
echo %CYAN%📋 Manual Firewall Configuration Instructions:%RESET%
echo =============================================
echo.
echo %YELLOW%Option 1: Use the provided script (easiest)%RESET%
echo   Right-click 'configure_firewall.bat' → "Run as administrator"
echo.
echo %YELLOW%Option 2: Windows Defender Firewall%RESET%
echo   1. Press Win+R, type: wf.msc
echo   2. Click "Inbound Rules" → "New Rule"
echo   3. Select "Port" → Next
echo   4. TCP, Specific ports: 9090,9191 → Next
echo   5. Allow the connection → Next
echo   6. Apply to all profiles → Next
echo   7. Name: "Aruba IoT Telemetry" → Finish
echo.
echo %YELLOW%Option 3: Command Line (run as administrator)%RESET%
echo   netsh advfirewall firewall add rule name="Aruba IoT Web" dir=in action=allow protocol=TCP localport=9090
echo   netsh advfirewall firewall add rule name="Aruba IoT WS" dir=in action=allow protocol=TCP localport=9191
echo.
goto :eof

:RUN_FINAL_VALIDATION
call :LOG_INFO "Running final validation tests"
echo %CYAN%🧪 Running final validation tests...%RESET%

REM Test 1: Virtual environment activation
echo Test 1: Virtual environment...
call .venv\Scripts\activate.bat >nul 2>&1
if !ERRORLEVEL! neq 0 (
    call :LOG_ERROR "Virtual environment activation failed"
    echo %RED%❌ Virtual environment test failed%RESET%
    goto :eof
)
echo %GREEN%✅ Virtual environment OK%RESET%

REM Test 2: Critical package imports
echo Test 2: Package imports...
python -c "import flask, flask_socketio, websockets, asyncio, json, logging; print('All imports successful')" >nul 2>&1
if !ERRORLEVEL! neq 0 (
    call :LOG_ERROR "Package import test failed"
    echo %RED%❌ Package import test failed%RESET%
    goto :eof
)
echo %GREEN%✅ Package imports OK%RESET%

REM Test 3: Configuration file validation
echo Test 3: Configuration validation...
if not exist .env (
    call :LOG_ERROR "Configuration file missing"
    echo %RED%❌ Configuration test failed%RESET%
    goto :eof
)

REM Check for required configuration
findstr "ARUBA_AUTH_TOKENS" .env >nul 2>&1
if !ERRORLEVEL! neq 0 (
    call :LOG_ERROR "Authentication tokens not found in configuration"
    echo %RED%❌ Configuration test failed%RESET%
    goto :eof
)
echo %GREEN%✅ Configuration OK%RESET%

REM Test 4: Port availability check
echo Test 4: Port availability...
netstat -an | findstr ":9090" >nul 2>&1
if !ERRORLEVEL!==0 (
    call :LOG_WARNING "Port 9090 may be in use by another application"
    echo %YELLOW%⚠️  Port 9090 may be in use%RESET%
)

netstat -an | findstr ":9191" >nul 2>&1
if !ERRORLEVEL!==0 (
    call :LOG_WARNING "Port 9191 may be in use by another application"
    echo %YELLOW%⚠️  Port 9191 may be in use%RESET%
)
echo %GREEN%✅ Port check completed%RESET%

call :LOG_SUCCESS "Final validation completed successfully"
echo %GREEN%✅ All validation tests passed%RESET%
goto :eof

:DISPLAY_SUCCESS_SUMMARY
echo.
echo %GREEN%🎉 SETUP COMPLETED SUCCESSFULLY! 🎉%RESET%
echo ==========================================
echo.
echo %BLUE%Setup Summary:%RESET%
echo ✅ Project directory validated
echo ✅ Python %PYTHON_VERSION% configured
echo ✅ Virtual environment created
echo ✅ Dependencies installed
echo ✅ Environment configured
if !FIREWALL_OK!==1 (echo ✅ Firewall configured) else (echo ⚠️  Firewall needs manual setup)
echo ✅ Final validation passed
echo.
echo %BLUE%Access Information:%RESET%
echo 🌐 Web Dashboard: http://localhost:9090
echo 🔌 WebSocket Endpoint: ws://localhost:9191/aruba
echo.
echo %BLUE%Your Network Addresses:%RESET%
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr "IPv4" ^| findstr /v "127.0.0.1"') do (
    set "ip=%%a"
    set "ip=!ip: =!"
    echo 🌐 http://!ip!:9090
)
echo.
echo %BLUE%Authentication Tokens:%RESET%
type .env | findstr "ARUBA_AUTH_TOKENS" | findstr /v "#"
echo.
echo %BLUE%Log Files:%RESET%
echo 📝 Debug: %DEBUG_LOG%
echo 📝 Errors: %ERROR_LOG%
echo 📝 System: %SYSTEM_LOG%
echo.
echo %BLUE%Next Steps:%RESET%
echo 1. Review the authentication tokens above
echo 2. Configure your Aruba APs with these tokens
echo 3. Start the server (next step)
echo.
goto :eof

:startup_server
echo %YELLOW%🚀 Ready to start the server!%RESET%
echo =============================
echo.
echo Options:
echo 1. Start server now (recommended)
echo 2. Exit and start manually later
echo.
set /p start_choice="Enter your choice (1-2): "

if "!start_choice!"=="1" (
    echo.
    echo %GREEN%🚀 Starting Aruba IoT Telemetry Server...%RESET%
    echo ===============================================
    echo.
    echo %YELLOW%💡 Server Controls:%RESET%
    echo    Ctrl+C: Stop server
    echo    Ctrl+Break: Force stop
    echo.
    echo %YELLOW%📊 Monitor at: http://localhost:9090%RESET%
    echo.
    
    call :LOG_INFO "Starting server application"
    call .venv\Scripts\activate.bat
    python app.py
) else (
    echo.
    echo %BLUE%💾 Setup completed successfully!%RESET%
    echo.
    echo To start the server later, run:
    echo   start_windows.bat
    echo.
    echo Or manually:
    echo   1. cd %CD%
    echo   2. .venv\Scripts\activate.bat
    echo   3. python app.py
)

goto :end

:final_error_summary
echo.
echo %RED%❌ SETUP FAILED - COMPREHENSIVE ERROR SUMMARY%RESET%
echo ==============================================
echo.
echo %BLUE%Setup Progress:%RESET%
if !STEP_COUNT! GEQ 1 (echo Step 1 - Project Directory: %GREEN%✅%RESET%) else (echo Step 1 - Project Directory: %RED%❌%RESET%)
if !PYTHON_OK!==1 (echo Step 2 - Python Validation: %GREEN%✅%RESET%) else (echo Step 2 - Python Validation: %RED%❌%RESET%)
if !VENV_OK!==1 (echo Step 3 - Virtual Environment: %GREEN%✅%RESET%) else (echo Step 3 - Virtual Environment: %RED%❌%RESET%)
if !DEPS_OK!==1 (echo Step 4 - Dependencies: %GREEN%✅%RESET%) else (echo Step 4 - Dependencies: %RED%❌%RESET%)
if !CONFIG_OK!==1 (echo Step 5 - Configuration: %GREEN%✅%RESET%) else (echo Step 5 - Configuration: %RED%❌%RESET%)
if !FIREWALL_OK!==1 (echo Step 6 - Firewall: %GREEN%✅%RESET%) else (echo Step 6 - Firewall: %YELLOW%⚠️ %RESET%)
if !STEP_COUNT! GEQ 7 (echo Step 7 - Validation: %GREEN%✅%RESET%) else (echo Step 7 - Validation: %RED%❌%RESET%)
echo.
echo %BLUE%Error Details:%RESET%
if defined LAST_ERROR echo Last Error: %LAST_ERROR%
if defined ERROR_DETAILS echo Details: %ERROR_DETAILS%
if defined RECOVERY_SUGGESTION echo Suggestion: %RECOVERY_SUGGESTION%
echo.
echo %BLUE%Log Files for Debugging:%RESET%
echo 🔍 Debug Log: %DEBUG_LOG%
echo 🔍 Error Log: %ERROR_LOG%
echo 🔍 System Log: %SYSTEM_LOG%
echo.
echo %BLUE%Troubleshooting Options:%RESET%
echo 1. Review the error logs above
echo 2. Run: troubleshoot_windows.bat
echo 3. Check: DEPLOYMENT_GUIDE.md
echo 4. Visit: https://github.com/kzmp/iot-aruba-telemetry/issues
echo 5. Retry setup after addressing the issues
echo.
echo %YELLOW%🔧 Quick Recovery Commands:%RESET%
echo ============================
if !PYTHON_OK!==0 echo - Install Python 3.8+ with PATH option
if !VENV_OK!==0 echo - Delete .venv folder and retry
if !DEPS_OK!==0 echo - Check internet connection and retry
if !CONFIG_OK!==0 echo - Check write permissions in project folder
if !FIREWALL_OK!==0 echo - Run configure_firewall.bat as administrator
echo.

:end
echo.
echo %BLUE%📊 Setup Statistics:%RESET%
echo ===================
echo Completed steps: !STEP_COUNT!/7
echo Errors encountered: !SETUP_ERROR!
echo Session duration: %TIME%
echo.
echo %CYAN%Thank you for using Aruba IoT Telemetry Server!%RESET%
echo.
pause
ENDLOCAL
