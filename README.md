# 🌐 Aruba IoT Telemetry Web Application

A Python web application with WebSocket support designed to receive and visualize IoT telemetry data from Aruba network infrastructure. This application processes real-time data from Bluetooth Low Energy (BLE), EnOcean Alliance, and WiFi packets for location and sensing applications.

## ✨ Features

- **Real-time WebSocket Communication**: Receives telemetry data from Aruba access points
- **Multi-Protocol Support**: Handles BLE, WiFi, and EnOcean packets
- **Live Dashboard**: Beautiful web interface with real-time updates
- **Device Registry**: Tracks discovered devices and their metadata
- **Statistics & Analytics**: Packet distribution charts and counters
- **Test Simulator**: Built-in AP simulator for testing and development

## 🏗️ Architecture

```
┌─────────────────┐    WebSocket    ┌──────────────────┐    SocketIO    ┌─────────────────┐
│  Aruba Access   │────────────────▶│   Python Flask   │───────────────▶│   Web Dashboard │
│     Points      │    Port 9191    │   Application    │   Port 9090    │                 │
└─────────────────┘                 └──────────────────┘                └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- Python 3.8 or higher
- pip package manager

### Installation

1. **Clone or navigate to the project directory**:
   ```bash
   cd /Users/deaw/Downloads/newgit/iot-aruba
   ```

2. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

3. **Configure environment** (optional):
   ```bash
   cp .env.example .env
   # Edit .env with your preferred settings
   ```

### Running the Application

1. **Start the main application**:
   ```bash
   python app.py
   ```

2. **Open the dashboard**:
   Navigate to `http://localhost:9090` in your web browser

3. **Test with simulator** (in a new terminal):
   ```bash
   python test_client.py --duration 120
   ```

## 📊 Dashboard Features

The web dashboard provides comprehensive BLE analytics and monitoring:

### Real-time Monitoring
- **📡 Live Telemetry Stream**: Real-time packet display with type indicators
- **📱 Connected Devices**: Registry of discovered devices
- **📊 Packet Distribution**: Visual charts showing packet type breakdown
- **📈 Real-time Statistics**: Counters for packets, devices, and connections

### BLE Analytics & Reporting
- **📡 BLE Reporters (Access Points)**: Detailed statistics about APs detecting BLE devices
  - Devices seen per reporter
  - Total packets per reporter  
  - Average RSSI per reporter
  - Signal quality indicators
- **📱 BLE Devices (Reported)**: Comprehensive device tracking
  - Device information and MAC addresses
  - Number of reporters seeing each device
  - RSSI statistics (best, worst, average)
  - Primary reporter identification
- **📊 Signal Quality Distribution**: Visual breakdown of device signal strengths
- **🏆 Top Analytics**: 
  - Most active reporters by packet count
  - Most active devices by packet count
  - Performance rankings and insights

### Advanced Features
- **Reporter-Reported Relationship**: Track which access points see which devices
- **Proximity Mapping**: Device-to-AP proximity based on signal strength
- **Signal Quality Indicators**: Color-coded RSSI status (Excellent, Good, Fair, Poor)
- **🔄 Auto-refresh**: Updates every 5 seconds

## 🔧 Configuration

Edit the `.env` file to customize:

```env
# Flask Configuration
FLASK_HOST=0.0.0.0
FLASK_PORT=5000
FLASK_DEBUG=True

# WebSocket Server for Aruba APs
ARUBA_WS_HOST=0.0.0.0
ARUBA_WS_PORT=8765

# Security
SECRET_KEY=your-secret-key-here
```

## 📡 Aruba AP Integration

### WebSocket Endpoint

Aruba access points should connect to:
```
ws://your-server-ip:8765
```

### Expected Packet Format

#### BLE Packet
```json
{
  "type": "ble",
  "deviceId": "ble-aabbccddeeff",
  "macAddress": "aa:bb:cc:dd:ee:ff",
  "rssi": -65,
  "manufacturerData": "4c00",
  "serviceUuids": ["180f", "180a"],
  "location": {"x": 10.5, "y": 20.3, "z": 1.2},
  "accessPoint": "AP-01"
}
```

#### WiFi Packet
```json
{
  "type": "wifi",
  "deviceId": "wifi-aabbccddeeff",
  "macAddress": "aa:bb:cc:dd:ee:ff",
  "ssid": "Guest-Network",
  "rssi": -45,
  "channel": 6,
  "location": {"x": 15.2, "y": 25.8, "z": 1.5},
  "accessPoint": "AP-01"
}
```

#### EnOcean Packet
```json
{
  "type": "enocean",
  "deviceId": "enocean-00112233",
  "eep": "F6-02-01",
  "payload": "12345678",
  "rssi": -55,
  "location": {"x": 8.7, "y": 12.4, "z": 0.8},
  "accessPoint": "AP-01"
}
```

