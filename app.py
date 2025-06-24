#!/usr/bin/env python3
"""
Aruba IoT Telemetry WebSocket Server
Receives IoT telemetry data from Aruba access points including:
- Bluetooth Low Energy (BLE) packets
- EnOcean Alliance packets  
- WiFi packets
For real-time location and sensing applications.
"""

import asyncio
import json
import logging
import os
from datetime import datetime, timezone
from typing import Dict, Any, List

from flask import Flask, render_template, request
from flask_socketio import SocketIO, emit
import websockets
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__)
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'your-secret-key-here')

# Initialize SocketIO
socketio = SocketIO(app, cors_allowed_origins="*", async_mode='threading')

class ArubaIoTTelemetryHandler:
    """Handler for processing Aruba IoT telemetry data"""
    
    def __init__(self):
        self.connected_clients = set()
        self.telemetry_data = []
        self.device_registry = {}
        self.ble_analytics = {
            'reporter_stats': {},  # Access point statistics
            'device_stats': {},    # Device statistics
            'proximity_map': {},   # Device-to-AP proximity mapping
            'signal_strength': {}  # Signal strength trends
        }
        
    def process_ble_packet(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Process Bluetooth Low Energy packet data"""
        device_id = data.get('deviceId', 'unknown')
        mac_address = data.get('macAddress', '')
        access_point = data.get('accessPoint', '')
        rssi = data.get('rssi', 0)
        timestamp = datetime.now(timezone.utc).isoformat()
        
        processed = {
            'type': 'ble',
            'timestamp': timestamp,
            'device_id': device_id,
            'mac_address': mac_address,
            'rssi': rssi,
            'manufacturer_data': data.get('manufacturerData', ''),
            'service_uuids': data.get('serviceUuids', []),
            'location': data.get('location', {}),
            'access_point': access_point,
            'reporter': access_point,  # The AP that reported this device
            'reported': device_id      # The device being reported
        }
        
        # Update BLE analytics
        self._update_ble_analytics(device_id, access_point, rssi, timestamp, mac_address)
        
        return processed
    
    def process_enocean_packet(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Process EnOcean Alliance packet data"""
        processed = {
            'type': 'enocean',
            'timestamp': datetime.now(timezone.utc).isoformat(),
            'device_id': data.get('deviceId', 'unknown'),
            'eep': data.get('eep', ''),
            'payload': data.get('payload', ''),
            'rssi': data.get('rssi', 0),
            'location': data.get('location', {}),
            'access_point': data.get('accessPoint', '')
        }
        return processed
    
    def process_wifi_packet(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Process WiFi packet data"""
        processed = {
            'type': 'wifi',
            'timestamp': datetime.now(timezone.utc).isoformat(),
            'device_id': data.get('deviceId', 'unknown'),
            'mac_address': data.get('macAddress', ''),
            'ssid': data.get('ssid', ''),
            'rssi': data.get('rssi', 0),
            'channel': data.get('channel', 0),
            'location': data.get('location', {}),
            'access_point': data.get('accessPoint', '')
        }
        return processed
    
    def process_telemetry(self, raw_data: str) -> Dict[str, Any]:
        """Process incoming telemetry data"""
        try:
            data = json.loads(raw_data)
            packet_type = data.get('type', '').lower()
            
            if packet_type == 'ble' or 'bluetooth' in packet_type:
                processed = self.process_ble_packet(data)
            elif packet_type == 'enocean':
                processed = self.process_enocean_packet(data)
            elif packet_type == 'wifi':
                processed = self.process_wifi_packet(data)
            else:
                # Generic processing for unknown packet types
                processed = {
                    'type': packet_type or 'unknown',
                    'timestamp': datetime.now(timezone.utc).isoformat(),
                    'raw_data': data,
                    'access_point': data.get('accessPoint', '')
                }
            
            # Store in memory (in production, use a proper database)
            self.telemetry_data.append(processed)
            
            # Keep only last 1000 entries
            if len(self.telemetry_data) > 1000:
                self.telemetry_data = self.telemetry_data[-1000:]
            
            # Update device registry
            device_id = processed.get('device_id')
            if device_id and device_id != 'unknown':
                self.device_registry[device_id] = {
                    'last_seen': processed['timestamp'],
                    'type': processed['type'],
                    'access_point': processed.get('access_point', '')
                }
            
            logger.info(f"Processed {packet_type} packet from {device_id}")
            return processed
            
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse JSON: {e}")
            return None
        except Exception as e:
            logger.error(f"Error processing telemetry: {e}")
            return None

    def _update_ble_analytics(self, device_id: str, access_point: str, rssi: int, timestamp: str, mac_address: str):
        """Update BLE analytics data"""
        # Update reporter (AP) statistics
        if access_point not in self.ble_analytics['reporter_stats']:
            self.ble_analytics['reporter_stats'][access_point] = {
                'devices_seen': set(),
                'total_packets': 0,
                'avg_rssi': 0,
                'rssi_readings': [],
                'first_seen': timestamp,
                'last_seen': timestamp
            }
        
        ap_stats = self.ble_analytics['reporter_stats'][access_point]
        ap_stats['devices_seen'].add(device_id)
        ap_stats['total_packets'] += 1
        ap_stats['rssi_readings'].append(rssi)
        ap_stats['avg_rssi'] = sum(ap_stats['rssi_readings']) / len(ap_stats['rssi_readings'])
        ap_stats['last_seen'] = timestamp
        
        # Keep only last 100 RSSI readings per AP
        if len(ap_stats['rssi_readings']) > 100:
            ap_stats['rssi_readings'] = ap_stats['rssi_readings'][-100:]
        
        # Update device (reported) statistics
        if device_id not in self.ble_analytics['device_stats']:
            self.ble_analytics['device_stats'][device_id] = {
                'reporters': set(),
                'total_packets': 0,
                'best_rssi': rssi,
                'worst_rssi': rssi,
                'avg_rssi': rssi,
                'rssi_readings': [],
                'mac_address': mac_address,
                'first_seen': timestamp,
                'last_seen': timestamp,
                'primary_reporter': access_point
            }
        
        device_stats = self.ble_analytics['device_stats'][device_id]
        device_stats['reporters'].add(access_point)
        device_stats['total_packets'] += 1
        device_stats['rssi_readings'].append(rssi)
        device_stats['best_rssi'] = max(device_stats['best_rssi'], rssi)
        device_stats['worst_rssi'] = min(device_stats['worst_rssi'], rssi)
        device_stats['avg_rssi'] = sum(device_stats['rssi_readings']) / len(device_stats['rssi_readings'])
        device_stats['last_seen'] = timestamp
        
        # Update primary reporter (AP with best average signal)
        if len(device_stats['rssi_readings']) > 5:  # Only after some readings
            # Find AP with best average RSSI for this device
            best_ap = access_point
            best_avg = rssi
            for ap in device_stats['reporters']:
                if ap in self.ble_analytics['proximity_map'].get(device_id, {}):
                    ap_avg = self.ble_analytics['proximity_map'][device_id][ap]['avg_rssi']
                    if ap_avg > best_avg:
                        best_avg = ap_avg
                        best_ap = ap
            device_stats['primary_reporter'] = best_ap
        
        # Keep only last 100 RSSI readings per device
        if len(device_stats['rssi_readings']) > 100:
            device_stats['rssi_readings'] = device_stats['rssi_readings'][-100:]
        
        # Update proximity mapping
        if device_id not in self.ble_analytics['proximity_map']:
            self.ble_analytics['proximity_map'][device_id] = {}
        
        if access_point not in self.ble_analytics['proximity_map'][device_id]:
            self.ble_analytics['proximity_map'][device_id][access_point] = {
                'rssi_readings': [],
                'avg_rssi': rssi,
                'packet_count': 0,
                'first_seen': timestamp,
                'last_seen': timestamp
            }
        
        proximity_data = self.ble_analytics['proximity_map'][device_id][access_point]
        proximity_data['rssi_readings'].append(rssi)
        proximity_data['avg_rssi'] = sum(proximity_data['rssi_readings']) / len(proximity_data['rssi_readings'])
        proximity_data['packet_count'] += 1
        proximity_data['last_seen'] = timestamp
        
        # Keep only last 50 RSSI readings per device-AP pair
        if len(proximity_data['rssi_readings']) > 50:
            proximity_data['rssi_readings'] = proximity_data['rssi_readings'][-50:]

# Initialize telemetry handler
telemetry_handler = ArubaIoTTelemetryHandler()

# WebSocket server for receiving data from Aruba APs
async def aruba_websocket_server(websocket, path):
    """WebSocket server to receive data from Aruba access points with authentication"""
    client_address = websocket.remote_address
    logger.info(f"New connection attempt from {client_address[0]}:{client_address[1]} on path: {path}")
    
    # Authentication: Check for token in query parameters or headers
    # Note: '1234' is a temporary token for development/testing purposes only
    valid_tokens = os.getenv('ARUBA_AUTH_TOKENS', '1234,admin,aruba-iot').split(',')
    token = None
    
    # Try to get token from query parameters first
    if '?' in path:
        from urllib.parse import parse_qs, urlparse
        parsed_url = urlparse(path)
        query_params = parse_qs(parsed_url.query)
        token = query_params.get('token', [None])[0]
    
    # If no token in query, check WebSocket headers
    if not token:
        auth_header = websocket.request_headers.get('Authorization')
        if auth_header and auth_header.startswith('Bearer '):
            token = auth_header[7:]  # Remove 'Bearer ' prefix
        else:
            # Check for custom token header
            token = websocket.request_headers.get('X-Auth-Token')
    
    # Validate token
    if not token or token not in valid_tokens:
        logger.warning(f"Authentication failed for {client_address[0]} - Invalid or missing token")
        await websocket.close(code=1008, reason="Authentication required")
        return
    
    logger.info(f"✅ Authenticated Aruba AP connection from {client_address[0]}:{client_address[1]}")
    
    # Send welcome message to confirm connection
    try:
        await websocket.send(json.dumps({
            "status": "authenticated",
            "message": "Aruba IoT Telemetry Server Ready - Authentication Successful",
            "timestamp": datetime.now().isoformat(),
            "server_version": "1.0",
            "client_ip": client_address[0]
        }))
        logger.info(f"Sent authenticated welcome message to {client_address}")
    except Exception as e:
        logger.error(f"Failed to send welcome message: {e}")
        return
    
    try:
        async for message in websocket:
            logger.info(f"Received message from {client_address[0]}: {message[:200]}...")
            
            # Process the telemetry data
            processed_data = telemetry_handler.process_telemetry(message)
            
            if processed_data:
                # Store the data for the web interface
                logger.info(f"Successfully processed {processed_data['type']} packet from {processed_data.get('device_id', 'unknown')}")
                
                # Send acknowledgment back to Aruba AP
                try:
                    ack_response = json.dumps({
                        "status": "received",
                        "packet_type": processed_data['type'],
                        "timestamp": datetime.now().isoformat()
                    })
                    await websocket.send(ack_response)
                except Exception as e:
                    logger.error(f"Failed to send acknowledgment: {e}")
            else:
                logger.warning(f"Failed to process message from {client_address}")
            
    except websockets.exceptions.ConnectionClosed:
        logger.info(f"Aruba AP {client_address[0]} disconnected")
    except websockets.exceptions.ConnectionClosedError:
        logger.info(f"Aruba AP {client_address[0]} connection closed unexpectedly")
    except Exception as e:
        logger.error(f"Error in WebSocket connection {client_address}: {e}", exc_info=True)

# Flask routes
@app.route('/')
def dashboard():
    """Main dashboard page"""
    return render_template('dashboard.html')

@app.route('/api/devices')
def get_devices():
    """API endpoint to get device registry"""
    return telemetry_handler.device_registry

@app.route('/api/telemetry')
def get_telemetry():
    """API endpoint to get recent telemetry data"""
    limit = request.args.get('limit', 100, type=int)
    return telemetry_handler.telemetry_data[-limit:]

@app.route('/api/stats')
def get_stats():
    """API endpoint to get statistics"""
    total_packets = len(telemetry_handler.telemetry_data)
    ble_count = sum(1 for data in telemetry_handler.telemetry_data if data.get('type') == 'ble')
    wifi_count = sum(1 for data in telemetry_handler.telemetry_data if data.get('type') == 'wifi')
    enocean_count = sum(1 for data in telemetry_handler.telemetry_data if data.get('type') == 'enocean')
    
    return {
        'total_packets': total_packets,
        'ble_packets': ble_count,
        'wifi_packets': wifi_count,
        'enocean_packets': enocean_count,
        'total_devices': len(telemetry_handler.device_registry),
        'connected_clients': len(telemetry_handler.connected_clients)
    }

@app.route('/api/ble/reporters')
def get_ble_reporters():
    """API endpoint to get BLE reporter (Access Point) statistics"""
    reporters = {}
    for ap_name, stats in telemetry_handler.ble_analytics['reporter_stats'].items():
        reporters[ap_name] = {
            'name': ap_name,
            'devices_seen': len(stats['devices_seen']),
            'total_packets': stats['total_packets'],
            'avg_rssi': round(stats['avg_rssi'], 1),
            'first_seen': stats['first_seen'],
            'last_seen': stats['last_seen']
        }
    return reporters

@app.route('/api/ble/devices')
def get_ble_devices():
    """API endpoint to get BLE device (reported) statistics"""
    devices = {}
    for device_id, stats in telemetry_handler.ble_analytics['device_stats'].items():
        devices[device_id] = {
            'device_id': device_id,
            'mac_address': stats['mac_address'],
            'reporters_count': len(stats['reporters']),
            'reporters': list(stats['reporters']),
            'total_packets': stats['total_packets'],
            'best_rssi': stats['best_rssi'],
            'worst_rssi': stats['worst_rssi'],
            'avg_rssi': round(stats['avg_rssi'], 1),
            'primary_reporter': stats['primary_reporter'],
            'first_seen': stats['first_seen'],
            'last_seen': stats['last_seen']
        }
    return devices

@app.route('/api/ble/proximity')
def get_ble_proximity():
    """API endpoint to get BLE proximity mapping"""
    proximity = {}
    for device_id, ap_data in telemetry_handler.ble_analytics['proximity_map'].items():
        proximity[device_id] = {}
        for ap_name, prox_data in ap_data.items():
            proximity[device_id][ap_name] = {
                'avg_rssi': round(prox_data['avg_rssi'], 1),
                'packet_count': prox_data['packet_count'],
                'first_seen': prox_data['first_seen'],
                'last_seen': prox_data['last_seen']
            }
    return proximity

@app.route('/api/ble/analytics')
def get_ble_analytics():
    """API endpoint to get comprehensive BLE analytics"""
    analytics = {
        'summary': {
            'total_devices': len(telemetry_handler.ble_analytics['device_stats']),
            'total_reporters': len(telemetry_handler.ble_analytics['reporter_stats']),
            'total_proximity_pairs': sum(len(ap_data) for ap_data in telemetry_handler.ble_analytics['proximity_map'].values())
        },
        'top_reporters': [],
        'top_devices': [],
        'signal_quality': {
            'excellent': 0,  # RSSI > -50
            'good': 0,       # RSSI -50 to -70
            'fair': 0,       # RSSI -70 to -85
            'poor': 0        # RSSI < -85
        }
    }
    
    # Get top reporters by packet count
    for ap_name, stats in sorted(telemetry_handler.ble_analytics['reporter_stats'].items(), 
                                key=lambda x: x[1]['total_packets'], reverse=True)[:5]:
        analytics['top_reporters'].append({
            'name': ap_name,
            'devices_seen': len(stats['devices_seen']),
            'total_packets': stats['total_packets'],
            'avg_rssi': round(stats['avg_rssi'], 1)
        })
    
    # Get top devices by packet count
    for device_id, stats in sorted(telemetry_handler.ble_analytics['device_stats'].items(),
                                  key=lambda x: x[1]['total_packets'], reverse=True)[:10]:
        analytics['top_devices'].append({
            'device_id': device_id,
            'mac_address': stats['mac_address'],
            'total_packets': stats['total_packets'],
            'avg_rssi': round(stats['avg_rssi'], 1),
            'primary_reporter': stats['primary_reporter']
        })
    
    # Calculate signal quality distribution
    for device_stats in telemetry_handler.ble_analytics['device_stats'].values():
        avg_rssi = device_stats['avg_rssi']
        if avg_rssi > -50:
            analytics['signal_quality']['excellent'] += 1
        elif avg_rssi > -70:
            analytics['signal_quality']['good'] += 1
        elif avg_rssi > -85:
            analytics['signal_quality']['fair'] += 1
        else:
            analytics['signal_quality']['poor'] += 1
    
    return analytics

# SocketIO events
@socketio.on('connect')
def handle_connect():
    """Handle client connection"""
    client_id = request.sid
    telemetry_handler.connected_clients.add(client_id)
    logger.info(f"Web client {client_id} connected")
    
    # Send recent telemetry data to new client
    recent_data = telemetry_handler.telemetry_data[-10:]
    for data in recent_data:
        emit('telemetry_update', data)

@socketio.on('disconnect')
def handle_disconnect():
    """Handle client disconnection"""
    client_id = request.sid
    telemetry_handler.connected_clients.discard(client_id)
    logger.info(f"Web client {client_id} disconnected")

@socketio.on('request_stats')
def handle_stats_request():
    """Handle stats request from client"""
    stats = get_stats()
    emit('stats_update', stats)

def start_aruba_websocket_server():
    """Start the WebSocket server for Aruba APs"""
    host = os.getenv('ARUBA_WS_HOST', '0.0.0.0')
    port = int(os.getenv('ARUBA_WS_PORT', 9191))
    
    logger.info(f"Starting Aruba WebSocket server on {host}:{port}")
    logger.info(f"WebSocket server will accept connections on ws://{host}:{port}/aruba")
    
    # Create server with proper SSL context if needed
    start_server = websockets.serve(
        aruba_websocket_server, 
        host, 
        port,
        # Add ping/pong for connection health
        ping_interval=30,
        ping_timeout=10,
        # Allow larger message sizes for telemetry data
        max_size=1024*1024,  # 1MB
        # Compression for better performance
        compression=None
    )
    return start_server

if __name__ == '__main__':
    # Start WebSocket server for Aruba APs in background
    import threading
    
    def run_websocket_server():
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        start_server = start_aruba_websocket_server()
        loop.run_until_complete(start_server)
        loop.run_forever()
    
    ws_thread = threading.Thread(target=run_websocket_server, daemon=True)
    ws_thread.start()
    
    # Start Flask-SocketIO server
    host = os.getenv('FLASK_HOST', '0.0.0.0')
    port = int(os.getenv('FLASK_PORT', 5000))
    debug = os.getenv('FLASK_DEBUG', 'False').lower() == 'true'
    
    logger.info(f"Starting Flask server on {host}:{port}")
    socketio.run(app, host=host, port=port, debug=debug, allow_unsafe_werkzeug=True)
