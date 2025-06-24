"""
Protobuf utilities for Aruba IoT Telemetry Server

This module provides utility functions to encode and decode protobuf messages
for the Aruba IoT Telemetry Server.
"""
import logging
from datetime import datetime, timezone
from typing import Dict, Any, Optional, List, Union

# Import the generated protobuf classes
from protos.generated.ibeacon_pb2 import IBeaconPacket, IBeaconPacketCollection
from protos.wifi_pb2 import WiFiPacket, WiFiPacketCollection
from protos.enocean_pb2 import EnOceanPacket, EnOceanPacketCollection

# Configure logging
logger = logging.getLogger('aruba-iot')

def encode_ibeacon_packet(data: Dict[str, Any]) -> bytes:
    """
    Encode a BLE packet with iBeacon data to protobuf binary format
    
    Args:
        data: Dictionary containing the iBeacon packet data
        
    Returns:
        Binary protobuf message
    """
    logger.info("encode_ibeacon_packet: Starting protobuf encoding for iBeacon data")
    
    # Extract device information
    device_mac = data.get('macAddress', '')
    device_id = data.get('deviceId', 'unknown')
    timestamp = datetime.now(timezone.utc).isoformat()
    rssi = data.get('rssi', 0)
    ap_mac = data.get('accessPoint', '')
    
    # Log key values
    logger.info(f"encode_ibeacon_packet: Device ID: {device_id}, MAC: {device_mac}, RSSI: {rssi}")
    
    # Extract iBeacon specific data (need to parse from manufacturer data)
    manufacturer_data = data.get('manufacturerData', '')
    uuid = ''
    major = 0
    minor = 0
    tx_power = 0
    device_name = data.get('deviceName', '')
    
    # Check if we have valid iBeacon manufacturer data
    # This is a simplified example - real iBeacon parsing would be more complex
    if manufacturer_data:
        logger.info(f"encode_ibeacon_packet: Extracting iBeacon data from manufacturer data")
        
        # Basic iBeacon parsing from manufacturer data
        # In real app, you'd need to properly parse based on iBeacon format
        # This is placeholder logic
        uuid = data.get('uuid', '')
        major = data.get('major', 0)
        minor = data.get('minor', 0)
        tx_power = data.get('txPower', 0)
    
    # Create protobuf message
    packet = IBeaconPacket(
        device_mac=device_mac,
        timestamp=timestamp,
        rssi=rssi,
        uuid=uuid,
        major=major,
        minor=minor,
        tx_power=tx_power
    )
    
    # Set optional fields only if they're available
    if ap_mac:
        packet.ap_mac = ap_mac
    if device_name:
        packet.device_name = device_name
    
    # Calculate distance if RSSI and txPower are available
    if rssi and tx_power:
        # Basic distance calculation formula (very approximate)
        # distance = 10 ^ ((txPower - RSSI) / 20)
        try:
            import math
            distance = 10 ** ((tx_power - rssi) / 20)
            packet.distance = distance
            logger.info(f"encode_ibeacon_packet: Calculated distance: {distance:.2f} meters")
        except Exception as e:
            logger.warning(f"encode_ibeacon_packet: Failed to calculate distance: {e}")
    
    # Serialize to binary
    binary_data = packet.SerializeToString()
    logger.info(f"encode_ibeacon_packet: Successfully encoded to {len(binary_data)} bytes")
    
    return binary_data

def decode_ibeacon_packet(binary_data: bytes) -> Dict[str, Any]:
    """
    Decode a protobuf binary message to an iBeacon packet dictionary
    
    Args:
        binary_data: Protobuf binary data
        
    Returns:
        Dictionary with decoded packet data
    """
    logger.info(f"decode_ibeacon_packet: Decoding {len(binary_data)} bytes of protobuf data")
    
    # Parse protobuf message
    packet = IBeaconPacket()
    packet.ParseFromString(binary_data)
    
    # Convert to dictionary
    result = {
        'type': 'ble',
        'subtype': 'ibeacon',
        'device_id': packet.device_mac,  # Using MAC as device ID
        'mac_address': packet.device_mac,
        'timestamp': packet.timestamp,
        'rssi': packet.rssi,
        'uuid': packet.uuid,
        'major': packet.major,
        'minor': packet.minor,
        'tx_power': packet.tx_power,
    }
    
    # Add optional fields if present
    if packet.HasField('ap_mac'):
        result['access_point'] = packet.ap_mac
        result['reporter'] = packet.ap_mac
    
    if packet.HasField('device_name'):
        result['device_name'] = packet.device_name
    
    if packet.HasField('distance'):
        result['distance'] = packet.distance
    
    logger.info(f"decode_ibeacon_packet: Successfully decoded protobuf data")
    return result

