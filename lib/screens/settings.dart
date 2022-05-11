import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../components/buttons.dart';
import '../components/logo.dart';
import '../components/page_router.dart';
import '../conf.dart';
import '../const.dart';
import '../dialogs/device_name_edit_dialog.dart';
import '../dialogs/open_dialog.dart';
import '../logic/theme.dart';
import '../utils/helper.dart';

// todo tweak colors
// todo checkboxes look weird

class SettingsScreen extends StatelessWidget {
  final _globalKey = GlobalKey();

  void _exit(BuildContext context) {
    SharikRouter.navigateTo(_globalKey, Screens.home, RouteDirection.left);
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _globalKey,
      child: Scaffold(
        body: WillPopScope(
          onWillPop: () {
            _exit(context);
            return Future.value(false);
          },
          child: GestureDetector(
            onHorizontalDragEnd: (DragEndDetails details) {
              if ((details.primaryVelocity ?? 0) > 0) {
                _exit(context);
              }
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                const SafeArea(
                  bottom: false,
                  left: false,
                  right: false,
                  child: SizedBox(height: 12),
                ),
                Stack(
                  children: [
                    Hero(
                      tag: 'icon',
                      child: SharikLogo(),
                    ),
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TransparentButton(
                          const Icon(LucideIcons.chevronLeft, size: 28),
                          () => _exit(context),
                          TransparentButtonBackground.def,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Theme(
                  data: context.t.copyWith(
                    splashColor: context.t.dividerColor.withOpacity(0.08),
                    highlightColor: Colors.transparent,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 720) {
                        return Column(
                          children: [
                            _appearanceSection(context),
                          ],
                        );
                      } else {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _appearanceSection(context)),
                          ],
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _appearanceSection(BuildContext context) {
    final box = Hive.box<String>('strings');
    const transition = 'disable_transition_effects';
    const blur = 'disable_blur';

    return Column(
      children: [
        _appearanceTitle(context),
        const SizedBox(height: 14),
        _themeItemWidget(context),
        const SizedBox(height: 8),
        _screenTransitionWidget(context, box, transition),
        const SizedBox(height: 8),
        _blurItemWidget(context, box, blur),
        const SizedBox(height: 14),
        _deviceNameTitle(context),
        const SizedBox(height: 14),
        _deviceNameEdit(context, box),
      ],
    );
  }

  Text _appearanceTitle(BuildContext context) {
    return Text(
        context.l.settingsAppearance,
        textAlign: TextAlign.center,
        style: GoogleFonts.getFont(
          context.l.fontComfortaa,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      );
  }
  Text _deviceNameTitle(BuildContext context) {
    return Text(
      'Device Name',
      textAlign: TextAlign.center,
      style: GoogleFonts.getFont(
        context.l.fontComfortaa,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  ListTile _blurItemWidget(BuildContext context, Box<String> box, String blur) {
    return ListTile(
        hoverColor: context.t.dividerColor.withOpacity(0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        leading: const Icon(LucideIcons.palette),
        onTap: () {
          box.put(blur, box.get(blur, defaultValue: '0')! == '0' ? '1' : '0');
        },
        title: Text(
          context.l.settingsDisableBlur,
          style: GoogleFonts.getFont(context.l.fontAndika),
        ),
        trailing: StreamBuilder<BoxEvent>(
          stream: box.watch(key: blur),
          initialData:
              BoxEvent(blur, box.get(blur, defaultValue: '0'), false),
          builder: (_, snapshot) => Checkbox(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            value: snapshot.data!.value as String == '1',
            onChanged: (val) {
              box.put(blur, val! ? '1' : '0');
            },
            activeColor: Colors.deepPurple.shade300,
          ),
        ),
      );
  }

  ListTile _screenTransitionWidget(BuildContext context, Box<String> box, String transition) {
    return ListTile(
        hoverColor: context.t.dividerColor.withOpacity(0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        leading: const Icon(LucideIcons.move),
        onTap: () {
          box.put(
            transition,
            box.get(transition, defaultValue: '0')! == '0' ? '1' : '0',
          );
        },
        title: Text(
          context.l.settingsDisableScreenTransitions,
          style: GoogleFonts.getFont(context.l.fontAndika),
        ),
        trailing: StreamBuilder<BoxEvent>(
          stream: box.watch(key: transition),
          initialData: BoxEvent(
            transition,
            box.get(transition, defaultValue: '0'),
            false,
          ),
          builder: (_, snapshot) => Checkbox(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            value: snapshot.data!.value as String == '1',
            onChanged: (val) {
              box.put(transition, val! ? '1' : '0');
            },
            activeColor: Colors.deepPurple.shade300,
          ),
        ),
      );
  }

  ListTile _themeItemWidget(BuildContext context) {
    return ListTile(
        hoverColor: context.t.dividerColor.withOpacity(0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        leading: const Icon(LucideIcons.sun),
        onTap: () {
          context.read<ThemeManager>().change();
        },
        title: Text(
          context.l.settingsTheme,
          style: GoogleFonts.getFont(context.l.fontAndika),
        ),
        trailing: Text(
          context.watch<ThemeManager>().name(context),
          style: GoogleFonts.getFont(context.l.fontComfortaa),
        ),
      );
  }

  ListTile _deviceNameEdit(BuildContext context, Box<String> box) {
    return ListTile(
      hoverColor: context.t.dividerColor.withOpacity(0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      leading: const Icon(LucideIcons.pencil),
      onTap: () => _editDeviceName(context, box),
      title: StreamBuilder<BoxEvent>(
        stream: box.watch(key: keyDeviceName),
        initialData: BoxEvent(
          keyDeviceName,
          box.get(keyDeviceName, defaultValue: notDefined),
          false,
        ),
        builder: (_, snapshot) => Text(
          box.get(keyDeviceName, defaultValue: notDefined) ?? notDefined,
          style: GoogleFonts.getFont(context.l.fontAndika),
        ),
      ),
    );
  }

  Future<void> _editDeviceName(BuildContext context, Box<String> box) async {
    final text = await showDialog<String?>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      builder: (_) => DeviceNameEditDialog(),
    );

    if (text != null) {
      box.put('deviceName', text);
    }
  }
}
