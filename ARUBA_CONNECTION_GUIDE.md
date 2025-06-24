# Aruba Controller WebSocket Connection Troubleshooting

## Current Server Status ✅
- **WebSocket Server**: Running on port 9191
- **Web Dashboard**: Running on port 9090 
- **Status**: Server is fully operational and tested
- **Last Update**: June 24, 2025
- **Test Results**: Successfully processed 12+ telemetry packets

## Connection URLs to Try

### Primary (Current Network IP)
```
ws://192.168.255.66:9191/aruba
```

### Alternative (Previous IP if still valid)
```
ws://192.168.255.34:9191/aruba
```

### Localhost (if controller is on same machine)
```
ws://localhost:9191/aruba
ws://127.0.0.1:9191/aruba
```

## Aruba Controller Configuration

### WebSocket Client Settings
- **Protocol**: WebSocket (ws://) or WebSocket Secure (wss://)
- **Authentication**: Token-based (send token in header or query param)
- **Path**: `/aruba`
- **Subprotocol**: Not required
- **Ping/Pong**: Enabled (30s interval)

### Sample Configuration
```json
{
  "websocket": {
    "url": "ws://192.168.255.34:9191/aruba",
    "token": "1234",
    "reconnect": true,
    "ping_interval": 30
  }
}
```

## Troubleshooting Steps

### 1. Test Basic Connectivity
```bash
telnet 192.168.255.34 9191
```

### 2. Test WebSocket Connection
```bash
curl -v -N -H "Connection: Upgrade" -H "Upgrade: websocket" \
     -H "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" \
     -H "Sec-WebSocket-Version: 13" \
     http://192.168.255.34:9191/aruba
```

### 3. Check Network Route
```bash
ping 192.168.255.34
traceroute 192.168.255.34
```

## Common Issues and Solutions

### Issue: Connection Timeout
**Cause**: Network routing or firewall
**Solution**: 
- Check if both devices are on same network segment
- Verify firewall rules allow port 9191
- Try alternative IP addresses

### Issue: Connection Refused  
**Cause**: Server not running or wrong port
**Solution**:
- Verify server is running: `lsof -i :9191`
- Check server logs for errors
- Try alternative ports

### Issue: Connection Drops
**Cause**: Network instability or server issues
**Solution**:
- Enable WebSocket ping/pong
- Implement reconnection logic
- Check network stability

## Server Logs
Monitor server logs for connection attempts:
```bash
tail -f /path/to/server.log
```

## Contact Information
For technical support with this IoT telemetry server, check the GitHub repository:
https://github.com/kzmp/iot-aruba-telemetry
