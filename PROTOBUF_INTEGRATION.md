# Protocol Buffers (protobuf) Integration

This document describes the integration of Protocol Buffers (protobuf) for encoding iBeacon device class packets in the Aruba IoT Telemetry application.

## Overview

Protocol Buffers (protobuf) is an efficient, structured data serialization format developed by Google. It provides a more compact binary representation compared to JSON and includes schema validation.

In this application, we've implemented protobuf encoding for iBeacon packets to demonstrate the advantages:

1. Reduced packet size
2. Improved parsing efficiency
3. Structured schema validation
4. Better handling of binary data

## Implementation Details

### Schema Definition

The protobuf schema for iBeacon packets is defined in `protos/ibeacon.proto`:

```protobuf
syntax = "proto3";

package aruba.iot;

// iBeacon packet structure
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

### Encoding/Decoding Functions

The encoding and decoding functions are implemented in the `protobuf_utils.py` module:

- `encode_ibeacon_packet(data)`: Converts a dictionary with iBeacon data to binary protobuf format
- `decode_ibeacon_packet(binary_data)`: Converts binary protobuf data back to a dictionary
- `is_ibeacon_data(data)`: Checks if data is an iBeacon packet

### Integration Points

1. The `process_telemetry` function now detects binary data and tries protobuf decoding
2. The `process_ble_packet` function detects iBeacon packets and encodes them with protobuf
3. The test client has been updated to optionally send protobuf-encoded iBeacon packets

## Testing

You can test protobuf encoding using the updated test client:

```bash
python test_client.py --protobuf
```

The dashboard will display iBeacon packets with a "Protobuf Encoded" badge to indicate they were processed using protobuf.

## Future Enhancements

1. Add protobuf definitions for other packet types (EnOcean, WiFi)
2. Implement versioning for protocol evolution
3. Add support for collections of packets
4. Optimize protobuf field definitions for better compression
