@echo off
REM Test script specifically for verifying the enhanced firewall configuration process
REM This script tests the enhanced process-isolation approach for firewall configuration

SETLOCAL EnableDelayedExpansion

echo.
echo 🔥 Enhanced Firewall Configuration Test
echo ======================================
echo This script verifies the enhanced firewall configuration process
echo that avoids script hanging during setup.
echo.

REM Set up basic variables and colors
for /F %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
set "GREEN=%ESC%[92m"
set "RED=%ESC%[91m"
set "YELLOW=%ESC%[93m"
set "BLUE=%ESC%[94m"
set "CYAN=%ESC%[96m"
set "RESET=%ESC%[0m"

set "TEST_LOG=firewall_enhanced_test.log"
echo [%DATE% %TIME%] Enhanced firewall test started > "%TEST_LOG%"

echo %CYAN%Testing enhanced firewall configuration process...%RESET%
echo.

REM Step 1: Check Firewall Service
echo %BLUE%Step 1: Checking Windows Firewall service%RESET%
sc query MpsSvc >nul 2>&1
set "SERVICE_CHECK=!ERRORLEVEL!"

if !SERVICE_CHECK! neq 0 (
    echo %RED%❌ Cannot query firewall service - command failed%RESET%
    echo [%DATE% %TIME%] Firewall service query failed: !SERVICE_CHECK! >> "%TEST_LOG%"
    goto :skip_service_check
)

sc query MpsSvc | findstr /i "RUNNING" >nul 2>&1
set "SERVICE_RUNNING=!ERRORLEVEL!"

if !SERVICE_RUNNING! neq 0 (
    echo %YELLOW%⚠️  Windows Firewall service is not running%RESET%
    echo [%DATE% %TIME%] Firewall service not running >> "%TEST_LOG%"
) else (
    echo %GREEN%✅ Windows Firewall service is running%RESET%
    echo [%DATE% %TIME%] Firewall service is running >> "%TEST_LOG%"
)

:skip_service_check
echo.

REM Step 2: Check Admin Rights
echo %BLUE%Step 2: Checking administrator privileges%RESET%
net session >nul 2>&1
set "ADMIN_RIGHTS=!ERRORLEVEL!"

if !ADMIN_RIGHTS! neq 0 (
    echo %YELLOW%⚠️  No administrator privileges%RESET%
    echo [%DATE% %TIME%] No admin privileges >> "%TEST_LOG%"
) else (
    echo %GREEN%✅ Administrator privileges confirmed%RESET%
    echo [%DATE% %TIME%] Admin privileges confirmed >> "%TEST_LOG%"
)
echo.

REM Step 3: Create and execute temporary firewall script
echo %BLUE%Step 3: Testing enhanced firewall configuration process%RESET%

REM Clean up any existing flag files to avoid false positives
if exist firewall_complete.flag del firewall_complete.flag >nul 2>&1
if exist firewall_output.txt del firewall_output.txt >nul 2>&1

echo %CYAN%Creating temporary firewall configuration script...%RESET%
echo [%DATE% %TIME%] Creating temporary firewall script >> "%TEST_LOG%"

REM Create a temporary script file for the firewall configuration
(
    echo @echo off
    echo setlocal enabledelayedexpansion
    echo echo Configuring test firewall rules...
    echo.
    echo REM Test rule 1
    echo echo Creating test rule 1 ^(port 9090^)...
    echo netsh advfirewall firewall delete rule name="Aruba IoT Test Rule 1" ^>nul 2^>^&1
    echo netsh advfirewall firewall add rule name="Aruba IoT Test Rule 1" dir=in action=allow protocol=TCP localport=9090 description="Aruba IoT Test Rule" ^>nul 2^>^&1
    echo set "RULE1_RESULT=!ERRORLEVEL!"
    echo echo Test rule 1 result: !RULE1_RESULT! ^(0=success^)
    echo.
    echo REM Test rule 2
    echo echo Creating test rule 2 ^(port 9191^)...
    echo netsh advfirewall firewall delete rule name="Aruba IoT Test Rule 2" ^>nul 2^>^&1
    echo netsh advfirewall firewall add rule name="Aruba IoT Test Rule 2" dir=in action=allow protocol=TCP localport=9191 description="Aruba IoT Test Rule" ^>nul 2^>^&1
    echo set "RULE2_RESULT=!ERRORLEVEL!"
    echo echo Test rule 2 result: !RULE2_RESULT! ^(0=success^)
    echo.
    echo REM Verification
    echo echo Verifying rules...
    echo netsh advfirewall firewall show rule name="Aruba IoT Test Rule 1" ^>nul 2^>^&1
    echo set "VERIFY1=!ERRORLEVEL!"
    echo.
    echo netsh advfirewall firewall show rule name="Aruba IoT Test Rule 2" ^>nul 2^>^&1
    echo set "VERIFY2=!ERRORLEVEL!"
    echo.
    echo if !RULE1_RESULT!==0 if !RULE2_RESULT!==0 if !VERIFY1!==0 if !VERIFY2!==0 ^(
    echo     echo FIREWALL_CONFIG_SUCCESS
    echo ^) else ^(
    echo     echo FIREWALL_CONFIG_FAILED
    echo ^)
    echo.
    echo echo 1^> "%CD%\firewall_complete.flag"
    echo exit /b 0
) > "%TEMP%\aruba_firewall_test.bat"

