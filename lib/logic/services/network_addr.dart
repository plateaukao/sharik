import 'package:hive_flutter/hive_flutter.dart';

part 'network_addr.g.dart';

@HiveType(typeId: 3)
class NetworkAddr {
  @HiveField(0)
  final String ip;
  @HiveField(1)
  final int port;

  const NetworkAddr({
    required this.ip,
    required this.port,
  });
}