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
      if (message.startsWith('http')) {
        final networkAddr = NetworkAddr(ip: datagram.address.address, port: multicastPort);
        receivers.add(Receiver(addr: networkAddr, os: 'EinkBro', name: message , type: SharingObjectType.text));
        notifyListeners();
      } else {
        final sharikData = Receiver.fromJson(ip: datagram.address.address, json: message);
        receivers.add(sharikData);
        notifyListeners();

        final deviceName = Hive.box<String>('strings').get(keyDeviceName);
        socket.send('$deviceName'.codeUnits, datagram.address, datagram.port);
      }
      _rawDatagramSocket?.close();
      _rawDatagramSocket = null;
    });

    return socket;
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

  factory Receiver.fromJson({required String ip, required String json}) {
    final parsed = jsonDecode(json);

    return Receiver(
      addr: NetworkAddr(ip: ip, port: parsed['port'] as int),
      os: parsed['os'] as String,
      name: parsed['name'] as String,
      type: string2fileType(parsed['type'] as String),
      deviceName: parsed['deviceName'] as String?,
    );
  }
}
