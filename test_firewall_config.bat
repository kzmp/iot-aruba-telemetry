@echo off
REM Test script specifically for firewall configuration debugging
REM This script tests only the firewall configuration step

SETLOCAL EnableDelayedExpansion

echo.
echo 🔥 Firewall Configuration Test Script
echo ====================================
echo This script tests only the firewall configuration functionality.
echo.

REM Set up basic variables and colors
for /F %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
set "GREEN=%ESC%[92m"
set "RED=%ESC%[91m"
set "YELLOW=%ESC%[93m"
set "BLUE=%ESC%[94m"
set "CYAN=%ESC%[96m"
set "RESET=%ESC%[0m"

set "FIREWALL_OK=0"

REM Create test log
set "TEST_LOG=firewall_test_log.txt"
echo [%DATE% %TIME%] Firewall test started > "%TEST_LOG%"

echo %CYAN%Testing firewall configuration...%RESET%
echo.

REM Test admin privileges
echo %BLUE%Step 1: Checking administrator privileges%RESET%
net session >nul 2>&1
set "ADMIN_RESULT=!ERRORLEVEL!"

if !ADMIN_RESULT!==0 (
    echo %GREEN%✅ Administrator privileges confirmed%RESET%
    echo [%DATE% %TIME%] Admin privileges: YES >> "%TEST_LOG%"
) else (
    echo %YELLOW%⚠️  No administrator privileges%RESET%
    echo [%DATE% %TIME%] Admin privileges: NO >> "%TEST_LOG%"
    echo.
    echo %CYAN%Solutions:%RESET%
    echo 1. Right-click this script and "Run as administrator"
    echo 2. Or test will show you manual firewall setup instructions
    echo.
    pause
)

echo.
echo %BLUE%Step 2: Testing firewall rule creation%RESET%

