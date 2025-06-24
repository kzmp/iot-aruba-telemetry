#!/usr/bin/env python3
"""
Multi-Protocol Test Client for Aruba IoT Telemetry Server

This client can simulate:
- BLE/iBeacon packets
- WiFi packets
- EnOcean packets

with both JSON and Protocol Buffer encoding
"""

import asyncio
import argparse
import random
import time
import json
import websockets
from datetime import datetime, timezone

# Import the protobuf utilities
import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from protobuf_utils import (
    encode_ibeacon_packet, 
    encode_wifi_packet, 
    encode_enocean_packet
)

class DeviceSimulator:
    """Simulates various IoT devices for testing"""
    
    def __init__(self, ap_name="AP-Simulator"):
        self.ap_name = ap_name
        self.device_macs = [
            "aa:bb:cc:dd:ee:01",
            "aa:bb:cc:dd:ee:02", 
            "aa:bb:cc:dd:ee:03",
            "11:22:33:44:55:01",
            "11:22:33:44:55:02"
        ]
        # Common WiFi SSIDs
        self.ssids = [
            "Guest WiFi", 
            "Corp-Network", 
            "IoT-Sensors", 
            "Building-Management",
            "Aruba-Test"
        ]
        # EnOcean EEP profiles
        self.eep_profiles = [
            "D5-00-01",  # Single Contact
            "A5-02-05",  # Temperature Sensor
            "A5-04-01",  # Temperature & Humidity
            "A5-06-02",  # Light Sensor
            "A5-07-01"   # Occupancy Sensor
        ]
    
    def generate_ibeacon_packet(self):
        """Generate a simulated iBeacon packet"""
        # Generate random iBeacon data
        uuid = f"{random.randint(0, 0xffffffff):08x}-{random.randint(0, 0xffff):04x}-{random.randint(0, 0xffff):04x}-{random.randint(0, 0xffff):04x}-{random.randint(0, 0xffffffffffff):012x}"
        major = random.randint(0, 65535)
        minor = random.randint(0, 65535)
        tx_power = -random.randint(55, 80)  # Typically around -60 to -75 dBm
        
        # Basic iBeacon structure
        return {
            "type": "ble",
            "subtype": "ibeacon",
            "deviceId": f"ibeacon-{uuid[:8]}-{major}-{minor}",
            "macAddress": random.choice(self.device_macs),
            "rssi": random.randint(-80, -30),
            "manufacturerData": f"4c000215{uuid.replace('-', '')}{major:04x}{minor:04x}{abs(tx_power):02x}",
            "uuid": uuid,
            "major": major,
            "minor": minor,
            "txPower": tx_power,
            "serviceUuids": [],
            "location": {
                "x": round(random.uniform(0, 100), 2),
                "y": round(random.uniform(0, 100), 2),
                "z": round(random.uniform(0, 10), 2)
            },
            "accessPoint": self.ap_name,
            "timestamp": datetime.now(timezone.utc).isoformat()
        }
    
    def generate_wifi_packet(self):
        """Generate a simulated WiFi packet"""
        # Generate random WiFi data
        channel = random.randint(1, 13)
        ssid = random.choice(self.ssids)
        mac = random.choice(self.device_macs)
        
        return {
            "type": "wifi",
            "deviceId": f"wifi-{mac.replace(':', '')}",
            "macAddress": mac,
            "rssi": random.randint(-85, -30),
            "ssid": ssid,
            "channel": channel,
            "frequency": 2400 + (channel * 5),  # Approximate 2.4GHz frequency
            "security": random.choice(["WPA2", "WPA3", "Open", "WPA2-Enterprise"]),
            "vendor": random.choice(["Apple", "Samsung", "Dell", "HP", "Aruba"]),
            "signalLevel": random.randint(30, 90),
            "location": {
                "x": round(random.uniform(0, 100), 2),
                "y": round(random.uniform(0, 100), 2),
                "z": round(random.uniform(0, 10), 2)
            },
            "accessPoint": self.ap_name,
            "timestamp": datetime.now(timezone.utc).isoformat()
        }
    
    def generate_enocean_packet(self):
        """Generate a simulated EnOcean packet"""
        # Generate random EnOcean data
        eep = random.choice(self.eep_profiles)
        device_id = f"enocean-{random.randint(0, 0xffffffff):08x}"
        
        # Generate sensor data based on EEP profile
        sensor_data = {}
        if "A5-02" in eep:  # Temperature sensor
            sensor_data["temperature"] = round(random.uniform(15, 30), 1)
        elif "A5-04" in eep:  # Temperature & Humidity
            sensor_data["temperature"] = round(random.uniform(15, 30), 1)
            sensor_data["humidity"] = round(random.uniform(30, 80), 1)
        elif "A5-06" in eep:  # Light sensor
            sensor_data["illuminance"] = round(random.uniform(0, 2000), 1)
        elif "A5-07" in eep:  # Occupancy
            sensor_data["occupancy"] = random.choice([True, False])
        elif "D5-00" in eep:  # Contact
            sensor_data["contactState"] = random.choice([True, False])
        
        # Generate random payload (hex string)
        payload_length = random.randint(8, 16)
        payload = ''.join([f"{random.randint(0, 255):02x}" for _ in range(payload_length)])
        
        # Basic EnOcean structure
        packet = {
            "type": "enocean",
            "deviceId": device_id,
            "eep": eep,
            "payload": payload,
            "rssi": random.randint(-85, -30),
            "batteryLevel": random.randint(30, 100),
            "location": {
                "x": round(random.uniform(0, 100), 2),
                "y": round(random.uniform(0, 100), 2),
                "z": round(random.uniform(0, 10), 2)
            },
            "accessPoint": self.ap_name,
            "timestamp": datetime.now(timezone.utc).isoformat()
        }
        
        # Add sensor data
        packet.update(sensor_data)
        
        return packet

