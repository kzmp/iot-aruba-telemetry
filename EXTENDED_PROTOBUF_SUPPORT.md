# Extended Protocol Buffers Support

This document describes the extended Protocol Buffers (protobuf) support for the Aruba IoT Telemetry server, which now supports multiple packet types.

## Overview

The Aruba IoT Telemetry server now supports Protocol Buffers for efficient encoding and decoding of multiple IoT telemetry packet types:

1. **iBeacon** (BLE packets with iBeacon format)
2. **WiFi** (WiFi device telemetry)
3. **EnOcean** (EnOcean Alliance sensors)

Protocol Buffers provide several advantages over JSON:
- Smaller message size (typically 30-70% smaller)
- Faster encoding/decoding
- Strongly typed data structures
- Backwards compatibility

## Protobuf Schema Definitions

### iBeacon Schema

```protobuf
message IBeaconPacket {
  string device_mac = 1;           // MAC address of the device
  string timestamp = 2;            // Timestamp when packet was received
  int32 rssi = 3;                  // Received Signal Strength Indicator
  string uuid = 4;                 // iBeacon UUID
  int32 major = 5;                 // iBeacon Major value
  int32 minor = 6;                 // iBeacon Minor value
  int32 tx_power = 7;              // Transmission power
  optional string ap_mac = 8;      // Access Point MAC address
  optional string device_name = 9; // Device name if available
  optional float distance = 10;    // Calculated distance in meters
}
```

### WiFi Schema

```protobuf
message WiFiPacket {
  string device_mac = 1;           // MAC address of the device
  string timestamp = 2;            // Timestamp when packet was received
  int32 rssi = 3;                  // Received Signal Strength Indicator
  string ssid = 4;                 // Network SSID
  int32 channel = 5;               // WiFi channel
  optional string ap_mac = 6;      // Access Point MAC address
  optional string device_name = 7; // Device name if available
  optional float distance = 8;     // Calculated distance in meters
  optional string security = 9;    // Security type (WPA, WPA2, etc.)
  optional int32 frequency = 10;   // Frequency in MHz
  optional string vendor = 11;     // Device vendor if available
  optional int32 signal_level = 12; // Signal level in percentage
}
```

### EnOcean Schema

```protobuf
message EnOceanPacket {
  string device_id = 1;            // EnOcean device ID
  string timestamp = 2;            // Timestamp when packet was received
  int32 rssi = 3;                  // Received Signal Strength Indicator
  string eep = 4;                  // EnOcean Equipment Profile
  string payload = 5;              // EnOcean payload data
  optional string ap_mac = 6;      // Access Point MAC address
  optional string device_name = 7; // Device name if available
  optional float distance = 8;     // Calculated distance in meters
  optional float temperature = 9;  // Temperature reading if available
  optional float humidity = 10;    // Humidity reading if available
  optional bool contact_state = 11; // Contact state for window/door sensors
  optional float illuminance = 12; // Light level for light sensors
  optional float battery_level = 13; // Battery level percentage
}
```

## Usage

### Server-Side Integration

The server automatically detects packet types and attempts to encode/decode them using the appropriate protobuf schema. You don't need to do anything special to use protobuf - the server will handle it automatically.

In the telemetry dashboard, packets processed with protobuf will display a "Protobuf Encoded" badge.

### Testing the Protobuf Implementation

The project includes multiple test clients that can generate protobuf-encoded packets:

1. `test_ibeacon_protobuf.py` - Focused on iBeacon protobuf testing
2. `test_multi_protocol.py` - Tests all packet types with protobuf encoding

To run the multi-protocol test client:

```bash
# Send all packet types with protobuf encoding for 60 seconds
python test_multi_protocol.py --duration 60

# Send only WiFi packets with protobuf encoding
python test_multi_protocol.py --packet-types wifi --duration 30

# Send all packet types without protobuf (JSON only)
python test_multi_protocol.py --json-only
```

## Protobuf Encoding Process

When a packet is received by the server:

1. The server first checks if the data is in binary (protobuf) format
2. If binary, it attempts to decode using each protobuf schema type in sequence
3. If successfully decoded, it processes the packet with the protobuf data
4. If decoding fails, it falls back to standard JSON processing

## Performance Considerations

Protobuf encoding/decoding is significantly faster than JSON and results in smaller message sizes. For typical IoT telemetry data:

- Message size: 30-70% smaller than JSON
- Processing time: 20-50% faster than JSON

This efficiency becomes more important as the scale of your IoT deployment increases.

## Future Enhancements

Planned enhancements for the protobuf implementation:

1. Additional packet types and sensor formats
2. Schema versioning for backward compatibility
3. Support for compressed collections of packets
4. Integration with time-series databases
5. Streaming analytics capabilities

## Troubleshooting

If you encounter issues with protobuf encoding or decoding:

1. Check the server logs for specific error messages related to protobuf
2. Ensure all required fields in the packet match the schema definition
3. Try testing with the `--json-only` flag to see if the issue is related to protobuf
4. Verify that the packet type is correctly identified (check the `type` field)

For more information on Protocol Buffers, visit the [official documentation](https://protobuf.dev/).
