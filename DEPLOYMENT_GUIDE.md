# Aruba IoT Telemetry Server - Deployment Guide

## Prerequisites

### System Requirements
- **Operating System**: Linux, macOS, or Windows
- **Python**: Version 3.8 or higher
- **Memory**: Minimum 512MB RAM
- **Network**: Open port 9090 (web dashboard) and 9191 (WebSocket server)
- **Git**: For cloning the repository

### Network Requirements
- Firewall rules allowing inbound connections on ports 9090 and 9191
- Static IP address or dynamic DNS (recommended for production)

## Installation Steps

### 1. Clone the Repository
```bash
git clone https://github.com/kzmp/iot-aruba-telemetry.git
cd iot-aruba-telemetry
```

### 2. Create Python Virtual Environment
```bash
# On Linux/macOS:
python3 -m venv .venv
source .venv/bin/activate

# On Windows:
python -m venv .venv
.venv\Scripts\activate
```

### 3. Install Dependencies
```bash
pip install -r requirements.txt
```

### 4. Configure Environment Variables
Create a `.env` file:
```bash
cp .env.example .env  # If available, or create manually
```

Edit `.env` with your configuration:
```properties
# Flask Configuration
FLASK_HOST=0.0.0.0
FLASK_PORT=9090
FLASK_DEBUG=False
SECRET_KEY=your-unique-secret-key-change-this

# Aruba WebSocket Server Configuration
ARUBA_WS_HOST=0.0.0.0
ARUBA_WS_PORT=9191

# Authentication Configuration (IMPORTANT!)
ARUBA_AUTH_TOKENS=your-token-1,your-token-2,admin,production-key

# Logging Configuration
LOG_LEVEL=INFO
```

### 5. Test the Installation
```bash
python app.py
```

## Production Deployment

### Option 1: Using systemd (Linux)

Create service file: `/etc/systemd/system/aruba-iot.service`
```ini
[Unit]
Description=Aruba IoT Telemetry Server
After=network.target

[Service]
Type=simple
User=iot-user
WorkingDirectory=/opt/aruba-iot-telemetry
Environment=PATH=/opt/aruba-iot-telemetry/.venv/bin
ExecStart=/opt/aruba-iot-telemetry/.venv/bin/python app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl enable aruba-iot
sudo systemctl start aruba-iot
sudo systemctl status aruba-iot
```

### Option 2: Using Docker

Create `Dockerfile`:
```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 9090 9191

CMD ["python", "app.py"]
```

Build and run:
```bash
docker build -t aruba-iot-telemetry .
docker run -d -p 9090:9090 -p 9191:9191 \
  --env-file .env \
  --name aruba-iot \
  aruba-iot-telemetry
```

### Option 3: Using Docker Compose

Create `docker-compose.yml`:
```yaml
version: '3.8'
services:
  aruba-iot:
    build: .
    ports:
      - "9090:9090"
      - "9191:9191"
    environment:
      - FLASK_HOST=0.0.0.0
      - FLASK_PORT=9090
      - ARUBA_WS_HOST=0.0.0.0
      - ARUBA_WS_PORT=9191
      - ARUBA_AUTH_TOKENS=prod-token,admin,secure-key
    restart: unless-stopped
    volumes:
      - ./logs:/app/logs
```

Run:
```bash
docker-compose up -d
```

## Firewall Configuration

### Linux (UFW)
```bash
sudo ufw allow 9090/tcp
sudo ufw allow 9191/tcp
sudo ufw reload
```

### Linux (iptables)
```bash
sudo iptables -A INPUT -p tcp --dport 9090 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 9191 -j ACCEPT
sudo iptables-save > /etc/iptables/rules.v4
```

### macOS
```bash
# Add rules to /etc/pf.conf
echo "pass in proto tcp from any to any port 9090" >> /etc/pf.conf
echo "pass in proto tcp from any to any port 9191" >> /etc/pf.conf
sudo pfctl -f /etc/pf.conf
```

### Windows
```powershell
netsh advfirewall firewall add rule name="Aruba IoT Web" dir=in action=allow protocol=TCP localport=9090
netsh advfirewall firewall add rule name="Aruba IoT WebSocket" dir=in action=allow protocol=TCP localport=9191
```

## Security Considerations

### 1. Change Default Authentication Tokens
Update `ARUBA_AUTH_TOKENS` in `.env`:
```properties
ARUBA_AUTH_TOKENS=prod-secure-token-2025,backup-token,admin-key-xyz
```

### 2. Use HTTPS/WSS (Recommended for Production)
Configure reverse proxy with SSL:

**Nginx configuration** (`/etc/nginx/sites-available/aruba-iot`):
```nginx
server {
    listen 443 ssl;
    server_name your-domain.com;
    
    ssl_certificate /path/to/certificate.crt;
    ssl_certificate_key /path/to/private.key;
    
    # Web Dashboard
    location / {
        proxy_pass http://localhost:9090;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    # WebSocket Server
    location /aruba {
        proxy_pass http://localhost:9191;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### 3. Restrict Network Access
Use firewall rules to limit access to trusted networks only:
```bash
# Allow only specific network
sudo ufw allow from 192.168.1.0/24 to any port 9191
```

## Monitoring and Maintenance

### 1. Log Monitoring
```bash
# View real-time logs
tail -f /var/log/aruba-iot.log

