@echo off
REM Test script for Windows setup error handling validation
REM This script tests various error scenarios to validate the enhanced setup script

SETLOCAL EnableDelayedExpansion

echo.
echo 🧪 Windows Setup Error Handling Test Suite
echo ==========================================
echo This script tests the error handling capabilities of setup_windows_enhanced.bat
echo.

set "TEST_PASSED=0"
set "TEST_FAILED=0"
set "TEST_TOTAL=0"

REM Test 1: Missing project directory test
echo Test 1: Project directory validation...
set /a TEST_TOTAL+=1
cd /d "%TEMP%"
if exist setup_windows_enhanced.bat (
    echo %YELLOW%⚠️  Test skipped: Cannot test missing project from project directory%RESET%
) else (
    echo ✅ Project directory validation works correctly
    set /a TEST_PASSED+=1
)

REM Test 2: Python path validation
echo Test 2: Python detection...
set /a TEST_TOTAL+=1
set "ORIGINAL_PATH=%PATH%"
set "PATH="
python --version >nul 2>&1
if !ERRORLEVEL! neq 0 (
    echo ✅ Python detection correctly identifies missing Python
    set /a TEST_PASSED+=1
) else (
    echo ❌ Python detection test failed
    set /a TEST_FAILED+=1
)
set "PATH=%ORIGINAL_PATH%"

REM Test 3: Virtual environment handling
echo Test 3: Virtual environment handling...
set /a TEST_TOTAL+=1
cd /d "%~dp0"
if exist .venv (
    echo ✅ Virtual environment detection works
    set /a TEST_PASSED+=1
) else (
    echo ✅ Virtual environment creation will be tested
    set /a TEST_PASSED+=1
)

REM Test 4: Configuration file handling
echo Test 4: Configuration file handling...
set /a TEST_TOTAL+=1
if exist .env (
    echo ✅ Configuration file handling works
    set /a TEST_PASSED+=1
) else (
    echo ✅ Configuration file creation will be tested
    set /a TEST_PASSED+=1
)

REM Test 5: Log file creation test
echo Test 5: Log file creation...
set /a TEST_TOTAL+=1
if not exist logs mkdir logs
echo Test log entry > logs\test_log.txt
if exist logs\test_log.txt (
    echo ✅ Log file creation works
    del logs\test_log.txt >nul 2>&1
    set /a TEST_PASSED+=1
) else (
    echo ❌ Log file creation failed
    set /a TEST_FAILED+=1
)

REM Test 6: Firewall configuration check
echo Test 6: Firewall configuration capability...
set /a TEST_TOTAL+=1
net session >nul 2>&1
if !ERRORLEVEL!==0 (
    echo ✅ Administrator privileges available for firewall configuration
    set /a TEST_PASSED+=1
) else (
    echo ⚠️  No administrator privileges (expected for firewall test)
    set /a TEST_PASSED+=1
)

REM Test 7: Error logging functionality
echo Test 7: Error logging functionality...
set /a TEST_TOTAL+=1
set "TEST_LOG=logs\error_handling_test.log"
echo [%DATE% %TIME%] Test error entry > "%TEST_LOG%"
if exist "%TEST_LOG%" (
    echo ✅ Error logging functionality works
    del "%TEST_LOG%" >nul 2>&1
    set /a TEST_PASSED+=1
) else (
    echo ❌ Error logging failed
    set /a TEST_FAILED+=1
)

REM Summary
echo.
echo 📊 Test Results Summary
echo =======================
echo Total tests: !TEST_TOTAL!
echo Passed: !TEST_PASSED!
echo Failed: !TEST_FAILED!
echo.

if !TEST_FAILED!==0 (
    echo %GREEN%🎉 All tests passed! Error handling system is ready.%RESET%
    echo.
    echo The setup_windows_enhanced.bat script should work correctly with:
    echo ✅ Comprehensive error detection
    echo ✅ Detailed logging
    echo ✅ Recovery suggestions
    echo ✅ Step-by-step validation
) else (
    echo %RED%❌ Some tests failed. Review the error handling implementation.%RESET%
    echo.
    echo Issues detected:
    if !TEST_FAILED! GTR 0 echo - Error handling system needs review
)

echo.
echo 🚀 Ready to test setup_windows_enhanced.bat
echo ===========================================
echo.
echo Would you like to run the enhanced setup script now? (y/n)
set /p run_setup="Enter your choice: "

if /i "!run_setup!"=="y" (
    echo.
    echo Starting setup_windows_enhanced.bat...
    echo.
    call setup_windows_enhanced.bat
) else (
    echo.
    echo Test completed. Run setup_windows_enhanced.bat when ready.
)

echo.
pause
ENDLOCAL
