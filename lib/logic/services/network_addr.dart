import 'package:hive_flutter/hive_flutter.dart';

class NetworkAddr {
  final String ip;
  final int port;

  const NetworkAddr({
    required this.ip,
    required this.port,
  });
}