## 🧪 Testing

### Using the Built-in Simulator

The included test client simulates an Aruba access point:

```bash
# Basic usage
python test_client.py

# Custom server and duration
python test_client.py --server ws://192.168.1.100:8765 --duration 300

# Help
python test_client.py --help
```

### Manual Testing

You can also send test data using any WebSocket client:

```bash
# Using wscat (npm install -g wscat)
wscat -c ws://localhost:8765

# Then send JSON packets manually
```

## 📁 Project Structure

```
iot-aruba/
├── app.py                 # Main Flask application
├── test_client.py         # AP simulator for testing
├── requirements.txt       # Python dependencies
├── .env                  # Environment configuration
├── templates/
│   └── dashboard.html    # Web dashboard template
├── .github/
│   └── copilot-instructions.md
└── README.md
```

## 🔍 API Endpoints

### Core Endpoints
- `GET /` - Main dashboard with BLE analytics
- `GET /api/devices` - Get device registry
- `GET /api/telemetry?limit=N` - Get recent telemetry data
- `GET /api/stats` - Get packet statistics

### BLE Analytics Endpoints
- `GET /api/ble/reporters` - Get BLE reporter (Access Point) statistics
- `GET /api/ble/devices` - Get BLE device (reported) statistics  
- `GET /api/ble/proximity` - Get device-to-AP proximity mapping
- `GET /api/ble/analytics` - Get comprehensive BLE analytics including:
  - Signal quality distribution
  - Top reporters by activity
  - Most active devices
  - Summary statistics

## 🌟 Advanced Features

### Device Registry
- Automatic device discovery and tracking
- Last seen timestamps
- Device type classification
- Access point associations

### Real-time Updates
- WebSocket connections for instant updates
- Automatic client reconnection
- Graceful error handling

### Scalability
- In-memory data storage (easily extensible to databases)
- Configurable data retention
- Support for multiple concurrent AP connections

## 🛠️ Development

### Adding New Packet Types

1. Add processing method in `ArubaIoTTelemetryHandler`
2. Update the dashboard CSS for new packet type styling
3. Add visualization logic in the JavaScript

### Database Integration

Replace in-memory storage by:
1. Adding database dependencies to `requirements.txt`
2. Updating `ArubaIoTTelemetryHandler` methods
3. Creating database models and migrations

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📝 License

This project is open source and available under the [MIT License](LICENSE).

## 🔗 References

- [Aruba AOS8 IoT Server Example](https://github.com/aruba/aos8-iot-server-example-websocket)
- [Aruba Socket Server](https://github.com/oLuciaZo/ArubaSocketServer)
- [Barnowl Aruba](https://github.com/reelyactive/barnowl-aruba)
- [Flask-SocketIO Documentation](https://flask-socketio.readthedocs.io/)

---

🚀 **Ready to monitor your IoT network with Aruba!** Start the application and watch real-time telemetry data flow through your dashboard.

## 🌐 Deployment to Another Machine

For production deployment on a remote server, we provide multiple deployment options:

### Option 1: Quick Setup Script (Recommended)
```bash
# On Linux/macOS
git clone https://github.com/kzmp/iot-aruba-telemetry.git
cd iot-aruba-telemetry
chmod +x setup.sh
./setup.sh
```

```batch
REM On Windows (using GitHub Desktop)
REM 1. Clone repository with GitHub Desktop
REM 2. Open Command Prompt in project folder
setup_windows.bat
```

### Option 2: Manual Setup
```bash
# 1. Clone repository
git clone https://github.com/kzmp/iot-aruba-telemetry.git
cd iot-aruba-telemetry

# 2. Create virtual environment
python3 -m venv .venv
source .venv/bin/activate  # Linux/macOS
# or .venv\Scripts\activate  # Windows

# 3. Install dependencies
pip install -r requirements.txt

# 4. Configure environment
cp .env.example .env
# Edit .env with your settings

# 5. Open firewall ports 9090 and 9191

# 6. Run the application
python app.py
```

### Option 3: Docker Deployment
```bash
# Clone and build
git clone https://github.com/kzmp/iot-aruba-telemetry.git
cd iot-aruba-telemetry
docker build -t aruba-iot .

# Run container
docker run -d -p 9090:9090 -p 9191:9191 \
  -e ARUBA_AUTH_TOKENS=your-secure-token \
  --name aruba-iot aruba-iot
```

### Remote Access URLs
After deployment, your Aruba controllers can connect using:
```
WebSocket: ws://YOUR_SERVER_IP:9191/aruba?token=YOUR_TOKEN
Dashboard: http://YOUR_SERVER_IP:9090
```

**📖 For detailed deployment instructions, see: [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)**

## 🔐 Security & Authentication
