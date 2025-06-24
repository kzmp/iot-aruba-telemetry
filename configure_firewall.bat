@echo off
REM Configure Windows Firewall for Aruba IoT Telemetry Server

echo 🔥 Windows Firewall Configuration for Aruba IoT Telemetry
echo =========================================================
echo.
echo This script will configure Windows Firewall to allow:
echo - Port 9090 (Web Dashboard)
echo - Port 9191 (WebSocket Server)
echo.

REM Check if running as administrator
net session >nul 2>&1
if errorlevel 1 (
    echo ❌ This script requires Administrator privileges
    echo.
    echo Please:
    echo 1. Right-click on Command Prompt
    echo 2. Select "Run as administrator"
    echo 3. Navigate to this folder
    echo 4. Run: configure_firewall.bat
    echo.
    pause
    exit /b 1
)

echo ✅ Administrator privileges detected
echo.

REM Remove existing rules first (in case they exist)
echo 🧹 Removing any existing rules...
netsh advfirewall firewall delete rule name="Aruba IoT Web Dashboard" >nul 2>&1
netsh advfirewall firewall delete rule name="Aruba IoT WebSocket Server" >nul 2>&1
netsh advfirewall firewall delete rule name="Aruba IoT Web" >nul 2>&1
netsh advfirewall firewall delete rule name="Aruba IoT WebSocket" >nul 2>&1

REM Add new firewall rules
echo 🛡️  Adding firewall rules...

echo Adding rule for Web Dashboard (port 9090)...
netsh advfirewall firewall add rule name="Aruba IoT Web Dashboard" dir=in action=allow protocol=TCP localport=9090 profile=any
if errorlevel 1 (
    echo ❌ Failed to add rule for port 9090
    set "error=1"
) else (
    echo ✅ Successfully added rule for port 9090
)

echo.
echo Adding rule for WebSocket Server (port 9191)...
netsh advfirewall firewall add rule name="Aruba IoT WebSocket Server" dir=in action=allow protocol=TCP localport=9191 profile=any
if errorlevel 1 (
    echo ❌ Failed to add rule for port 9191
    set "error=1"
) else (
    echo ✅ Successfully added rule for port 9191
)

echo.
echo 🔍 Verifying firewall configuration...
echo =====================================

REM Check if rules are active
netsh advfirewall firewall show rule name="Aruba IoT Web Dashboard" | findstr "Enabled" >nul 2>&1
if errorlevel 1 (
    echo ❌ Web Dashboard rule not found or not enabled
    set "error=1"
) else (
    echo ✅ Web Dashboard rule is active
)

netsh advfirewall firewall show rule name="Aruba IoT WebSocket Server" | findstr "Enabled" >nul 2>&1
if errorlevel 1 (
    echo ❌ WebSocket Server rule not found or not enabled
    set "error=1"
) else (
    echo ✅ WebSocket Server rule is active
)

echo.
if defined error (
    echo ⚠️  Some firewall rules may not have been configured correctly
    echo.
    echo Manual Configuration:
    echo ====================
    echo 1. Open "Windows Defender Firewall with Advanced Security"
    echo 2. Click "Inbound Rules" in the left panel
    echo 3. Click "New Rule..." in the right panel
    echo 4. Select "Port" and click Next
    echo 5. Select "TCP" and enter "9090,9191" in Specific local ports
    echo 6. Select "Allow the connection" and click Next
    echo 7. Check all profiles (Domain, Private, Public) and click Next
    echo 8. Name the rule "Aruba IoT Telemetry" and click Finish
) else (
    echo ✅ Firewall configuration completed successfully!
    echo.
    echo Your Aruba IoT Telemetry server can now accept external connections on:
    echo - Port 9090 (Web Dashboard)
    echo - Port 9191 (WebSocket Server)
)

echo.
echo 📋 Current firewall rules for Aruba IoT:
echo =======================================
netsh advfirewall firewall show rule name="Aruba IoT Web Dashboard"
echo.
netsh advfirewall firewall show rule name="Aruba IoT WebSocket Server"

echo.
echo 🔧 To remove these rules later (if needed):
echo ===========================================
echo netsh advfirewall firewall delete rule name="Aruba IoT Web Dashboard"
echo netsh advfirewall firewall delete rule name="Aruba IoT WebSocket Server"

echo.
pause
