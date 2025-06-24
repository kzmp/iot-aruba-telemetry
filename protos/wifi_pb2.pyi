from google.protobuf.internal import containers as _containers
from google.protobuf import descriptor as _descriptor
from google.protobuf import message as _message
from collections.abc import Iterable as _Iterable, Mapping as _Mapping
from typing import ClassVar as _ClassVar, Optional as _Optional, Union as _Union

DESCRIPTOR: _descriptor.FileDescriptor

class WiFiPacket(_message.Message):
    __slots__ = ("device_mac", "timestamp", "rssi", "ssid", "channel", "ap_mac", "device_name", "distance", "security", "frequency", "vendor", "signal_level")
    DEVICE_MAC_FIELD_NUMBER: _ClassVar[int]
    TIMESTAMP_FIELD_NUMBER: _ClassVar[int]
    RSSI_FIELD_NUMBER: _ClassVar[int]
    SSID_FIELD_NUMBER: _ClassVar[int]
    CHANNEL_FIELD_NUMBER: _ClassVar[int]
    AP_MAC_FIELD_NUMBER: _ClassVar[int]
    DEVICE_NAME_FIELD_NUMBER: _ClassVar[int]
    DISTANCE_FIELD_NUMBER: _ClassVar[int]
    SECURITY_FIELD_NUMBER: _ClassVar[int]
    FREQUENCY_FIELD_NUMBER: _ClassVar[int]
    VENDOR_FIELD_NUMBER: _ClassVar[int]
    SIGNAL_LEVEL_FIELD_NUMBER: _ClassVar[int]
    device_mac: str
    timestamp: str
    rssi: int
    ssid: str
    channel: int
    ap_mac: str
    device_name: str
    distance: float
    security: str
    frequency: int
    vendor: str
    signal_level: int
    def __init__(self, device_mac: _Optional[str] = ..., timestamp: _Optional[str] = ..., rssi: _Optional[int] = ..., ssid: _Optional[str] = ..., channel: _Optional[int] = ..., ap_mac: _Optional[str] = ..., device_name: _Optional[str] = ..., distance: _Optional[float] = ..., security: _Optional[str] = ..., frequency: _Optional[int] = ..., vendor: _Optional[str] = ..., signal_level: _Optional[int] = ...) -> None: ...

class WiFiPacketCollection(_message.Message):
    __slots__ = ("packets",)
    PACKETS_FIELD_NUMBER: _ClassVar[int]
    packets: _containers.RepeatedCompositeFieldContainer[WiFiPacket]
    def __init__(self, packets: _Optional[_Iterable[_Union[WiFiPacket, _Mapping]]] = ...) -> None: ...
