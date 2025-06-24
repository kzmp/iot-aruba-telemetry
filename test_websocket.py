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
    # Base URL without authentication parameters
    server_url = "ws://192.168.255.34:9191/aruba"
    
    # Authentication parameters
    client_id = "test-client-1"
    access_token = "1234"
    
    # Method 1: Add authentication in URL query parameters using token
    # This is the method that works with our Aruba IoT server
    auth_url = f"{server_url}?token={access_token}"
    
    # Method 2: Add authentication in headers (alternative method)
    extra_headers = {
        "X-Client-ID": client_id,
        "X-Access-Token": access_token
    }
    
    print(f"🔄 Testing connection to {server_url}...")
    print(f"🔑 Using clientID: {client_id}, accessToken: {access_token}")
    
    try:
        # Using both query parameters and headers for authentication
        async with websockets.connect(auth_url, extra_headers=extra_headers, timeout=10) as websocket:
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

async def test_websocket_connection_with_params(server_url=None, client_id=None, access_token=None):
    """Test WebSocket connection with customizable parameters"""
    # Default values if not provided
    server_url = server_url or "ws://192.168.255.34:9191/aruba"
    client_id = client_id or "test-client-1"
    access_token = access_token or "1234"
    
    # Add authentication in URL query parameters
    # Try the simple token authentication that works with the test_client.py
    auth_url = f"{server_url}?token={access_token}"
    
    # Add authentication in headers (alternative method)
    extra_headers = {
        "X-Client-ID": client_id,
        "X-Access-Token": access_token
    }
    
    print(f"🔄 Testing connection to {server_url}")
    print(f"🔑 Using clientID: {client_id}, accessToken: {access_token}")
    
    try:
        # Using both query parameters and headers for authentication
        async with websockets.connect(auth_url, extra_headers=extra_headers, timeout=10) as websocket:
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
    import argparse
    
    # Set up command-line arguments
    parser = argparse.ArgumentParser(description="Test WebSocket connection to Aruba IoT server")
    parser.add_argument("--server", default="ws://192.168.255.34:9191/aruba",
                        help="WebSocket server URL (default: ws://192.168.255.34:9191/aruba)")
    parser.add_argument("--client-id", default="test-client-1",
                        help="Client ID for authentication (default: test-client-1)")
    parser.add_argument("--access-token", default="1234",
                        help="Access token for authentication (default: 1234)")
    
    args = parser.parse_args()
    
    # Run the test with the provided parameters
    result = asyncio.run(test_websocket_connection_with_params(
        server_url=args.server,
        client_id=args.client_id,
        access_token=args.access_token
    ))
    
    sys.exit(0 if result else 1)
