
import 'package:flutter/material.dart';

import '../logic/sharing_object.dart';

// todo not only file model but generic interface
Future<SharingObject?> openDialog(
    BuildContext context,
    Widget dialog, {
      bool dismissible = true,
    }
) {
  return showDialog(
    context: context,
    barrierDismissible: dismissible,
    barrierLabel: 'Close',
    builder: (_) => dialog,
  );
}
