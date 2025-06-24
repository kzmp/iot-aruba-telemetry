#!/usr/bin/env python3
"""
Test client to simulate Aruba access point sending IoT telemetry data
"""

import argparse
import random
import asyncio
import json
import time
import websockets
from datetime import datetime, timezone

# Try to import protobuf utilities
try:
    import sys
    import os
    # Add the parent directory to the path to find protobuf_utils
    sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    from protobuf_utils import encode_ibeacon_packet
    HAS_PROTOBUF = True
    print("Found protobuf utilities, protobuf encoding is available")
except ImportError:
    HAS_PROTOBUF = False
    print("Warning: protobuf_utils module not found, protobuf encoding will be disabled")

class ArubaAPSimulator:
    """Simulates an Aruba access point sending IoT telemetry"""
    
    def __init__(self, ap_name="AP-Test-01"):
        self.ap_name = ap_name
        self.device_macs = [
            "aa:bb:cc:dd:ee:01",
            "aa:bb:cc:dd:ee:02", 
            "aa:bb:cc:dd:ee:03",
            "11:22:33:44:55:01",
            "11:22:33:44:55:02"
        ]
        self.enocean_devices = [
            "00:11:22:33",
            "44:55:66:77", 
            "88:99:aa:bb"
        ]
        
    def generate_ble_packet(self):
        """Generate a simulated BLE packet"""
        return {
            "type": "ble",
            "deviceId": f"ble-{random.choice(self.device_macs).replace(':', '')}",
            "macAddress": random.choice(self.device_macs),
            "rssi": random.randint(-80, -30),
            "manufacturerData": f"{random.randint(0, 65535):04x}",
            "serviceUuids": ["180f", "180a"] if random.random() > 0.5 else [],
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
        ssids = ["Guest-WiFi", "Corp-Network", "IoT-Devices", ""]
        return {
            "type": "wifi",
            "deviceId": f"wifi-{random.choice(self.device_macs).replace(':', '')}",
            "macAddress": random.choice(self.device_macs),
            "ssid": random.choice(ssids),
            "rssi": random.randint(-90, -20),
            "channel": random.choice([1, 6, 11, 36, 44, 149, 157]),
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
        eeps = ["F6-02-01", "D5-00-01", "A5-02-05", "A5-04-01"]
        return {
            "type": "enocean",
            "deviceId": f"enocean-{random.choice(self.enocean_devices)}",
            "eep": random.choice(eeps),
            "payload": f"{random.randint(0, 4294967295):08x}",
            "rssi": random.randint(-70, -40),
            "location": {
                "x": round(random.uniform(0, 100), 2),
                "y": round(random.uniform(0, 100), 2),
                "z": round(random.uniform(0, 10), 2)
            },
            "accessPoint": self.ap_name,
            "timestamp": datetime.now(timezone.utc).isoformat()
        }
    
    def generate_ibeacon_packet(self):
        """Generate a simulated iBeacon packet"""
        # Generate random iBeacon data
        uuid = f"{random.randint(0, 0xffffffff):08x}-{random.randint(0, 0xffff):04x}-{random.randint(0, 0xffff):04x}-{random.randint(0, 0xffff):04x}-{random.randint(0, 0xffffffffffff):012x}"
        major = random.randint(0, 65535)
        minor = random.randint(0, 65535)
        tx_power = -random.randint(55, 80)  # Typically around -60 to -75 dBm
        
        # Basic iBeacon structure
        packet = {
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
        
        # If protobuf is available, encode the packet using protobuf
        if HAS_PROTOBUF:
            packet = encode_ibeacon_packet(packet)
        
        return packet
    
    def generate_random_packet(self, use_protobuf=False):
        """Generate a random packet type"""
        if use_protobuf:
            # Always generate an iBeacon packet when protobuf is requested
            print("Generating iBeacon packet for protobuf encoding")
            return self.generate_ibeacon_packet()
        else:
            packet_types = [
                self.generate_ble_packet,
                self.generate_wifi_packet,
                self.generate_enocean_packet,
                self.generate_ibeacon_packet
            ]
            # Weight BLE packets more heavily as they're more common
            weights = [0.4, 0.3, 0.1, 0.2]  # Added weight for iBeacon packets
            packet_generator = random.choices(packet_types, weights=weights)[0]
            return packet_generator()

async def simulate_aruba_ap(server_uri, duration=300, client_id=None, access_token=None):
    """
    Simulate an Aruba access point sending data to the server
    
    Args:
        server_uri: WebSocket server URI (e.g., "ws://localhost:9191")
        duration: Simulation duration in seconds
        client_id: Optional client_id for header-based authentication
        access_token: Optional access_token for header-based authentication
    """
    simulator = ArubaAPSimulator()
    
    # Add custom headers for additional authentication methods
    extra_headers = {}
    if client_id:
        extra_headers["X-Client-ID"] = client_id
    if access_token:
        extra_headers["X-Access-Token"] = access_token
    
    try:
        async with websockets.connect(server_uri, extra_headers=extra_headers) as websocket:
            print(f"Connected to {server_uri}")
            print(f"Starting simulation for {duration} seconds...")
            
            start_time = time.time()
            packet_count = 0
            
            while time.time() - start_time < duration:
                # Determine if we should try to use protobuf
                use_protobuf = HAS_PROTOBUF and args.protobuf and random.random() < 0.3
                
                if use_protobuf:
                    # Generate an iBeacon packet specifically for protobuf
                    packet = simulator.generate_random_packet(use_protobuf=True)
                    try:
                        print(f"🔶 Using protobuf encoding for iBeacon packet")
                        binary_data = encode_ibeacon_packet(packet)
                        print(f"📦 Sending {len(binary_data)} bytes of protobuf binary data")
                        await websocket.send(binary_data)
                        packet_count += 1
                        print(f"Sent packet #{packet_count}: BLE (IBEACON) (Protobuf) from {packet['deviceId']}")
                    except Exception as e:
                        print(f"❌ Error encoding protobuf: {e}")
                        print(f"⚠️ Falling back to JSON")
                        # Fall back to JSON if protobuf encoding fails
                        packet_json = json.dumps(packet)
                        await websocket.send(packet_json)
                        packet_count += 1
                        print(f"Sent packet #{packet_count}: BLE (IBEACON) from {packet['deviceId']}")
                else:
                    # Generate a regular packet
                    packet = simulator.generate_random_packet()
                    packet_json = json.dumps(packet)
                    await websocket.send(packet_json)
                    packet_count += 1
                    print(f"Sent packet #{packet_count}: {packet['type'].upper()} from {packet['deviceId']}")
                
                # Random delay between packets (0.1 to 2 seconds)
                await asyncio.sleep(random.uniform(0.1, 2.0))
            
            print(f"Simulation complete. Sent {packet_count} packets in {duration} seconds.")
            
    except websockets.exceptions.ConnectionClosedOK:
        print(f"Connection closed normally")
    except websockets.exceptions.ConnectionClosedError:
        print(f"Connection closed with error")
    except ConnectionRefusedError:
        print(f"Could not connect to {server_uri}. Make sure the server is running.")
    except Exception as e:
        print(f"Error during simulation: {e}")

def main(args):
    """Main function"""
    global HAS_PROTOBUF  # Allow main to modify this variable
    
    # Check protobuf availability if requested
    if args.protobuf and not HAS_PROTOBUF:
        print("⚠️ Warning: Protobuf support requested but protobuf_utils module not found")
        print("⚠️ Running without protobuf support")
    
    # Add path to server URI
    base_uri = args.server
    if not base_uri.endswith('/'):
        base_uri = f"{base_uri}/aruba"
    else:
        base_uri = f"{base_uri}aruba"
    
    # Determine authentication method
    auth_params = ""
    if args.auth_method == "token":
        print(f"Auth Method: Token")
        print(f"Auth Token: {args.token}")
        auth_params = f"token={args.token}"
    else:
        print(f"Auth Method: Client ID + Access Token")
        print(f"Client ID: {args.client_id}")
        print(f"Access Token: {'*' * len(args.access_token)}")
        auth_params = f"clientID={args.client_id}&accessToken={args.access_token}"
    
    print()
        
    # Add authentication to server URI
    if '?' in base_uri:
        server_uri = f"{base_uri}&{auth_params}"
    else:
        server_uri = f"{base_uri}?{auth_params}"
    
    # Run the simulation with the appropriate authentication method
    asyncio.run(simulate_aruba_ap(
        server_uri=server_uri, 
        duration=args.duration,
        client_id=args.client_id if args.auth_method == "client" else None,
        access_token=args.access_token if args.auth_method == "client" else None
    ))

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Simulate Aruba AP sending IoT telemetry")
    parser.add_argument("--server", default="ws://localhost:9191", 
                        help="WebSocket server URI (default: ws://localhost:9191)")
    parser.add_argument("--duration", type=int, default=60,
                        help="Simulation duration in seconds (default: 60)")
    parser.add_argument("--token", default="1234",
                        help="Authentication token (default: 1234)")
    parser.add_argument("--client-id", default="",
                        help="Client ID for authentication (default: none)")
    parser.add_argument("--access-token", default="",
                        help="Access token for authentication (default: none)")
    parser.add_argument("--auth-method", default="token", choices=["token", "client"],
                        help="Authentication method: 'token' or 'client' (default: token)")
    parser.add_argument("--protobuf", action="store_true", 
                        help="Enable protobuf encoding for iBeacon packets")
    
    args = parser.parse_args()
    
    print("Aruba AP Simulator")
    print("==================")
    print(f"Server: {args.server}")
    print(f"Duration: {args.duration} seconds")
    
    # Run the main function with the parsed arguments
    main(args)
