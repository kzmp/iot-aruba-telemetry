from google.protobuf.internal import containers as _containers
from google.protobuf import descriptor as _descriptor
from google.protobuf import message as _message
from collections.abc import Iterable as _Iterable, Mapping as _Mapping
from typing import ClassVar as _ClassVar, Optional as _Optional, Union as _Union

DESCRIPTOR: _descriptor.FileDescriptor

class EnOceanPacket(_message.Message):
    __slots__ = ("device_id", "timestamp", "rssi", "eep", "payload", "ap_mac", "device_name", "distance", "temperature", "humidity", "contact_state", "illuminance", "battery_level")
    DEVICE_ID_FIELD_NUMBER: _ClassVar[int]
    TIMESTAMP_FIELD_NUMBER: _ClassVar[int]
    RSSI_FIELD_NUMBER: _ClassVar[int]
    EEP_FIELD_NUMBER: _ClassVar[int]
    PAYLOAD_FIELD_NUMBER: _ClassVar[int]
    AP_MAC_FIELD_NUMBER: _ClassVar[int]
    DEVICE_NAME_FIELD_NUMBER: _ClassVar[int]
    DISTANCE_FIELD_NUMBER: _ClassVar[int]
    TEMPERATURE_FIELD_NUMBER: _ClassVar[int]
    HUMIDITY_FIELD_NUMBER: _ClassVar[int]
    CONTACT_STATE_FIELD_NUMBER: _ClassVar[int]
    ILLUMINANCE_FIELD_NUMBER: _ClassVar[int]
    BATTERY_LEVEL_FIELD_NUMBER: _ClassVar[int]
    device_id: str
    timestamp: str
    rssi: int
    eep: str
    payload: str
    ap_mac: str
    device_name: str
    distance: float
    temperature: float
    humidity: float
    contact_state: bool
    illuminance: float
    battery_level: float
    def __init__(self, device_id: _Optional[str] = ..., timestamp: _Optional[str] = ..., rssi: _Optional[int] = ..., eep: _Optional[str] = ..., payload: _Optional[str] = ..., ap_mac: _Optional[str] = ..., device_name: _Optional[str] = ..., distance: _Optional[float] = ..., temperature: _Optional[float] = ..., humidity: _Optional[float] = ..., contact_state: bool = ..., illuminance: _Optional[float] = ..., battery_level: _Optional[float] = ...) -> None: ...

class EnOceanPacketCollection(_message.Message):
    __slots__ = ("packets",)
    PACKETS_FIELD_NUMBER: _ClassVar[int]
    packets: _containers.RepeatedCompositeFieldContainer[EnOceanPacket]
    def __init__(self, packets: _Optional[_Iterable[_Union[EnOceanPacket, _Mapping]]] = ...) -> None: ...
