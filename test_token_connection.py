#!/usr/bin/env python3
"""
Simple test script to connect to Aruba IoT Server with token authentication
"""

import asyncio
import websockets
import json
import time
import sys

async def test_connection(uri):
    """Connect to the WebSocket server and verify authentication"""
    print(f"Connecting to {uri}...")
    
    try:
        async with websockets.connect(uri) as websocket:
            print("Connection established!")
            
            # Wait for the welcome message
            welcome = await websocket.recv()
            print(f"Server response: {welcome}")
            
            # Parse the welcome message
            try:
                welcome_data = json.loads(welcome)
                if welcome_data.get("status") in ["success", "authenticated"]:
                    print("✅ Authentication successful!")
                else:
                    print("❌ Authentication failed or unexpected response!")
            except json.JSONDecodeError:
                print(f"❌ Could not parse server response as JSON: {welcome}")
            
            # Send a ping to check the connection
            ping_message = {
                "type": "ping",
                "timestamp": int(time.time())
            }
            await websocket.send(json.dumps(ping_message))
            print("Sent ping message")
            
            # Wait for a response
            try:
                pong = await asyncio.wait_for(websocket.recv(), timeout=5)
                print(f"Received response: {pong}")
                print("✅ Connection test completed successfully!")
            except asyncio.TimeoutError:
                print("❌ Timeout waiting for server response to ping")
    
    except websockets.exceptions.InvalidStatusCode as e:
        print(f"❌ Connection failed with status code: {e.status_code}")
        print(f"Error message: {e}")
        return False
    except Exception as e:
        print(f"❌ Connection failed: {e}")
        return False
    
    return True

if __name__ == "__main__":
    # Default server URI with authentication token
    token = "token1234"
    if len(sys.argv) > 1:
        token = sys.argv[1]
    
    server_uri = f"ws://localhost:9191/aruba?token={token}"
    
    print("=== Aruba IoT Server Connection Test ===")
    print(f"Server: ws://localhost:9191")
    print(f"Authentication: Token ({token})")
    print("======================================")
    
    asyncio.run(test_connection(server_uri))
