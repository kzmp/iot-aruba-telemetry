#!/usr/bin/env python3
"""
Test client that specifically sends iBeacon packets with protobuf encoding
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
from protobuf_utils import encode_ibeacon_packet

class IBeaconSimulator:
    """Simulates iBeacon devices for testing protobuf encoding"""
    
    def __init__(self, ap_name="AP-Protobuf-Test"):
        self.ap_name = ap_name
        self.device_macs = [
            "aa:bb:cc:dd:ee:01",
            "aa:bb:cc:dd:ee:02", 
            "aa:bb:cc:dd:ee:03",
            "11:22:33:44:55:01",
            "11:22:33:44:55:02"
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

async def send_ibeacon_packets(server_uri, duration=60, use_protobuf=True, token="1234"):
    """Send iBeacon packets to the server using protobuf encoding"""
    simulator = IBeaconSimulator()
    
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
            print(f"Starting iBeacon simulation for {duration} seconds...")
            print(f"Protobuf encoding: {'ENABLED' if use_protobuf else 'DISABLED'}")
            
            start_time = time.time()
            packet_count = 0
            
            # Get welcome message
            welcome = await websocket.recv()
            print(f"Server says: {welcome}")
            
            while time.time() - start_time < duration:
                # Generate an iBeacon packet
                packet = simulator.generate_ibeacon_packet()
                
                if use_protobuf:
                    try:
                        # Encode the packet using protobuf
                        binary_data = encode_ibeacon_packet(packet)
                        print(f"📦 Sending protobuf packet: {len(binary_data)} bytes")
                        await websocket.send(binary_data)
                        packet_count += 1
                    except Exception as e:
                        print(f"❌ Error encoding protobuf: {e}")
                        # Fall back to JSON
                        print("⚠️ Falling back to JSON")
                        await websocket.send(json.dumps(packet))
                        packet_count += 1
                else:
                    # Send as JSON
                    await websocket.send(json.dumps(packet))
                    packet_count += 1
                
                print(f"📡 Sent packet #{packet_count}: iBeacon {packet['uuid'][:8]}... Major: {packet['major']} Minor: {packet['minor']}")
                
                # Get acknowledgment
                try:
                    ack = await asyncio.wait_for(websocket.recv(), timeout=1.0)
                    print(f"✅ Server acknowledged: {ack}")
                except asyncio.TimeoutError:
                    print("⚠️ No acknowledgment received")
                
                # Random delay between packets
                await asyncio.sleep(random.uniform(0.5, 2.0))
            
            print(f"Simulation complete. Sent {packet_count} packets in {duration} seconds.")
            
    except websockets.exceptions.ConnectionClosedOK:
        print(f"Connection closed normally")
    except websockets.exceptions.ConnectionClosedError:
        print(f"Connection closed with error")
    except ConnectionRefusedError:
        print(f"Could not connect to {server_uri}. Make sure the server is running.")
    except Exception as e:
        print(f"Error during simulation: {e}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Simulate iBeacon devices with protobuf encoding")
    parser.add_argument("--server", default="ws://localhost:9191", 
                        help="WebSocket server URI (default: ws://localhost:9191)")
    parser.add_argument("--duration", type=int, default=30,
                        help="Simulation duration in seconds (default: 30)")
    parser.add_argument("--token", default="1234",
                        help="Authentication token (default: 1234)")
    parser.add_argument("--json-only", action="store_true",
                        help="Use JSON encoding only (no protobuf)")
    
    args = parser.parse_args()
    
    print("iBeacon Protobuf Test Client")
    print("===========================")
    print(f"Server: {args.server}")
    print(f"Duration: {args.duration} seconds")
    print(f"Auth Token: {args.token}")
    print(f"Encoding: {'JSON only' if args.json_only else 'Protobuf when possible'}")
    print()
    
    # Start the simulation
    asyncio.run(send_ibeacon_packets(
        server_uri=args.server,
        duration=args.duration,
        use_protobuf=not args.json_only,
        token=args.token
    ))
