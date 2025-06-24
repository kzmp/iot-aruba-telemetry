#!/usr/bin/env python3
"""
Simple WebSocket test client to verify Aruba IoT server connectivity
"""

import asyncio
import websockets
import json
import sys

async def test_websocket_connection():
    """Test WebSocket connection to the Aruba IoT server"""
    server_url = "ws://192.168.255.34:9191/aruba"
    
    print(f"🔄 Testing connection to {server_url}...")
    
    try:
        async with websockets.connect(server_url, timeout=10) as websocket:
            print("✅ WebSocket connection established!")
            
            # Wait for welcome message
            try:
                welcome = await asyncio.wait_for(websocket.recv(), timeout=5)
                print(f"📩 Received welcome: {welcome}")
            except asyncio.TimeoutError:
                print("⚠️  No welcome message received (this is OK)")
            
            # Send a test BLE packet
            test_packet = {
                "type": "ble",
                "timestamp": "2025-06-20T17:30:00Z",
                "access_point": "AP-TEST-01",
                "device_id": "test:device:001",
                "mac_address": "aa:bb:cc:dd:ee:ff",
                "rssi": -65,
                "tx_power": 4,
                "data": "test data"
            }
            
            print(f"📤 Sending test packet...")
            await websocket.send(json.dumps(test_packet))
            
            # Wait for acknowledgment
            try:
                response = await asyncio.wait_for(websocket.recv(), timeout=5)
                print(f"📩 Received response: {response}")
            except asyncio.TimeoutError:
                print("⚠️  No response received")
            
            print("✅ Test completed successfully!")
            
    except asyncio.TimeoutError:
        print("❌ Connection timeout - server might not be accessible")
        return False
    except ConnectionRefusedError:
        print("❌ Connection refused - check if server is running on port 9191")
        return False
    except Exception as e:
        print(f"❌ Connection failed: {e}")
        return False
    
    return True

if __name__ == "__main__":
    result = asyncio.run(test_websocket_connection())
    sys.exit(0 if result else 1)
