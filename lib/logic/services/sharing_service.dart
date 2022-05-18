import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../conf.dart';
import '../../const.dart';
import '../../utils/helper.dart';
import '../sharing_object.dart';

class SharingService extends ChangeNotifier {
  final SharingObject _file;
  int? _port;
  HttpServer? _server;
  final BuildContext _context;
  Timer? _aliveTimer;

  int? get port => _port;

  bool get running => _port != null;

  String? _receivedInfo;
  String? get receivedInfo => _receivedInfo;

  SharingService(this._file, this._context);

  Future<bool> _isPortFree(int port) async {
    try {
      final _ = await HttpServer.bind(InternetAddress.anyIPv4, port);
      await _.close(force: true);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<int> _getPrettyPort() async {
    for (final el in ports) {
      if (await _isPortFree(el)) {
        return el;
      }
    }

    final _ = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    final port = _.port;
    await _.close(force: true);
    return port;
  }

  Future<Timer> _broadcastAlive(int port) async {
    final multicastAddress = InternetAddress(broadcastInternetAddress);
    final rawDatagramSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    rawDatagramSocket.listen((event) {
      final datagram = rawDatagramSocket.receive();
      if (datagram == null) return;

      final message = String.fromCharCodes(datagram.data).trim();
      _receivedInfo = '$message (${datagram.address.address}) got it.';
      notifyListeners();
    });

    // send out sharik json string
    final jsonString = _createSharikJsonString(port);
    return Timer.periodic(const Duration(seconds: 1), (Timer t) {
      rawDatagramSocket.send(jsonString.codeUnits, multicastAddress, multicastPort);
    });
  }

  Future<void> start() async {
    _port = await _getPrettyPort();
    _server = await HttpServer.bind(InternetAddress.anyIPv4, _port!);
    _aliveTimer = await _broadcastAlive(_port!);

    _serve();
    notifyListeners();
  }

  Future<void> end() async {
    _aliveTimer?.cancel();
    _aliveTimer = null;
    await _server!.close(force: true);
    _server = null;

    if (Platform.isAndroid || Platform.isIOS) {
      FilePicker.platform.clearTemporaryFiles();
    }
  }

  Future<void> _serve() async {
    if (_server == null) {
      throw Exception('Server was not initialized');
    }

    await for (final request in _server!) {
      if (_isFaviconUrl(request)) {
        await _serveFavicon(request);
        continue;
      }

      if (_file.type == SharingObjectType.text) {
        _serveText(request);
        continue;
      }

      if (_isSingleFile()) {
        await _serveSingleFile(request);
        continue;
      }

      await _serveOtherCases(request);
    }
  }

  Future<void> _serveOtherCases(HttpRequest request) async {
    final fileList = _file.data.split(multipleFilesDelimiter);

    final requestedFilePath = request.requestedUri.queryParameters['q'] ?? '';
    File? file;
    int? size;
    var isDir = false;

    // if the file is requested
    if (requestedFilePath.isNotEmpty) {
      isDir = await FileSystemEntity.type(requestedFilePath) ==
          FileSystemEntityType.directory;
      // todo is that secure enough?
      if (!fileList.contains(requestedFilePath)) {
        // checking if the path belongs to a shared folder
        var isInsideAFolder = false;
        for (final el in fileList) {
          if (requestedFilePath.contains(el)) {
            isInsideAFolder = true;
          }
        }

        if (!isInsideAFolder) {
          print('NO ACCESS!!!');
          return ;
        }
      }

      if (!isDir) {
        file = File(requestedFilePath);
        size = await file.length();
      }
    }

    // We are sharing multiple files
    // Serving an entry html page or the folder page
    if (requestedFilePath.isEmpty || isDir) {
      final _fileList = isDir
          ? Directory(requestedFilePath)
              .listSync()
              .map((e) => e.path)
              .toList()
          : fileList;

      final displayFiles = Map.fromEntries(
        _fileList.map(
          (e) => MapEntry(
            e,
            FileSystemEntity.typeSync(e) != FileSystemEntityType.directory,
          ),
        ),
      );

      request.response.headers.contentType =
          ContentType('text', 'html', charset: 'utf-8');
      request.response
          .write(_buildHTML(displayFiles, _context.l.shareDownloadAllButton));
      request.response.close();
      // Serving the files
    } else {
      _pipeFile(
        request,
        file,
        size,
        requestedFilePath.split(Platform.pathSeparator).last,
      );
    }
  }

  bool _isSingleFile() {
    return !_file.data.contains(multipleFilesDelimiter) &&
        FileSystemEntity.typeSync(_file.data) != FileSystemEntityType.directory;
  }

  bool _isFaviconUrl(HttpRequest request) {
    return request.requestedUri.toString().split('/').length == 4 &&
        request.requestedUri.toString().split('/').last == 'favicon.ico';
  }

  Future<void> _serveSingleFile(HttpRequest request) async {
    final f = File(_file.data);
    final size = await f.length();

    _pipeFile(
      request,
      f,
      size,
      _file.type == SharingObjectType.file
          ? _file.name
          : '${_file.name}.apk',
    );
  }

  void _serveText(HttpRequest request) {
    request.response.headers.contentType =
        ContentType('text', 'plain', charset: 'utf-8');
    request.response.write(_file.data);
    request.response.close();
  }

  String _createSharikJsonString(int port) {
    return jsonEncode({
      'sharik': currentVersion,
      'type': _file.type.toString().split('.').last,
      'name': _file.name,
      'os': Platform.operatingSystem,
      'port': port,
      'deviceName': Hive.box<String>('strings').get(keyDeviceName),
    });
  }

  Future<void> _serveFavicon(HttpRequest request) async {
    request.response.headers.contentType =
        ContentType('image', 'x-icon', charset: 'utf-8');

    final favicon = await rootBundle.load('assets/favicon.ico');

    request.response.add(favicon.buffer.asUint8List());
    request.response.close();
  }
}

Future<void> _pipeFile(
  HttpRequest request,
  File? file,
  int? size,
  String fileName,
) async {
  request.response.headers.contentType =
      ContentType('application', 'octet-stream', charset: 'utf-8');

  request.response.headers.add(
    'Content-Transfer-Encoding',
    'Binary',
  );

  request.response.headers.add(
    'Content-disposition',
    'attachment; filename="${Uri.encodeComponent(fileName)}"',
  );

  if (size != null) {
    request.response.headers.add(
      'Content-length',
      size,
    );
  }

  await file!.openRead().pipe(request.response).catchError((e) {}).then((a) {
    request.response.close();
  });
}

/// bool - true if the path is a file; false if it's a folder
String _buildHTML(Map<String, bool> files, String downloadButtonText) {
  final html = '''
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Sharik</title>
  </head>
  <body>
    <button onClick="downloadAll()">$downloadButtonText</button>
    <ul style="line-height:200%">
      ${files.entries.map((val) => '<li><a href="/?q=${Uri.decodeComponent(val.key)}" class="${val.value ? 'file' : 'folder'}"><b>${val.key.split(Platform.pathSeparator).last}</b> <small>(${val.key})</small></li></a>').join('\n')}
    </ul>
    
    <script>
    // Adapted from https://web.archive.org/web/20210805125534/https://developpaper.com/question/how-to-download-multiple-url-files-with-js/ 
    
    let triggerDelay = 100;
    let removeDelay = 1000; 
    
    function downloadAll(){
      var arr = [].slice.call(document.getElementsByClassName('file'));
      arr.forEach(function(item,index){
        _createIFrame(item.href, index * triggerDelay, removeDelay);
      });
    }
    
    function _createIFrame(url, triggerDelay, removeDelay) {
      setTimeout(function() {
        var node = document.createElement("iframe");
        node.setAttribute("style", "display: none;");
        node.setAttribute("src", url);
        document.body.appendChild(node);
    
        setTimeout(function() {
            node.remove();
        }, removeDelay);
        
      }, triggerDelay);
    } 
    </script>
  </body>
</html>
  ''';

  return html;
}
