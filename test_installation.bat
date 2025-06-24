@echo off
REM Test Aruba IoT Telemetry Server Installation

echo 🧪 Testing Aruba IoT Telemetry Server Installation
echo ===============================================
echo.

REM Activate virtual environment
if exist .venv\Scripts\activate.bat (
    echo 🔧 Activating virtual environment...
    call .venv\Scripts\activate.bat
) else (
    echo ❌ Virtual environment not found!
    echo Please run setup_windows.bat first
    pause
    exit /b 1
)

REM Test basic import
echo 📦 Testing Python imports...
python -c "
try:
    import flask
    import flask_socketio
    import websockets
    import dotenv
    print('✅ All required packages imported successfully')
except ImportError as e:
    print('❌ Import error:', e)
    exit(1)
"

if errorlevel 1 (
    echo ❌ Package import failed
    echo Please run setup_windows.bat again
    pause
    exit /b 1
)

REM Test configuration file
if exist .env (
    echo ✅ Configuration file (.env) found
) else (
    echo ❌ Configuration file not found
    echo Please run setup_windows.bat first
    pause
    exit /b 1
)

REM Quick syntax check of app.py
echo 🔍 Testing app.py syntax...
python -m py_compile app.py >nul 2>&1
if errorlevel 1 (
    echo ❌ Syntax error in app.py
    echo Please check the file or re-clone the repository
    pause
    exit /b 1
) else (
    echo ✅ app.py syntax is valid
)

echo.
echo 🎉 Installation test completed successfully!
echo.
echo You can now run: start_windows.bat
echo.
pause
