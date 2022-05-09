import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../components/buttons.dart';
import '../logic/sharing_object.dart';
import '../utils/helper.dart';

// review: done

class DeviceNameEditDialog extends StatefulWidget {
  @override
  _DeviceNameEditDialogState createState() => _DeviceNameEditDialogState();
}

class _DeviceNameEditDialogState extends State<DeviceNameEditDialog> {
  String text = '';

  // todo cancel instead close
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      elevation: 0,
      insetPadding: const EdgeInsets.all(24),
      title: Text(
        'Device Name',
        style: GoogleFonts.getFont(
          context.l.fontComfortaa,
          fontWeight: FontWeight.w700,
        ),
      ),
      scrollable: true,
      content: TextField(
        autofocus: true,
        maxLines: null,
        minLines: 2,
        onChanged: (str) {
          setState(() {
            text = str;
          });
        },
      ),
      actions: [
        DialogTextButton(context.l.generalClose, () {
          Navigator.of(context).pop();
        }),
        DialogTextButton(
          'Okay',
          text.isEmpty
              ? null
              : () => Navigator.of(context).pop(text),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