REM Execute the temporary script
echo %CYAN%Executing firewall configuration in isolated process...%RESET%
echo [%DATE% %TIME%] Executing temporary firewall script >> "%TEST_LOG%"

REM Start the firewall configuration in a separate process
start /b cmd /c "%TEMP%\aruba_firewall_test.bat" > firewall_output.txt 2>&1

REM Wait for the configuration to complete with a timeout
set "TIMEOUT_SECONDS=15"
echo Waiting up to !TIMEOUT_SECONDS! seconds for process to complete...
set "ELAPSED=0"
set "FIREWALL_COMPLETE=0"

:wait_for_completion
if !ELAPSED! geq !TIMEOUT_SECONDS! (
    echo %YELLOW%⚠️  Process timed out after !TIMEOUT_SECONDS! seconds%RESET%
    echo [%DATE% %TIME%] Process timed out >> "%TEST_LOG%"
    goto :timeout_end
)

if exist firewall_complete.flag (
    set "FIREWALL_COMPLETE=1"
    del firewall_complete.flag >nul 2>&1
    goto :timeout_end
)

timeout /t 1 /nobreak >nul
set /a ELAPSED+=1
goto :wait_for_completion

:timeout_end
REM Clean up temporary script
if exist "%TEMP%\aruba_firewall_test.bat" del "%TEMP%\aruba_firewall_test.bat" >nul 2>&1

REM Process results
echo.
echo %BLUE%Step 4: Checking results%RESET%

if !FIREWALL_COMPLETE!==1 (
    echo %GREEN%✅ Process completed within timeout period%RESET%
    echo [%DATE% %TIME%] Process completed within timeout >> "%TEST_LOG%"
) else (
    echo %RED%❌ Process did not complete within timeout period%RESET%
    echo [%DATE% %TIME%] Process did not complete within timeout >> "%TEST_LOG%"
)

if exist firewall_output.txt (
    echo %CYAN%Firewall Configuration Output:%RESET%
    type firewall_output.txt
    echo.
    
    REM Check for success marker
    findstr /C:"FIREWALL_CONFIG_SUCCESS" firewall_output.txt >nul 2>&1
    set "SUCCESS_MARKER=!ERRORLEVEL!"
    
    if !SUCCESS_MARKER!==0 (
        echo %GREEN%✅ Firewall configuration succeeded%RESET%
        echo [%DATE% %TIME%] Configuration succeeded >> "%TEST_LOG%"
    ) else (
        echo %RED%❌ Firewall configuration failed%RESET%
        echo [%DATE% %TIME%] Configuration failed >> "%TEST_LOG%"
    )
    
    REM Save output to log
    echo ===== FIREWALL OUTPUT ===== >> "%TEST_LOG%"
    type firewall_output.txt >> "%TEST_LOG%"
    echo ========================== >> "%TEST_LOG%"
    
    del firewall_output.txt >nul 2>&1
)

REM Step 5: Clean up test rules
echo.
echo %BLUE%Step 5: Cleaning up test rules%RESET%

if !ADMIN_RIGHTS!==0 (
    echo Removing test firewall rules...
    netsh advfirewall firewall delete rule name="Aruba IoT Test Rule 1" >nul 2>&1
    netsh advfirewall firewall delete rule name="Aruba IoT Test Rule 2" >nul 2>&1
    echo %GREEN%✅ Test rules removed%RESET%
    echo [%DATE% %TIME%] Test rules removed >> "%TEST_LOG%"
)

REM Final summary
echo.
echo %CYAN%Test Summary:%RESET%
echo =============
echo Windows Firewall Service: !SERVICE_RUNNING! (0=running)
echo Admin Rights: !ADMIN_RIGHTS! (0=yes)
echo Process Completion: !FIREWALL_COMPLETE! (1=completed)
if !FIREWALL_COMPLETE!==1 (
    echo Configuration Success: !SUCCESS_MARKER! (0=success)
)
echo.
echo Log file: %TEST_LOG%
echo.

echo %CYAN%This test verifies if the enhanced firewall configuration process:%RESET%
echo 1. Properly runs in an isolated process
echo 2. Reliably signals completion
echo 3. Successfully configures firewall rules
echo 4. Does not hang or block the script
echo.

echo %CYAN%Press any key to exit...%RESET%
pause >nul

ENDLOCAL
