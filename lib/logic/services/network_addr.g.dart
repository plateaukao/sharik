// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_addr.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NetworkAddrAdapter extends TypeAdapter<NetworkAddr> {
  @override
  final int typeId = 3;

  @override
  NetworkAddr read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NetworkAddr(
      ip: fields[0] as String,
      port: fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, NetworkAddr obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.ip)
      ..writeByte(1)
      ..write(obj.port);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NetworkAddrAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