def encode_ibeacon_collection(packets: List[Dict[str, Any]]) -> bytes:
    """
    Encode a collection of iBeacon packets to protobuf binary format
    
    Args:
        packets: List of dictionaries containing iBeacon packet data
        
    Returns:
        Binary protobuf message
    """
    logger.info(f"encode_ibeacon_collection: Encoding collection of {len(packets)} packets")
    
    # Create a collection message
    collection = IBeaconPacketCollection()
    
    # Add each packet to the collection
    for packet_data in packets:
        # Create a new IBeaconPacket
        packet = IBeaconPacket(
            device_mac=packet_data.get('macAddress', ''),
            timestamp=packet_data.get('timestamp', datetime.now(timezone.utc).isoformat()),
            rssi=packet_data.get('rssi', 0),
            uuid=packet_data.get('uuid', ''),
            major=packet_data.get('major', 0),
            minor=packet_data.get('minor', 0),
            tx_power=packet_data.get('txPower', 0)
        )
        
        # Set optional fields
        ap_mac = packet_data.get('accessPoint')
        if ap_mac:
            packet.ap_mac = ap_mac
        
        device_name = packet_data.get('deviceName')
        if device_name:
            packet.device_name = device_name
        
        distance = packet_data.get('distance')
        if distance is not None:
            packet.distance = distance
        
        # Add to collection
        collection.packets.append(packet)
    
    # Serialize to binary
    binary_data = collection.SerializeToString()
    logger.info(f"encode_ibeacon_collection: Successfully encoded to {len(binary_data)} bytes")
    
    return binary_data

def decode_ibeacon_collection(binary_data: bytes) -> List[Dict[str, Any]]:
    """
    Decode a protobuf binary message to a list of iBeacon packet dictionaries
    
    Args:
        binary_data: Protobuf binary data
        
    Returns:
        List of dictionaries with decoded packet data
    """
    logger.info(f"decode_ibeacon_collection: Decoding {len(binary_data)} bytes of protobuf data")
    
    # Parse protobuf message
    collection = IBeaconPacketCollection()
    collection.ParseFromString(binary_data)
    
    # Convert each packet to dictionary
    results = []
    for packet in collection.packets:
        result = {
            'type': 'ble',
            'subtype': 'ibeacon',
            'device_id': packet.device_mac,
            'mac_address': packet.device_mac,
            'timestamp': packet.timestamp,
            'rssi': packet.rssi,
            'uuid': packet.uuid,
            'major': packet.major,
            'minor': packet.minor,
            'tx_power': packet.tx_power,
        }
        
        # Add optional fields if present
        if packet.HasField('ap_mac'):
            result['access_point'] = packet.ap_mac
            result['reporter'] = packet.ap_mac
        
        if packet.HasField('device_name'):
            result['device_name'] = packet.device_name
        
        if packet.HasField('distance'):
            result['distance'] = packet.distance
        
        results.append(result)
    
    logger.info(f"decode_ibeacon_collection: Successfully decoded {len(results)} packets")
    return results

def is_ibeacon_data(data: Dict[str, Any]) -> bool:
    """
    Check if the data appears to be an iBeacon packet
    
    Args:
        data: Dictionary containing packet data
        
    Returns:
        True if the data appears to be an iBeacon packet
    """
    # This is a simplified check - in practice you'd need to examine the
    # manufacturer data format and structure according to iBeacon specs
    if data.get('type', '').lower() != 'ble':
        return False
    
    # Check for iBeacon indicators
    # Real implementation would parse manufacturer data properly
    manufacturer_data = data.get('manufacturerData', '')
    if not manufacturer_data:
        return False
    
    # Examples of iBeacon indicators:
    # - Company ID for Apple (0x004C) at the start of manufacturer data
    # - Followed by iBeacon type code (0x02, 0x15)
    # - Then 16 bytes of UUID, 2 bytes major, 2 bytes minor, 1 byte tx power
    
    # This is a placeholder for actual iBeacon detection logic
    # In reality, you'd examine the binary structure of manufacturer data
    return 'ibeacon' in str(data).lower() or \
           'uuid' in data or \
           (manufacturer_data and len(str(manufacturer_data)) >= 20)  # Minimum expected length

