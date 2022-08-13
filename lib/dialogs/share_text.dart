import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../components/buttons.dart';
import '../logic/sharing_object.dart';
import '../utils/helper.dart';

// review: done

class ShareTextDialog extends StatefulWidget {
  @override
  _ShareTextDialogState createState() => _ShareTextDialogState();
}

class _ShareTextDialogState extends State<ShareTextDialog> {
  String text = '';
  final TextEditingController _controller = TextEditingController();

  // todo cancel instead close
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      elevation: 0,
      insetPadding: const EdgeInsets.all(24),
      title: Row(
        children: [
          Text(
            context.l.homeSelectTextTypeSomeText,
            style: GoogleFonts.getFont(
              context.l.fontComfortaa,
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.clipboard),
            onPressed: () {
              Clipboard.getData('text/plain').then((data) {
                setState(() {
                  _controller.text = data?.text ?? '';
                  text = _controller.text;
                });
              });
            },
          ),
        ],
      ),
      scrollable: true,
      content: TextField(
        controller: _controller,
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
          context.l.generalSend,
          text.isEmpty
              ? null
              : () {
                  Navigator.of(context).pop(
                    SharingObject(
                      data: text,
                      type: SharingObjectType.text,
                      name: SharingObject.getSharingName(
                        SharingObjectType.text,
                        text,
                      ),
                    ),
                  );
                },
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