if !ADMIN_RESULT!==0 (
    echo %CYAN%Adding test firewall rules...%RESET%
    
    REM Test port 9090 rule
    echo Testing port 9090 rule...
    netsh advfirewall firewall delete rule name="Aruba IoT Web Dashboard Test" >nul 2>&1
    netsh advfirewall firewall add rule name="Aruba IoT Web Dashboard Test" dir=in action=allow protocol=TCP localport=9090 description="Test rule for Aruba IoT" >nul 2>&1
    set "WEB_RESULT=!ERRORLEVEL!"
    echo [%DATE% %TIME%] Port 9090 rule creation result: !WEB_RESULT! >> "%TEST_LOG%"
    
    if !WEB_RESULT!==0 (
        echo   %GREEN%✅ Port 9090 rule created successfully%RESET%
    ) else (
        echo   %RED%❌ Port 9090 rule creation failed (Error: !WEB_RESULT!)%RESET%
    )
    
    REM Test port 9191 rule
    echo Testing port 9191 rule...
    netsh advfirewall firewall delete rule name="Aruba IoT WebSocket Test" >nul 2>&1
    netsh advfirewall firewall add rule name="Aruba IoT WebSocket Test" dir=in action=allow protocol=TCP localport=9191 description="Test rule for Aruba IoT" >nul 2>&1
    set "WS_RESULT=!ERRORLEVEL!"
    echo [%DATE% %TIME%] Port 9191 rule creation result: !WS_RESULT! >> "%TEST_LOG%"
    
    if !WS_RESULT!==0 (
        echo   %GREEN%✅ Port 9191 rule created successfully%RESET%
    ) else (
        echo   %RED%❌ Port 9191 rule creation failed (Error: !WS_RESULT!)%RESET%
    )
    
    echo.
    echo %BLUE%Step 3: Verifying firewall rules%RESET%
    
    REM Verify rules exist
    netsh advfirewall firewall show rule name="Aruba IoT Web Dashboard Test" >nul 2>&1
    set "VERIFY_WEB=!ERRORLEVEL!"
    echo [%DATE% %TIME%] Port 9090 rule verification: !VERIFY_WEB! >> "%TEST_LOG%"
    
    netsh advfirewall firewall show rule name="Aruba IoT WebSocket Test" >nul 2>&1
    set "VERIFY_WS=!ERRORLEVEL!"
    echo [%DATE% %TIME%] Port 9191 rule verification: !VERIFY_WS! >> "%TEST_LOG%"
    
    if !VERIFY_WEB!==0 (
        echo   %GREEN%✅ Port 9090 rule verified%RESET%
    ) else (
        echo   %RED%❌ Port 9090 rule verification failed%RESET%
    )
    
    if !VERIFY_WS!==0 (
        echo   %GREEN%✅ Port 9191 rule verified%RESET%
    ) else (
        echo   %RED%❌ Port 9191 rule verification failed%RESET%
    )
    
    echo.
    echo %BLUE%Step 4: Cleanup test rules%RESET%
    echo Removing test firewall rules...
    netsh advfirewall firewall delete rule name="Aruba IoT Web Dashboard Test" >nul 2>&1
    netsh advfirewall firewall delete rule name="Aruba IoT WebSocket Test" >nul 2>&1
    echo   %GREEN%✅ Test rules removed%RESET%
    
    REM Overall result
    if !WEB_RESULT!==0 if !WS_RESULT!==0 if !VERIFY_WEB!==0 if !VERIFY_WS!==0 (
        set "FIREWALL_OK=1"
        echo.
        echo %GREEN%🎉 FIREWALL TEST PASSED!%RESET%
        echo ========================
        echo The firewall configuration should work correctly in the main setup script.
    ) else (
        echo.
        echo %RED%❌ FIREWALL TEST FAILED%RESET%
        echo ======================
        echo The firewall configuration has issues. Details:
        echo   Port 9090 creation: !WEB_RESULT! (0=success)
        echo   Port 9191 creation: !WS_RESULT! (0=success)
        echo   Port 9090 verification: !VERIFY_WEB! (0=success)
        echo   Port 9191 verification: !VERIFY_WS! (0=success)
    )
    
) else (
    echo %YELLOW%Cannot test firewall rules without administrator privileges%RESET%
    echo.
    echo %CYAN%Manual Firewall Configuration:%RESET%
    echo ============================
    echo.
    echo %YELLOW%Method 1: Windows Firewall with Advanced Security%RESET%
    echo 1. Press Win+R, type: wf.msc
    echo 2. Click "Inbound Rules" in left panel
    echo 3. Click "New Rule..." in right panel
    echo 4. Select "Port" → Next
    echo 5. Select "TCP" and "Specific local ports"
    echo 6. Enter: 9090,9191 → Next
    echo 7. Select "Allow the connection" → Next
    echo 8. Check all profiles (Domain, Private, Public) → Next
    echo 9. Name: "Aruba IoT Telemetry Server" → Finish
    echo.
    echo %YELLOW%Method 2: Command Line (run as administrator)%RESET%
    echo netsh advfirewall firewall add rule name="Aruba IoT Dashboard" dir=in action=allow protocol=TCP localport=9090
    echo netsh advfirewall firewall add rule name="Aruba IoT WebSocket" dir=in action=allow protocol=TCP localport=9191
    echo.
    echo %YELLOW%Method 3: Use the provided script%RESET%
    echo Right-click 'configure_firewall.bat' and select "Run as administrator"
)

echo.
echo %BLUE%Test Summary:%RESET%
echo ============
echo Administrator privileges: !ADMIN_RESULT! (0=yes, 1=no)
if !ADMIN_RESULT!==0 (
    echo Firewall configuration: !FIREWALL_OK! (1=success, 0=failed)
    echo Port 9090 rule: !WEB_RESULT! (0=success)
    echo Port 9191 rule: !WS_RESULT! (0=success)
    echo Rule verification: !VERIFY_WEB!/!VERIFY_WS! (0=success)
)
echo.
echo Log file: %TEST_LOG%
echo.

if !FIREWALL_OK!==1 (
    echo %GREEN%✅ The enhanced setup script should work correctly for firewall configuration!%RESET%
) else (
    echo %YELLOW%⚠️  You may need to configure the firewall manually or run as administrator.%RESET%
)

echo.
echo %CYAN%Press any key to exit...%RESET%
pause >nul

ENDLOCAL