def encode_wifi_packet(data: Dict[str, Any]) -> bytes:
    """
    Encode a WiFi packet to protobuf binary format
    
    Args:
        data: Dictionary containing the WiFi packet data
        
    Returns:
        Binary protobuf message
    """
    logger.info("encode_wifi_packet: Starting protobuf encoding for WiFi data")
    
    # Extract device information
    device_mac = data.get('macAddress', '')
    device_id = data.get('deviceId', 'unknown')
    timestamp = datetime.now(timezone.utc).isoformat()
    rssi = data.get('rssi', 0)
    ap_mac = data.get('accessPoint', '')
    
    # Log key values
    logger.info(f"encode_wifi_packet: Device ID: {device_id}, MAC: {device_mac}, RSSI: {rssi}")
    
    # Extract WiFi specific data
    ssid = data.get('ssid', '')
    channel = data.get('channel', 0)
    security = data.get('security', '')
    frequency = data.get('frequency', 0)
    vendor = data.get('vendor', '')
    device_name = data.get('deviceName', '')
    signal_level = data.get('signalLevel', 0)
    
    # Create protobuf message
    packet = WiFiPacket(
        device_mac=device_mac,
        timestamp=timestamp,
        rssi=rssi,
        ssid=ssid,
        channel=channel
    )
    
    # Set optional fields only if they're available
    if ap_mac:
        packet.ap_mac = ap_mac
    if device_name:
        packet.device_name = device_name
    if security:
        packet.security = security
    if frequency:
        packet.frequency = frequency
    if vendor:
        packet.vendor = vendor
    if signal_level:
        packet.signal_level = signal_level
    
    # Calculate distance if RSSI is available
    if rssi:
        try:
            import math
            # Basic distance calculation (simplified formula)
            # distance = 10 ^ ((RSSI at 1m - RSSI) / 20)
            # Using -40 as a reference RSSI at 1m
            distance = 10 ** ((-40 - rssi) / 20)
            packet.distance = distance
            logger.info(f"encode_wifi_packet: Calculated distance: {distance:.2f} meters")
        except Exception as e:
            logger.warning(f"encode_wifi_packet: Failed to calculate distance: {e}")
    
    # Serialize to binary
    binary_data = packet.SerializeToString()
    logger.info(f"encode_wifi_packet: Successfully encoded to {len(binary_data)} bytes")
    
    return binary_data

def decode_wifi_packet(binary_data: bytes) -> Dict[str, Any]:
    """
    Decode a protobuf binary message to a WiFi packet dictionary
    
    Args:
        binary_data: Protobuf binary data
        
    Returns:
        Dictionary with decoded packet data
    """
    logger.info(f"decode_wifi_packet: Decoding {len(binary_data)} bytes of protobuf data")
    
    # Parse protobuf message
    packet = WiFiPacket()
    packet.ParseFromString(binary_data)
    
    # Convert to dictionary
    result = {
        'type': 'wifi',
        'device_id': packet.device_mac,  # Using MAC as device ID
        'mac_address': packet.device_mac,
        'timestamp': packet.timestamp,
        'rssi': packet.rssi,
        'ssid': packet.ssid,
        'channel': packet.channel,
    }
    
    # Add optional fields if present
    if packet.HasField('ap_mac'):
        result['access_point'] = packet.ap_mac
        result['reporter'] = packet.ap_mac
    
    if packet.HasField('device_name'):
        result['device_name'] = packet.device_name
    
    if packet.HasField('distance'):
        result['distance'] = packet.distance
        
    if packet.HasField('security'):
        result['security'] = packet.security
        
    if packet.HasField('frequency'):
        result['frequency'] = packet.frequency
        
    if packet.HasField('vendor'):
        result['vendor'] = packet.vendor
        
    if packet.HasField('signal_level'):
        result['signal_level'] = packet.signal_level
    
    logger.info(f"decode_wifi_packet: Successfully decoded protobuf data")
    return result

def is_wifi_data(data: Dict[str, Any]) -> bool:
    """
    Check if the data appears to be a WiFi packet
    
    Args:
        data: Dictionary containing packet data
        
    Returns:
        True if the data appears to be a WiFi packet
    """
    if data.get('type', '').lower() != 'wifi':
        return False
    
    # Check for WiFi indicators
    return 'ssid' in data or 'channel' in data or 'wifi' in str(data).lower()

