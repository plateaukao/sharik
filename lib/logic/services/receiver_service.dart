import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

import '../../conf.dart';
import '../../const.dart';
import '../../screens/loading.dart';
import '../sharing_object.dart';
import 'ip_service.dart';
import 'network_addr.dart';

class ReceiverService extends ChangeNotifier {
  final ipService = LocalIpService();

  // todo SharingObject instead
  final List<Receiver> receivers = [];

  bool loaded = false;

  void kill() {
    loaded = false;
    _rawDatagramSocket?.close();
    _rawDatagramSocket = null;
  }

  Future<void> init() async {
    await ipService.load();
    loaded = true;
    notifyListeners();

    _rawDatagramSocket = await _listenToBroadcast();

  }

  RawDatagramSocket? _rawDatagramSocket;
  Future<RawDatagramSocket> _listenToBroadcast() async {
    final multicastAddress = InternetAddress(broadcastInternetAddress);
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, multicastPort);
    socket.joinMulticast(multicastAddress);

    socket.listen((RawSocketEvent e) async {
      final datagram = socket.receive();
      if (datagram == null) return;

      final message = String.fromCharCodes(datagram.data).trim();
      final networkAddr = NetworkAddr(ip: datagram.address.address, port: int.parse(message));
      final sharikData = await _hasSharik(networkAddr);
      if (sharikData!=null) {
        receivers.add(sharikData);
        notifyListeners();
        _rawDatagramSocket?.close();
        _rawDatagramSocket = null;
      }
    });

    return socket;
  }

  static Future<Receiver?> _hasSharik(NetworkAddr addr) async {
    try {
      final result = await http
          .get(Uri.parse('http://${addr.ip}:${addr.port}/sharik.json'))
          .timeout(const Duration(seconds: 3));

      print('${addr.ip}:${addr.port}: ${result.body}');
      return Receiver.fromJson(addr: addr, json: result.body);
    } catch (error) {
      print('${addr.ip}:${addr.port}: $error');
      return null;
    }
  }
}

class Receiver {
  final NetworkAddr addr;

  final String os;
  final String name;
  final String? deviceName;
  final SharingObjectType type;

  const Receiver({
    required this.addr,
    required this.os,
    required this.name,
    required this.type,
    this.deviceName,
  });

  factory Receiver.fromJson({required NetworkAddr addr, required String json}) {
    final parsed = jsonDecode(json);

    return Receiver(
      addr: addr,
      os: parsed['os'] as String,
      name: parsed['name'] as String,
      type: string2fileType(parsed['type'] as String),
      deviceName: parsed['deviceName'] as String?,
    );
  }
}
