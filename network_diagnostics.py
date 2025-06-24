#!/usr/bin/env python3
"""
Network diagnostics for Aruba IoT WebSocket server
"""

import socket
import subprocess
import sys

def check_network_configuration():
    """Check network configuration and connectivity"""
    print("🔍 Aruba IoT WebSocket Server Diagnostics")
    print("=" * 50)
    
    # Check if port 9191 is listening
    print("\n1. Port 9191 Status:")
    try:
        result = subprocess.run(['lsof', '-i', ':9191'], capture_output=True, text=True)
        if result.returncode == 0:
            print("✅ Port 9191 is listening")
            print(result.stdout)
        else:
            print("❌ Port 9191 is not listening")
    except Exception as e:
        print(f"❌ Error checking port: {e}")
    
    # Check all IP addresses
    print("\n2. Available IP Addresses:")
    try:
        hostname = socket.gethostname()
        local_ip = socket.gethostbyname(hostname)
        print(f"   Hostname: {hostname}")
        print(f"   Local IP: {local_ip}")
        print(f"   Localhost: 127.0.0.1")
        
        # Check if we can bind to the specific IP
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            try:
                s.bind(('192.168.255.34', 0))  # Bind to any available port
                print("✅ Can bind to 192.168.255.34")
            except Exception as e:
                print(f"❌ Cannot bind to 192.168.255.34: {e}")
    except Exception as e:
        print(f"❌ Error checking IP addresses: {e}")
    
    # Test WebSocket connections
    print("\n3. WebSocket Connection Tests:")
    test_urls = [
        "ws://localhost:9191/aruba",
        "ws://127.0.0.1:9191/aruba", 
        "ws://192.168.255.34:9191/aruba"
    ]
    
    for url in test_urls:
        try:
            # Simple socket test first
            host = url.split('//')[1].split(':')[0]
            port = 9191
            
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                s.settimeout(2)
                result = s.connect_ex((host, port))
                if result == 0:
                    print(f"✅ {url} - Socket connection OK")
                else:
                    print(f"❌ {url} - Socket connection failed")
        except Exception as e:
            print(f"❌ {url} - Error: {e}")
    
    # Firewall check
    print("\n4. Firewall Status:")
    try:
        result = subprocess.run(['sudo', 'pfctl', '-s', 'rules'], capture_output=True, text=True)
        if "block" in result.stdout.lower():
            print("⚠️  Firewall rules detected - may be blocking connections")
        else:
            print("✅ No obvious firewall blocks detected")
    except:
        print("ℹ️  Cannot check firewall status (requires sudo)")
    
    print("\n" + "=" * 50)
    print("🔧 Recommendations for Aruba Controller Configuration:")
    print("   1. Use URL: ws://192.168.255.34:9191/aruba")
    print("   2. Ensure controller is on same network segment")
    print("   3. Check for firewall rules blocking port 9191")
    print("   4. Verify controller WebSocket client implementation")

if __name__ == "__main__":
    check_network_configuration()