def encode_enocean_packet(data: Dict[str, Any]) -> bytes:
    """
    Encode an EnOcean packet to protobuf binary format
    
    Args:
        data: Dictionary containing the EnOcean packet data
        
    Returns:
        Binary protobuf message
    """
    logger.info("encode_enocean_packet: Starting protobuf encoding for EnOcean data")
    
    # Extract device information
    device_id = data.get('deviceId', 'unknown')
    timestamp = datetime.now(timezone.utc).isoformat()
    rssi = data.get('rssi', 0)
    ap_mac = data.get('accessPoint', '')
    
    # Log key values
    logger.info(f"encode_enocean_packet: Device ID: {device_id}, RSSI: {rssi}")
    
    # Extract EnOcean specific data
    eep = data.get('eep', '')
    payload = data.get('payload', '')
    device_name = data.get('deviceName', '')
    
    # Optional sensor data
    temperature = data.get('temperature')
    humidity = data.get('humidity')
    contact_state = data.get('contactState')
    illuminance = data.get('illuminance')
    battery_level = data.get('batteryLevel')
    
    # Create protobuf message
    packet = EnOceanPacket(
        device_id=device_id,
        timestamp=timestamp,
        rssi=rssi,
        eep=eep,
        payload=payload
    )
    
    # Set optional fields only if they're available
    if ap_mac:
        packet.ap_mac = ap_mac
    if device_name:
        packet.device_name = device_name
    
    # Set sensor data if available
    if temperature is not None:
        packet.temperature = float(temperature)
    if humidity is not None:
        packet.humidity = float(humidity)
    if contact_state is not None:
        packet.contact_state = bool(contact_state)
    if illuminance is not None:
        packet.illuminance = float(illuminance)
    if battery_level is not None:
        packet.battery_level = float(battery_level)
    
    # Calculate distance if RSSI is available
    if rssi:
        try:
            import math
            # Basic distance calculation (simplified formula)
            # distance = 10 ^ ((RSSI at 1m - RSSI) / 20)
            # Using -40 as a reference RSSI at 1m for EnOcean
            distance = 10 ** ((-40 - rssi) / 20)
            packet.distance = distance
            logger.info(f"encode_enocean_packet: Calculated distance: {distance:.2f} meters")
        except Exception as e:
            logger.warning(f"encode_enocean_packet: Failed to calculate distance: {e}")
    
    # Serialize to binary
    binary_data = packet.SerializeToString()
    logger.info(f"encode_enocean_packet: Successfully encoded to {len(binary_data)} bytes")
    
    return binary_data

def decode_enocean_packet(binary_data: bytes) -> Dict[str, Any]:
    """
    Decode a protobuf binary message to an EnOcean packet dictionary
    
    Args:
        binary_data: Protobuf binary data
        
    Returns:
        Dictionary with decoded packet data
    """
    logger.info(f"decode_enocean_packet: Decoding {len(binary_data)} bytes of protobuf data")
    
    # Parse protobuf message
    packet = EnOceanPacket()
    packet.ParseFromString(binary_data)
    
    # Convert to dictionary
    result = {
        'type': 'enocean',
        'device_id': packet.device_id,
        'timestamp': packet.timestamp,
        'rssi': packet.rssi,
        'eep': packet.eep,
        'payload': packet.payload
    }
    
    # Add optional fields if present
    if packet.HasField('ap_mac'):
        result['access_point'] = packet.ap_mac
        result['reporter'] = packet.ap_mac
    
    if packet.HasField('device_name'):
        result['device_name'] = packet.device_name
    
    if packet.HasField('distance'):
        result['distance'] = packet.distance
    
    # Add sensor data if present
    if packet.HasField('temperature'):
        result['temperature'] = packet.temperature
    
    if packet.HasField('humidity'):
        result['humidity'] = packet.humidity
    
    if packet.HasField('contact_state'):
        result['contact_state'] = packet.contact_state
    
    if packet.HasField('illuminance'):
        result['illuminance'] = packet.illuminance
    
    if packet.HasField('battery_level'):
        result['battery_level'] = packet.battery_level
    
    logger.info(f"decode_enocean_packet: Successfully decoded protobuf data")
    return result

def is_enocean_data(data: Dict[str, Any]) -> bool:
    """
    Check if the data appears to be an EnOcean packet
    
    Args:
        data: Dictionary containing packet data
        
    Returns:
        True if the data appears to be an EnOcean packet
    """
    if data.get('type', '').lower() != 'enocean':
        return False
    
    # Check for EnOcean indicators
    return 'eep' in data or 'payload' in data or 'enocean' in str(data).lower()