# Check systemd logs
journalctl -u aruba-iot -f
```

### 2. Health Check Script
Create `health_check.sh`:
```bash
#!/bin/bash
curl -f http://localhost:9090/api/stats || exit 1
nc -z localhost 9191 || exit 1
echo "Aruba IoT Server is healthy"
```

### 3. Backup Configuration
```bash
# Backup important files
tar -czf aruba-iot-backup-$(date +%Y%m%d).tar.gz \
  .env app.py templates/ requirements.txt
```

## Connection URLs for Remote Access

After deployment, your Aruba controllers can connect using:

### Standard Connection
```
ws://YOUR_SERVER_IP:9191/aruba?token=YOUR_TOKEN
```

### Secure Connection (with SSL proxy)
```
wss://your-domain.com/aruba?token=YOUR_TOKEN
```

## Troubleshooting Remote Deployment

### 1. Check Service Status
```bash
sudo systemctl status aruba-iot
```

### 2. Verify Port Binding
```bash
netstat -tulpn | grep -E ':(9090|9191)'
```

### 3. Test External Connectivity
```bash
# From another machine
telnet YOUR_SERVER_IP 9191
```

### 4. Check Logs
```bash
journalctl -u aruba-iot --since "1 hour ago"
```

## Performance Optimization

### 1. Increase File Descriptors (Linux)
```bash
echo "* soft nofile 65536" >> /etc/security/limits.conf
echo "* hard nofile 65536" >> /etc/security/limits.conf
```

### 2. Optimize Network Settings
```bash
echo 'net.core.somaxconn = 65536' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_max_syn_backlog = 65536' >> /etc/sysctl.conf
sysctl -p
```

## Support

- **GitHub Repository**: https://github.com/kzmp/iot-aruba-telemetry
- **Issues**: Report bugs or request features on GitHub
- **Documentation**: Check README.md and ARUBA_CONNECTION_GUIDE.md

## Quick Start Command Summary

```bash
# 1. Clone and setup
git clone https://github.com/kzmp/iot-aruba-telemetry.git
cd iot-aruba-telemetry
python3 -m venv .venv
source .venv/bin/activate  # Linux/macOS
pip install -r requirements.txt

# 2. Configure
cp .env.example .env
# Edit .env with your settings

# 3. Run
python app.py

# 4. Access
# Web Dashboard: http://YOUR_IP:9090
# WebSocket: ws://YOUR_IP:9191/aruba?token=YOUR_TOKEN
```

## Windows Installation with GitHub Desktop

### Prerequisites for Windows
- **GitHub Desktop**: Download from [desktop.github.com](https://desktop.github.com/)
- **Python 3.8+**: Download from [python.org](https://www.python.org/downloads/windows/)
- **Git for Windows**: Usually included with GitHub Desktop

### 🎯 Option 1: One-Click Installation (Recommended)

#### Step 1: Clone Repository with GitHub Desktop
1. **Open GitHub Desktop**
2. **Clone Repository**:
   - Click "Clone a repository from the Internet"
   - Enter repository URL: `https://github.com/kzmp/iot-aruba-telemetry`
   - Choose local path (e.g., `C:\Users\YourName\Documents\iot-aruba-telemetry`)
   - Click "Clone"

#### Step 2: Run One-Click Installer
1. **Open the project folder** (from GitHub Desktop: Repository → Show in Explorer)
2. **Double-click**: `INSTALL_WINDOWS.bat`
3. **Follow the prompts** - the installer will:
   - Check Python installation (download if needed)
   - Create virtual environment
   - Install all dependencies
   - Generate secure configuration
   - Configure Windows Firewall
   - Test the installation
   - Optionally start the server

#### That's it! 🎉
The one-click installer handles everything automatically.

### 🛠️ Option 2: Advanced Setup Scripts

For more control over the installation process:

#### Quick Setup
```cmd
setup_windows.bat
```

#### Comprehensive Setup with Visual Progress
```cmd
setup_windows_oneclick.bat
```

#### Individual Tools
```cmd
configure_firewall.bat     # Configure Windows Firewall only
test_installation.bat      # Test existing installation
troubleshoot_windows.bat   # Diagnose problems
```

### 🚀 Option 3: Manual Installation (Advanced Users)

#### 1. Clone Repository with GitHub Desktop
1. **Open GitHub Desktop**
2. **Clone Repository**:
   - Click "Clone a repository from the Internet"
   - Enter repository URL: `https://github.com/kzmp/iot-aruba-telemetry`
   - Choose local path (e.g., `C:\Users\YourName\Documents\iot-aruba-telemetry`)
   - Click "Clone"

#### 2. Setup Python Environment
1. **Open GitHub Desktop**
2. **Clone Repository**:
   - Click "Clone a repository from the Internet"
   - Enter repository URL: `https://github.com/kzmp/iot-aruba-telemetry`
   - Choose local path (e.g., `C:\Users\YourName\Documents\iot-aruba-telemetry`)
   - Click "Clone"

