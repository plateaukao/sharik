import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock/wakelock.dart';

import '../components/buttons.dart';
import '../logic/services/receiver_service.dart';
import '../logic/sharing_object.dart';
import '../utils/helper.dart';
import 'open_dialog.dart';
import 'select_network.dart';

// review: done

class ReceiverDialog extends StatefulWidget {
  @override
  _ReceiverDialogState createState() => _ReceiverDialogState();
}

class _ReceiverDialogState extends State<ReceiverDialog> {
  final ReceiverService receiverService = ReceiverService()..init();

  @override
  void initState() {
    if (!Platform.isLinux) {
      Wakelock.enable();
    }

    super.initState();
  }

  @override
  void dispose() {
    receiverService.kill();
    if (!Platform.isLinux) {
      Wakelock.disable();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: receiverService,
      builder: (context, _) {
        context.watch<ReceiverService>();

        return AlertDialog(
          scrollable: true,
          elevation: 0,
          insetPadding: const EdgeInsets.all(24),
          title: _titleWidget(context),
          content: receiverService.receivers.isEmpty
              ? const Text('receiving...')
              : _mainWidget(context),
          actions: [
            _networkInterfaceButton(context),
            _closeButton(context),
            const SizedBox(width: 4),
          ],
        );
      },
    );
  }

  Text _titleWidget(BuildContext context) =>
      Text(
        context.l.sharingReceiver,
        style: GoogleFonts.getFont(
          context.l.fontComfortaa,
          fontWeight: FontWeight.w700,
        ),
      );

  DialogTextButton _networkInterfaceButton(BuildContext context) =>
      DialogTextButton(
        context.l.sharingNetworkInterfaces,
        receiverService.loaded
            ? () async {
          await openDialog(
            context,
            PickNetworkDialog(receiverService.ipService),
          );
        }
            : null,
      );

  DialogTextButton _closeButton(BuildContext context) =>
      DialogTextButton(context.l.generalClose, () {
        Navigator.of(context).pop();
      });

  SizedBox _mainWidget(BuildContext context) =>
      SizedBox(
        width: double.maxFinite,
        child: Column(
          children: [
            SizedBox(
              height: receiverService.receivers.length * 60,
              child: Theme(
                data: context.t.copyWith(
                  splashColor:
                  context.t.dividerColor.withOpacity(0.08),
                  highlightColor: Colors.transparent,
                ),
                child: _receivedListWidget(context),
              ),
            ),
          ],
        ),
      );

  ListView _receivedListWidget(BuildContext context) =>
      ListView.builder(
        itemCount: receiverService.receivers.length,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (_, e) {
          final receivedObject = receiverService.receivers[e];
          return ListTile(
            hoverColor:
            context.t.dividerColor.withOpacity(0.04),
            // todo text styling
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: Icon(
              SharingObject(
                name: receivedObject.name,
                data: receivedObject.name,
                type: receivedObject.type,
              ).icon,
            ),
            // todo style colors
            title: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(receivedObject.name, style: GoogleFonts.getFont('Andika')),
            ),
            subtitle: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                '${receivedObject.deviceName ?? ''} • ${receivedObject.os} • ${receivedObject.addr.ip}:${receivedObject.addr.port}',
                style: GoogleFonts.getFont('Andika'),
              ),
            ),
            onTap: () => _useReceivedObject(receivedObject),
          );
        },
      );

  void _useReceivedObject(Receiver receiver) {
    final name = receiver.name;
    switch(receiver.type) {
      case SharingObjectType.text:
        if (name.startsWith('http')) {
          launchUrl(Uri.parse(name), mode: LaunchMode.externalApplication);
        } else {
          Clipboard.setData(ClipboardData(text: name));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Text is copied!')),
          );
        }
        Navigator.of(context).pop();
        break;
      default:
        launchUrl(Uri.parse('http://${receiver.addr.ip}:${receiver.addr.port}'), mode: LaunchMode.externalApplication);
    }
  }

  SizedBox _loadingWidget(BuildContext context) =>
      SizedBox(
        height: 42,
        child: Center(
          child: Stack(
            children: [
              Center(
                child: SizedBox(
                  height: 42,
                  width: 42,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(
                      context.t.colorScheme.secondary
                          .withOpacity(0.8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
