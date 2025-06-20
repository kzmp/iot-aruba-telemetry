<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# Aruba IoT Telemetry Web Application

This is a Python web application designed to receive IoT telemetry data from Aruba network infrastructure including:
- Bluetooth Low Energy (BLE) packets
- EnOcean Alliance packets  
- WiFi packets

## Architecture Guidelines

- Use Flask with SocketIO for real-time web communication
- Use WebSockets for receiving data from Aruba access points
- Follow asyncio patterns for concurrent connections
- Implement proper error handling and logging
- Use modern web standards for the dashboard UI

## Code Style Preferences

- Follow PEP 8 Python style guidelines
- Use type hints where appropriate
- Include comprehensive docstrings for classes and functions
- Implement proper exception handling
- Use environment variables for configuration

## Key Components

- `app.py`: Main Flask application with WebSocket server
- `templates/dashboard.html`: Real-time dashboard interface
- `test_client.py`: Simulator for testing Aruba AP connections
- `.env`: Environment configuration

## Development Notes

- The application listens on port 9090 for web interface
- WebSocket server for Aruba APs runs on port 9191
- Dashboard provides real-time visualization of received telemetry
- Supports multiple packet types with proper classification
- Includes device registry and statistics tracking
