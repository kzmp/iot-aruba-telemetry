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
        logger.info("process_ble_packet: Processing BLE packet")
        
        device_id = data.get('deviceId', 'unknown')
        logger.info(f"process_ble_packet: Device ID: {device_id}")
        
        mac_address = data.get('macAddress', '')
        logger.info(f"process_ble_packet: MAC Address: {mac_address or 'Not provided'}")
        
        access_point = data.get('accessPoint', '')
        logger.info(f"process_ble_packet: Access Point: {access_point or 'Not provided'}")
        
        rssi = data.get('rssi', 0)
        logger.info(f"process_ble_packet: RSSI: {rssi}")
        
        timestamp = datetime.now(timezone.utc).isoformat()
        logger.info(f"process_ble_packet: Timestamp: {timestamp}")
        
        # Log any manufacturer data and service UUIDs
        manufacturer_data = data.get('manufacturerData', '')
        logger.info(f"process_ble_packet: Manufacturer Data: {manufacturer_data[:20] + '...' if len(str(manufacturer_data)) > 20 else manufacturer_data or 'None'}")
        
        service_uuids = data.get('serviceUuids', [])
        logger.info(f"process_ble_packet: Service UUIDs: {service_uuids or 'None'}")
        
        # Check if location data is available
        location = data.get('location', {})
        if location:
            logger.info(f"process_ble_packet: Location data present: {list(location.keys())}")
        else:
            logger.info("process_ble_packet: No location data present")
        
        processed = {
            'type': 'ble',
            'timestamp': timestamp,
            'device_id': device_id,
            'mac_address': mac_address,
            'rssi': rssi,
            'manufacturer_data': manufacturer_data,
            'service_uuids': service_uuids,
            'location': location,
            'access_point': access_point,
            'reporter': access_point,  # The AP that reported this device
            'reported': device_id      # The device being reported
        }
        
        logger.info("process_ble_packet: Updating BLE analytics")
        # Update BLE analytics
        self._update_ble_analytics(device_id, access_point, rssi, timestamp, mac_address)
        logger.info("process_ble_packet: BLE packet processing complete")
        
        return processed
    
    def process_enocean_packet(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Process EnOcean Alliance packet data"""
        logger.info("process_enocean_packet: Processing EnOcean packet")
        
        device_id = data.get('deviceId', 'unknown')
        logger.info(f"process_enocean_packet: Device ID: {device_id}")
        
        eep = data.get('eep', '')
        logger.info(f"process_enocean_packet: EEP Profile: {eep or 'Not provided'}")
        
        payload = data.get('payload', '')
        logger.info(f"process_enocean_packet: Payload: {payload[:20] + '...' if len(str(payload)) > 20 else payload or 'None'}")
        
        rssi = data.get('rssi', 0)
        logger.info(f"process_enocean_packet: RSSI: {rssi}")
        
        access_point = data.get('accessPoint', '')
        logger.info(f"process_enocean_packet: Access Point: {access_point or 'Not provided'}")
        
        # Check if location data is available
        location = data.get('location', {})
        if location:
            logger.info(f"process_enocean_packet: Location data present: {list(location.keys())}")
        else:
            logger.info("process_enocean_packet: No location data present")
        
        timestamp = datetime.now(timezone.utc).isoformat()
        logger.info(f"process_enocean_packet: Timestamp: {timestamp}")
        
        processed = {
            'type': 'enocean',
            'timestamp': timestamp,
            'device_id': device_id,
            'eep': eep,
            'payload': payload,
            'rssi': rssi,
            'location': location,
            'access_point': access_point
        }
        
        logger.info("process_enocean_packet: EnOcean packet processing complete")
        return processed
    
    def process_wifi_packet(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Process WiFi packet data"""
        logger.info("process_wifi_packet: Processing WiFi packet")
        
        device_id = data.get('deviceId', 'unknown')
        logger.info(f"process_wifi_packet: Device ID: {device_id}")
        
        mac_address = data.get('macAddress', '')
        logger.info(f"process_wifi_packet: MAC Address: {mac_address or 'Not provided'}")
        
        ssid = data.get('ssid', '')
        logger.info(f"process_wifi_packet: SSID: {ssid or 'Not provided'}")
        
        rssi = data.get('rssi', 0)
        logger.info(f"process_wifi_packet: RSSI: {rssi}")
        
        channel = data.get('channel', 0)
        logger.info(f"process_wifi_packet: Channel: {channel}")
        
        access_point = data.get('accessPoint', '')
        logger.info(f"process_wifi_packet: Access Point: {access_point or 'Not provided'}")
        
        # Check if location data is available
        location = data.get('location', {})
        if location:
            logger.info(f"process_wifi_packet: Location data present: {list(location.keys())}")
        else:
            logger.info("process_wifi_packet: No location data present")
        
        timestamp = datetime.now(timezone.utc).isoformat()
        logger.info(f"process_wifi_packet: Timestamp: {timestamp}")
        
        processed = {
            'type': 'wifi',
            'timestamp': timestamp,
            'device_id': device_id,
            'mac_address': mac_address,
            'ssid': ssid,
            'rssi': rssi,
            'channel': channel,
            'location': location,
            'access_point': access_point
        }
        
        logger.info("process_wifi_packet: WiFi packet processing complete")
        return processed
    
    def process_telemetry(self, raw_data) -> Dict[str, Any]:
        """Process incoming telemetry data"""
        logger.info("process_telemetry: Starting telemetry processing")
        logger.info(f"process_telemetry: Input data type: {type(raw_data)}")
        
        # Handle different data types (bytes vs string)
        if isinstance(raw_data, bytes):
            logger.info(f"process_telemetry: Processing binary data of {len(raw_data)} bytes")
            
            # Add hexdump of first 128 bytes for debugging binary data
            logger.info("process_telemetry: First 128 bytes hexdump:")
            hex_lines = self._hex_dump(raw_data[:128])
            for line in hex_lines:
                logger.info(f"process_telemetry: {line}")
                
            # Try different encodings if UTF-8 fails
            try:
                # Try UTF-8 first (most common)
                decoded_data = raw_data.decode('utf-8')
                logger.info("process_telemetry: Successfully decoded data using UTF-8")
            except UnicodeDecodeError:
                logger.info("process_telemetry: UTF-8 decoding failed, trying Latin-1")
                try:
                    # Try Latin-1 which can decode any byte
                    decoded_data = raw_data.decode('latin-1')
                    logger.warning("process_telemetry: Received non-UTF8 data, falling back to latin-1 encoding")
                except Exception as e:
                    logger.error(f"process_telemetry: Could not decode binary data with any encoding: {e}")
                    return None
        else:
            # Already a string
            decoded_data = raw_data
            logger.info(f"process_telemetry: Processing string data of length {len(decoded_data)}")
            
        # Log a safe preview of the data
        if len(decoded_data) > 100:
            logger.info(f"process_telemetry: Data preview: {decoded_data[:100]}...")
        else:
            logger.info(f"process_telemetry: Data: {decoded_data}")
            
        # Check for common JSON syntax issues
        if decoded_data:
            # Remove potential BOM at the beginning of the string
            if decoded_data.startswith('\ufeff'):
                logger.warning("process_telemetry: Found BOM at start of string, removing it")
                decoded_data = decoded_data[1:]
                
            # Check for unescaped control characters
            control_chars = [ord(c) for c in decoded_data if ord(c) < 32 and c not in '\r\n\t']
            if control_chars:
                logger.warning(f"process_telemetry: Found {len(control_chars)} unescaped control characters in data")
                for i, char_code in enumerate(control_chars[:10]):  # Show first 10 only
                    char_pos = decoded_data.find(chr(char_code))
                    logger.warning(f"process_telemetry: Control char 0x{char_code:02x} at position {char_pos}")
                    
            # Check for basic structure
            stripped = decoded_data.strip()
            if not (stripped.startswith('{') and stripped.endswith('}')) and \
               not (stripped.startswith('[') and stripped.endswith(']')):
                logger.warning("process_telemetry: Data doesn't appear to have valid JSON structure")
                logger.warning(f"process_telemetry: Starts with: '{stripped[:10]}', Ends with: '{stripped[-10:]}'")
                
        try:
            # Try to parse the JSON
            logger.info("process_telemetry: Attempting to parse JSON")
            try:
                data = json.loads(decoded_data)
                logger.info(f"process_telemetry: JSON parsing successful, keys: {list(data.keys())}")
            except json.JSONDecodeError as initial_error:
                # Try to sanitize and parse again
                logger.warning(f"process_telemetry: Initial JSON parsing failed: {initial_error}")
                sanitized_data = self._sanitize_json_string(decoded_data)
                
                if sanitized_data != decoded_data:
                    logger.info("process_telemetry: Data was sanitized, attempting to parse again")
                    try:
                        data = json.loads(sanitized_data)
                        logger.info(f"process_telemetry: JSON parsing successful after sanitization, keys: {list(data.keys())}")
                    except json.JSONDecodeError:
                        # If it still fails, raise the original error for better debugging
                        logger.error("process_telemetry: JSON parsing failed even after sanitization")
                        raise initial_error
                else:
                    # No changes were made during sanitization, re-raise the original error
                    raise
            
            packet_type = data.get('type', '').lower()
            logger.info(f"process_telemetry: Detected packet type: '{packet_type}'")
            
            if packet_type == 'ble' or 'bluetooth' in packet_type:
                logger.info(f"process_telemetry: Processing as BLE packet")
                processed = self.process_ble_packet(data)
                logger.info(f"process_telemetry: BLE packet processed, device_id: {processed.get('device_id', 'unknown')}")
            elif packet_type == 'enocean':
                logger.info(f"process_telemetry: Processing as EnOcean packet")
                processed = self.process_enocean_packet(data)
                logger.info(f"process_telemetry: EnOcean packet processed, device_id: {processed.get('device_id', 'unknown')}")
            elif packet_type == 'wifi':
                logger.info(f"process_telemetry: Processing as WiFi packet")
                processed = self.process_wifi_packet(data)
                logger.info(f"process_telemetry: WiFi packet processed, device_id: {processed.get('device_id', 'unknown')}")
            else:
                # Generic processing for unknown packet types
                logger.info(f"process_telemetry: Unknown packet type '{packet_type}', using generic processing")
                processed = {
                    'type': packet_type or 'unknown',
                    'timestamp': datetime.now(timezone.utc).isoformat(),
                    'raw_data': data,
                    'access_point': data.get('accessPoint', '')
                }
                logger.info(f"process_telemetry: Generic packet processed with type: {processed['type']}")
            
            # Store in memory (in production, use a proper database)
            logger.info("process_telemetry: Adding processed packet to telemetry_data")
            self.telemetry_data.append(processed)
            
            # Keep only last 1000 entries
            if len(self.telemetry_data) > 1000:
                logger.info("process_telemetry: Trimming telemetry_data to last 1000 entries")
                self.telemetry_data = self.telemetry_data[-1000:]
            
            # Update device registry
            device_id = processed.get('device_id')
            if device_id and device_id != 'unknown':
                logger.info(f"process_telemetry: Updating device registry for device_id: {device_id}")
                self.device_registry[device_id] = {
                    'last_seen': processed['timestamp'],
                    'type': processed['type'],
                    'access_point': processed.get('access_point', '')
                }
                logger.info(f"process_telemetry: Device registry updated, total devices: {len(self.device_registry)}")
            else:
                logger.info("process_telemetry: No valid device_id found for device registry update")
            
            logger.info(f"process_telemetry: Successfully processed {packet_type} packet from {device_id}")
            return processed
            
        except json.JSONDecodeError as e:
            logger.error(f"process_telemetry: Failed to parse JSON: {e}")
            
            # Log the full raw data for debugging
            logger.error(f"process_telemetry: Raw data length: {len(decoded_data)} characters")
            
            # For better visibility, log chunks of data
            chunk_size = 1000
            for i in range(0, len(decoded_data), chunk_size):
                chunk = decoded_data[i:i+chunk_size]
                logger.error(f"process_telemetry: Raw data chunk {i//chunk_size + 1}: {chunk}")
            
            # For binary/non-printable character detection, add hexdump-style logging
            logger.error("process_telemetry: Hexdump of problematic area:")
            
            # Find the problematic area based on the error message
            error_msg = str(e)
            error_pos = None
            import re
            match = re.search(r'char (\d+)', error_msg)
            if match:
                error_pos = int(match.group(1))
                
            if error_pos is not None:
                # Get data around the error position
                start_pos = max(0, error_pos - 50)
                end_pos = min(len(decoded_data), error_pos + 50)
                error_context = decoded_data[start_pos:end_pos]
                
                # Log hexdump of the area
                hex_lines = []
                for i in range(0, len(error_context), 16):
                    chunk = error_context[i:i+16]
                    hex_values = ' '.join([f'{ord(c):02x}' for c in chunk])
                    ascii_values = ''.join([c if 32 <= ord(c) < 127 else '.' for c in chunk])
                    position = start_pos + i
                    marker = ' <<<< ERROR POSITION' if start_pos + i <= error_pos < start_pos + i + 16 else ''
                    hex_lines.append(f"{position:08x}: {hex_values.ljust(48)} | {ascii_values} {marker}")
                
                for line in hex_lines:
                    logger.error(f"process_telemetry: {line}")
            
            return None
        except Exception as e:
            logger.error(f"process_telemetry: Error processing telemetry: {e}")
            logger.error(f"process_telemetry: Exception type: {type(e).__name__}")
            import traceback
            logger.error(f"process_telemetry: Traceback: {traceback.format_exc()}")
            return None

    def _update_ble_analytics(self, device_id: str, access_point: str, rssi: int, timestamp: str, mac_address: str):
        """Update BLE analytics data"""
        logger.info(f"_update_ble_analytics: Updating analytics for device {device_id} from AP {access_point}")
        
        # Update reporter (AP) statistics
        if access_point not in self.ble_analytics['reporter_stats']:
            logger.info(f"_update_ble_analytics: First time seeing AP {access_point}, initializing stats")
            self.ble_analytics['reporter_stats'][access_point] = {
                'devices_seen': set(),
                'total_packets': 0,
                'avg_rssi': 0,
                'rssi_readings': [],
                'first_seen': timestamp,
                'last_seen': timestamp
            }
        
        ap_stats = self.ble_analytics['reporter_stats'][access_point]
        
        # Update AP statistics
        prev_device_count = len(ap_stats['devices_seen'])
        ap_stats['devices_seen'].add(device_id)
        
        if len(ap_stats['devices_seen']) > prev_device_count:
            logger.info(f"_update_ble_analytics: AP {access_point} detected a new device (total: {len(ap_stats['devices_seen'])})")
        
        ap_stats['total_packets'] += 1
        ap_stats['rssi_readings'].append(rssi)
        ap_stats['avg_rssi'] = sum(ap_stats['rssi_readings']) / len(ap_stats['rssi_readings'])
        ap_stats['last_seen'] = timestamp
        
        logger.info(f"_update_ble_analytics: AP {access_point} stats updated - "
                   f"packets: {ap_stats['total_packets']}, "
                   f"devices: {len(ap_stats['devices_seen'])}, "
                   f"avg RSSI: {ap_stats['avg_rssi']:.2f}")
        
        # Keep only last 100 RSSI readings per AP
        if len(ap_stats['rssi_readings']) > 100:
            logger.info(f"_update_ble_analytics: Trimming RSSI history for AP {access_point}")
            ap_stats['rssi_readings'] = ap_stats['rssi_readings'][-100:]
        
        # Update device (reported) statistics
        if device_id not in self.ble_analytics['device_stats']:
            logger.info(f"_update_ble_analytics: First time seeing device {device_id}, initializing stats")
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
        
        # Update device statistics
        prev_reporter_count = len(device_stats['reporters'])
        device_stats['reporters'].add(access_point)
        
        if len(device_stats['reporters']) > prev_reporter_count:
            logger.info(f"_update_ble_analytics: Device {device_id} detected by a new AP (total: {len(device_stats['reporters'])})")
        
        device_stats['total_packets'] += 1
        device_stats['rssi_readings'].append(rssi)
        
        # Update RSSI statistics
        old_best_rssi = device_stats['best_rssi']
        old_worst_rssi = device_stats['worst_rssi']
        device_stats['best_rssi'] = max(device_stats['best_rssi'], rssi)
        device_stats['worst_rssi'] = min(device_stats['worst_rssi'], rssi)
        
        if device_stats['best_rssi'] > old_best_rssi:
            logger.info(f"_update_ble_analytics: New best RSSI for device {device_id}: {device_stats['best_rssi']}")
        if device_stats['worst_rssi'] < old_worst_rssi:
            logger.info(f"_update_ble_analytics: New worst RSSI for device {device_id}: {device_stats['worst_rssi']}")
        
        device_stats['avg_rssi'] = sum(device_stats['rssi_readings']) / len(device_stats['rssi_readings'])
        device_stats['last_seen'] = timestamp
        
        logger.info(f"_update_ble_analytics: Device {device_id} stats updated - "
                   f"packets: {device_stats['total_packets']}, "
                   f"APs: {len(device_stats['reporters'])}, "
                   f"avg RSSI: {device_stats['avg_rssi']:.2f}")
        
        # Update primary reporter (AP with best average signal)
        old_primary = device_stats['primary_reporter']
        if len(device_stats['rssi_readings']) > 5:  # Only after some readings
            # Find AP with best average RSSI for this device
            best_ap = access_point
            best_avg = rssi
            logger.info(f"_update_ble_analytics: Evaluating primary reporter for device {device_id}")
            
            for ap in device_stats['reporters']:
                if ap in self.ble_analytics['proximity_map'].get(device_id, {}):
                    ap_avg = self.ble_analytics['proximity_map'][device_id][ap]['avg_rssi']
                    logger.info(f"_update_ble_analytics: AP {ap} has avg RSSI of {ap_avg:.2f} for device {device_id}")
                    if ap_avg > best_avg:
                        best_avg = ap_avg
                        best_ap = ap
                        logger.info(f"_update_ble_analytics: AP {ap} is now best candidate with RSSI {best_avg:.2f}")
            
            device_stats['primary_reporter'] = best_ap
            if old_primary != best_ap:
                logger.info(f"_update_ble_analytics: Primary reporter for device {device_id} changed from {old_primary} to {best_ap}")
        
        # Keep only last 100 RSSI readings per device
        if len(device_stats['rssi_readings']) > 100:
            logger.info(f"_update_ble_analytics: Trimming RSSI history for device {device_id}")
            device_stats['rssi_readings'] = device_stats['rssi_readings'][-100:]
        
        # Update proximity mapping
        if device_id not in self.ble_analytics['proximity_map']:
            logger.info(f"_update_ble_analytics: Initializing proximity map for device {device_id}")
            self.ble_analytics['proximity_map'][device_id] = {}
        
        if access_point not in self.ble_analytics['proximity_map'][device_id]:
            logger.info(f"_update_ble_analytics: First proximity data for device {device_id} with AP {access_point}")
            self.ble_analytics['proximity_map'][device_id][access_point] = {
                'rssi_readings': [],
                'avg_rssi': rssi,
                'packet_count': 0,
                'first_seen': timestamp,
                'last_seen': timestamp
            }
        
        proximity_data = self.ble_analytics['proximity_map'][device_id][access_point]
        proximity_data['rssi_readings'].append(rssi)
        old_avg = proximity_data['avg_rssi']
        proximity_data['avg_rssi'] = sum(proximity_data['rssi_readings']) / len(proximity_data['rssi_readings'])
        proximity_data['packet_count'] += 1
        proximity_data['last_seen'] = timestamp
        
        logger.info(f"_update_ble_analytics: Proximity data updated for device {device_id} with AP {access_point} - "
                  f"avg RSSI: {proximity_data['avg_rssi']:.2f} (was {old_avg:.2f}), "
                  f"packets: {proximity_data['packet_count']}")
        
        # Keep only last 50 RSSI readings per device-AP pair
        if len(proximity_data['rssi_readings']) > 50:
            logger.info(f"_update_ble_analytics: Trimming proximity RSSI history for device {device_id} with AP {access_point}")
            proximity_data['rssi_readings'] = proximity_data['rssi_readings'][-50:]
        
        logger.info(f"_update_ble_analytics: Analytics update complete for device {device_id}")
    
    def _hex_dump(self, data, start_offset=0, highlight_pos=None):
        """Generate a hex dump of binary or string data for debugging
        
        Args:
            data: The data to dump (bytes or string)
            start_offset: The starting offset for position display
            highlight_pos: Optional position to highlight (relative to start_offset)
            
        Returns:
            List of formatted hex dump lines
        """
        if isinstance(data, str):
            data = data.encode('utf-8', errors='replace')
        
        hex_lines = []
        for i in range(0, len(data), 16):
            chunk = data[i:i+16]
            hex_values = ' '.join([f'{b:02x}' for b in chunk])
            ascii_values = ''.join([chr(b) if 32 <= b < 127 else '.' for b in chunk])
            position = start_offset + i
            
            marker = ''
            if highlight_pos is not None and start_offset + i <= highlight_pos < start_offset + i + 16:
                marker = ' <<<< ERROR POSITION'
                
            hex_lines.append(f"{position:08x}: {hex_values.ljust(48)} | {ascii_values} {marker}")
        
        return hex_lines

    def _sanitize_json_string(self, data):
        """Attempt to sanitize a problematic JSON string
        
        Args:
            data: The JSON string to sanitize
            
        Returns:
            Sanitized JSON string
        """
        logger.info("process_telemetry: Attempting to sanitize problematic JSON")
        
        # Remove any leading/trailing whitespace
        data = data.strip()
        
        # Fix common issues:
        
        # 1. Remove any BOM characters
        if data.startswith('\ufeff'):
            data = data[1:]
            logger.info("process_telemetry: Removed BOM character")
            
        # 2. Fix unescaped newlines in strings
        import re
        # This regex finds strings with unescaped newlines and fixes them
        # It's not perfect but helps with common cases
        pattern = r'("(?:[^"\\]|\\.)*?)(\n)([^"]*?")'
        if re.search(pattern, data):
            data = re.sub(pattern, r'\1\\n\3', data)
            logger.info("process_telemetry: Fixed unescaped newlines in strings")
            
        # 3. Fix missing quotes around keys
        # This is a simplified approach - not a complete solution
        unquoted_key_pattern = r'{\s*(\w+)\s*:'
        if re.search(unquoted_key_pattern, data):
            data = re.sub(unquoted_key_pattern, r'{"\1":', data)
            logger.info("process_telemetry: Fixed unquoted keys")
            
        # 4. Try to fix trailing commas
        data = data.replace(',}', '}').replace(',]', ']')
        
        # 5. Replace control characters with their escaped versions
        for i in range(32):
            if i not in (9, 10, 13):  # Tab, LF, CR
                data = data.replace(chr(i), f'\\u{i:04x}')
                
        return data

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
    
    # Default clientID/accessToken for temporary testing purposes
    valid_client_ids = os.getenv('ARUBA_CLIENT_IDS', 'test-client-1,aruba-ap').split(',')
    valid_access_tokens = os.getenv('ARUBA_ACCESS_TOKENS', '1234,admin-token').split(',')
    
    token = None
    client_id = None
    access_token = None
    
    # Try to get authentication info from query parameters first
    if '?' in path:
        from urllib.parse import parse_qs, urlparse
        parsed_url = urlparse(path)
        query_params = parse_qs(parsed_url.query)
        token = query_params.get('token', [None])[0]
        client_id = query_params.get('clientID', [None])[0]
        access_token = query_params.get('accessToken', [None])[0]
    
    # If no token in query, check WebSocket headers
    if not token and not access_token:
        auth_header = websocket.request_headers.get('Authorization')
        if auth_header and auth_header.startswith('Bearer '):
            token = auth_header[7:]  # Remove 'Bearer ' prefix
        else:
            # Check for custom token header
            token = websocket.request_headers.get('X-Auth-Token')
            # Also check for client ID and access token headers
            client_id = websocket.request_headers.get('X-Client-ID')
            access_token = websocket.request_headers.get('X-Access-Token')
    
    # Validate token (supporting multiple auth methods)
    is_authenticated = False
    
    # Method 1: Simple token
    if token and token in valid_tokens:
        is_authenticated = True
        logger.info(f"Client authenticated using token")
    
    # Method 2: ClientID + AccessToken pair
    if client_id and access_token:
        if client_id in valid_client_ids and access_token in valid_access_tokens:
            is_authenticated = True
            logger.info(f"Client authenticated using clientID/accessToken: {client_id}")
    
    if not is_authenticated:
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
            try:
                # Log received message, safely truncating if necessary
                if isinstance(message, bytes):
                    logger.info(f"Received binary message from {client_address[0]} ({len(message)} bytes)")
                else:
                    logger.info(f"Received message from {client_address[0]}: {message[:200]}...")
            except:
                logger.info(f"Received message from {client_address[0]} (unprintable format)")
            
            # Process the telemetry data (now handles bytes or string)
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
        compression=None,
        # Support for binary messages
        subprotocols=["binary", "json"]
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
