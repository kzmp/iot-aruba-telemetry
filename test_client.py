#!/usr/bin/env python3
"""
Test client to simulate Aruba access point sending IoT telemetry data
"""

import asyncio
import json
import random
import time
import websockets
from datetime import datetime, timezone

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
    
    def generate_random_packet(self):
        """Generate a random packet type"""
        packet_types = [
            self.generate_ble_packet,
            self.generate_wifi_packet,
            self.generate_enocean_packet
        ]
        # Weight BLE packets more heavily as they're more common
        weights = [0.6, 0.3, 0.1]
        packet_generator = random.choices(packet_types, weights=weights)[0]
        return packet_generator()

async def simulate_aruba_ap(server_uri, duration=300):
    """
    Simulate an Aruba access point sending data to the server
    
    Args:
        server_uri: WebSocket server URI (e.g., "ws://localhost:9191")
        duration: Simulation duration in seconds
    """
    simulator = ArubaAPSimulator()
    
    try:
        async with websockets.connect(server_uri) as websocket:
            print(f"Connected to {server_uri}")
            print(f"Starting simulation for {duration} seconds...")
            
            start_time = time.time()
            packet_count = 0
            
            while time.time() - start_time < duration:
                # Generate and send a packet
                packet = simulator.generate_random_packet()
                packet_json = json.dumps(packet, indent=2)
                
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

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Simulate Aruba AP sending IoT telemetry")
    parser.add_argument("--server", default="ws://localhost:9191", 
                        help="WebSocket server URI (default: ws://localhost:9191)")
    parser.add_argument("--duration", type=int, default=60,
                        help="Simulation duration in seconds (default: 60)")
    
    args = parser.parse_args()
    
    print("Aruba AP Simulator")
    print("==================")
    print(f"Server: {args.server}")
    print(f"Duration: {args.duration} seconds")
    print()
    
    asyncio.run(simulate_aruba_ap(args.server, args.duration))