#### 2. Setup Python Environment
1. **Open Command Prompt or PowerShell**:
   - Press `Win + R`, type `cmd`, press Enter
   - Or press `Win + X`, select "Windows PowerShell"

2. **Navigate to project directory**:
   ```cmd
   cd "C:\Users\YourName\Documents\iot-aruba-telemetry"
   ```

3. **Create virtual environment**:
   ```cmd
   python -m venv .venv
   ```

4. **Activate virtual environment**:
   ```cmd
   .venv\Scripts\activate
   ```

5. **Install dependencies**:
   ```cmd
   pip install -r requirements.txt
   ```

#### 3. Configure Environment
1. **Create configuration file**:
   ```cmd
   copy nul .env
   ```

2. **Edit .env file** (use Notepad or any text editor):
   ```cmd
   notepad .env
   ```

3. **Add configuration** (paste this into the .env file):
   ```properties
   # Flask Configuration
   FLASK_HOST=0.0.0.0
   FLASK_PORT=9090
   FLASK_DEBUG=False
   SECRET_KEY=your-windows-secret-key-change-this

   # Aruba WebSocket Server Configuration
   ARUBA_WS_HOST=0.0.0.0
   ARUBA_WS_PORT=9191

   # Authentication Configuration
   ARUBA_AUTH_TOKENS=admin,windows-token,aruba-iot,secure-2025

   # Logging Configuration
   LOG_LEVEL=INFO
   ```

#### 4. Configure Windows Firewall
1. **Open Windows Defender Firewall**:
   - Press `Win + R`, type `wf.msc`, press Enter

2. **Create inbound rules** for ports 9090 and 9191:
   - Click "Inbound Rules" → "New Rule"
   - Select "Port" → "TCP"
   - Enter port numbers: `9090` and `9191`
   - Allow the connection
   - Apply to all profiles
   - Name: "Aruba IoT Telemetry"

**Or use PowerShell (Run as Administrator)**:
```powershell
New-NetFirewallRule -DisplayName "Aruba IoT Web" -Direction Inbound -Protocol TCP -LocalPort 9090 -Action Allow
New-NetFirewallRule -DisplayName "Aruba IoT WebSocket" -Direction Inbound -Protocol TCP -LocalPort 9191 -Action Allow
```

#### 5. Run the Application
1. **Start the server**:
   ```cmd
   python app.py
   ```

2. **Access the application**:
   - Web Dashboard: `http://localhost:9090`
   - WebSocket endpoint: `ws://YOUR_WINDOWS_IP:9191/aruba?token=admin`

#### 6. Find Your Windows IP Address
```cmd
ipconfig | findstr "IPv4"
```

### Windows Service Installation (Optional)

For running as a Windows service, create `install_service.bat`:

```batch
@echo off
echo Installing Aruba IoT as Windows Service...

REM Install Python Windows Service Wrapper
pip install pywin32

REM Create service script
python -c "
import win32serviceutil
import win32service
import win32event
import servicemanager
import socket
import sys
import os
import subprocess

class ArubaIoTService(win32serviceutil.ServiceFramework):
    _svc_name_ = 'ArubaIoTTelemetry'
    _svc_display_name_ = 'Aruba IoT Telemetry Server'
    _svc_description_ = 'WebSocket server for Aruba IoT telemetry data'

    def __init__(self, args):
        win32serviceutil.ServiceFramework.__init__(self, args)
        self.hWaitStop = win32event.CreateEvent(None, 0, 0, None)
        socket.setdefaulttimeout(60)

    def SvcStop(self):
        self.ReportServiceStatus(win32service.SERVICE_STOP_PENDING)
        win32event.SetEvent(self.hWaitStop)

    def SvcDoRun(self):
        servicemanager.LogMsg(servicemanager.EVENTLOG_INFORMATION_TYPE,
                              servicemanager.PYS_SERVICE_STARTED,
                              (self._svc_name_, ''))
        self.main()

    def main(self):
        import subprocess
        import os
        
        # Change to script directory
        script_dir = os.path.dirname(os.path.abspath(__file__))
        os.chdir(script_dir)
        
        # Activate virtual environment and run app
        venv_python = os.path.join(script_dir, '.venv', 'Scripts', 'python.exe')
        app_script = os.path.join(script_dir, 'app.py')
        
        process = subprocess.Popen([venv_python, app_script])
        process.wait()

if __name__ == '__main__':
    win32serviceutil.HandleCommandLine(ArubaIoTService)
"

REM Install the service
python install_service.py install

echo Service installed successfully!
echo Start with: net start ArubaIoTTelemetry
echo Stop with: net stop ArubaIoTTelemetry
pause
```

### Updating with GitHub Desktop

1. **Open GitHub Desktop**
2. **Select your repository**
3. **Click "Fetch origin"** to check for updates
4. **Click "Pull origin"** if updates are available
5. **Restart the application** to apply updates