async def send_packets(server_uri, duration=60, packet_types=None, use_protobuf=True, token="1234"):
    """Send packets to the server"""
    simulator = DeviceSimulator()
    
    if packet_types is None:
        packet_types = ["ble", "wifi", "enocean"]
    
    # Build the URI with authentication
    base_uri = server_uri
    if not base_uri.endswith('/'):
        base_uri = f"{base_uri}/aruba"
    else:
        base_uri = f"{base_uri}aruba"
    
    # Add token authentication
    if '?' in base_uri:
        server_uri = f"{base_uri}&token={token}"
    else:
        server_uri = f"{base_uri}?token={token}"
    
    try:
        async with websockets.connect(server_uri) as websocket:
            print(f"Connected to {server_uri}")
            print(f"Starting simulation for {duration} seconds...")
            print(f"Packet types: {', '.join(packet_types)}")
            print(f"Protobuf encoding: {'ENABLED' if use_protobuf else 'DISABLED'}")
            
            start_time = time.time()
            packet_count = 0
            packet_type_counts = {"ble": 0, "wifi": 0, "enocean": 0}
            
            # Get welcome message
            welcome = await websocket.recv()
            print(f"Server says: {welcome}")
            
            while time.time() - start_time < duration:
                # Choose packet type
                packet_type = random.choice(packet_types)
                
                # Generate packet based on type
                if packet_type == "ble":
                    packet = simulator.generate_ibeacon_packet()
                elif packet_type == "wifi":
                    packet = simulator.generate_wifi_packet()
                elif packet_type == "enocean":
                    packet = simulator.generate_enocean_packet()
                
                # Send with protobuf or JSON
                if use_protobuf:
                    try:
                        if packet_type == "ble":
                            binary_data = encode_ibeacon_packet(packet)
                            encoder_name = "iBeacon"
                        elif packet_type == "wifi":
                            binary_data = encode_wifi_packet(packet)
                            encoder_name = "WiFi"
                        elif packet_type == "enocean":
                            binary_data = encode_enocean_packet(packet)
                            encoder_name = "EnOcean"
                        
                        print(f"📦 Sending {encoder_name} protobuf packet: {len(binary_data)} bytes")
                        await websocket.send(binary_data)
                        packet_count += 1
                        packet_type_counts[packet_type] += 1
                    except Exception as e:
                        print(f"❌ Error encoding protobuf: {e}")
                        # Fall back to JSON
                        print("⚠️ Falling back to JSON")
                        await websocket.send(json.dumps(packet))
                        packet_count += 1
                        packet_type_counts[packet_type] += 1
                else:
                    # Send as JSON
                    await websocket.send(json.dumps(packet))
                    packet_count += 1
                    packet_type_counts[packet_type] += 1
                
                print(f"📡 Sent {packet_type.upper()} packet #{packet_count}: ID {packet['deviceId']}")
                
                # Get acknowledgment
                try:
                    ack = await asyncio.wait_for(websocket.recv(), timeout=1.0)
                    print(f"✅ Server acknowledged: {ack}")
                except asyncio.TimeoutError:
                    print("⚠️ No acknowledgment received")
                
                # Random delay between packets
                await asyncio.sleep(random.uniform(0.5, 2.0))
            
            print(f"Simulation complete. Sent {packet_count} packets in {duration} seconds:")
            for ptype, count in packet_type_counts.items():
                if count > 0:
                    print(f"  - {ptype.upper()}: {count} packets")
            
    except websockets.exceptions.ConnectionClosedOK:
        print(f"Connection closed normally")
    except websockets.exceptions.ConnectionClosedError:
        print(f"Connection closed with error")
    except ConnectionRefusedError:
        print(f"Could not connect to {server_uri}. Make sure the server is running.")
    except Exception as e:
        print(f"Error during simulation: {e}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Multi-Protocol Test Client for Aruba IoT Telemetry Server")
    parser.add_argument("--server", default="ws://localhost:9191", 
                        help="WebSocket server URI (default: ws://localhost:9191)")
    parser.add_argument("--duration", type=int, default=30,
                        help="Simulation duration in seconds (default: 30)")
    parser.add_argument("--token", default="1234",
                        help="Authentication token (default: 1234)")
    parser.add_argument("--json-only", action="store_true",
                        help="Use JSON encoding only (no protobuf)")
    parser.add_argument("--packet-types", default="ble,wifi,enocean",
                        help="Comma-separated list of packet types to simulate (default: ble,wifi,enocean)")
    
    args = parser.parse_args()
    
    # Parse packet types
    packet_types = args.packet_types.split(",")
    valid_types = {"ble", "wifi", "enocean"}
    packet_types = [pt for pt in packet_types if pt in valid_types]
    
    if not packet_types:
        print("No valid packet types specified. Using all packet types.")
        packet_types = ["ble", "wifi", "enocean"]
    
    print("Multi-Protocol Test Client")
    print("=========================")
    print(f"Server: {args.server}")
    print(f"Duration: {args.duration} seconds")
    print(f"Auth Token: {args.token}")
    print(f"Packet Types: {', '.join(packet_types)}")
    print(f"Encoding: {'JSON only' if args.json_only else 'Protobuf when possible'}")
    print()
    
    # Start the simulation
    asyncio.run(send_packets(
        server_uri=args.server,
        duration=args.duration,
        packet_types=packet_types,
        use_protobuf=not args.json_only,
        token=args.token
    ))
