from google.protobuf.internal import containers as _containers
from google.protobuf import descriptor as _descriptor
from google.protobuf import message as _message
from collections.abc import Iterable as _Iterable, Mapping as _Mapping
from typing import ClassVar as _ClassVar, Optional as _Optional, Union as _Union

DESCRIPTOR: _descriptor.FileDescriptor

class IBeaconPacket(_message.Message):
    __slots__ = ("device_mac", "timestamp", "rssi", "uuid", "major", "minor", "tx_power", "ap_mac", "device_name", "distance")
    DEVICE_MAC_FIELD_NUMBER: _ClassVar[int]
    TIMESTAMP_FIELD_NUMBER: _ClassVar[int]
    RSSI_FIELD_NUMBER: _ClassVar[int]
    UUID_FIELD_NUMBER: _ClassVar[int]
    MAJOR_FIELD_NUMBER: _ClassVar[int]
    MINOR_FIELD_NUMBER: _ClassVar[int]
    TX_POWER_FIELD_NUMBER: _ClassVar[int]
    AP_MAC_FIELD_NUMBER: _ClassVar[int]
    DEVICE_NAME_FIELD_NUMBER: _ClassVar[int]
    DISTANCE_FIELD_NUMBER: _ClassVar[int]
    device_mac: str
    timestamp: str
    rssi: int
    uuid: str
    major: int
    minor: int
    tx_power: int
    ap_mac: str
    device_name: str
    distance: float
    def __init__(self, device_mac: _Optional[str] = ..., timestamp: _Optional[str] = ..., rssi: _Optional[int] = ..., uuid: _Optional[str] = ..., major: _Optional[int] = ..., minor: _Optional[int] = ..., tx_power: _Optional[int] = ..., ap_mac: _Optional[str] = ..., device_name: _Optional[str] = ..., distance: _Optional[float] = ...) -> None: ...

class IBeaconPacketCollection(_message.Message):
    __slots__ = ("packets",)
    PACKETS_FIELD_NUMBER: _ClassVar[int]
    packets: _containers.RepeatedCompositeFieldContainer[IBeaconPacket]
    def __init__(self, packets: _Optional[_Iterable[_Union[IBeaconPacket, _Mapping]]] = ...) -> None: ...
