
import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../components/buttons.dart';
import '../components/logo.dart';
import '../components/page_router.dart';
import '../conf.dart';
import '../dialogs/open_dialog.dart';
import '../dialogs/receive.dart';
import '../dialogs/share_app.dart';
import '../dialogs/share_text.dart';
import '../logic/sharing_object.dart';
import '../utils/helper.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<SharingObject> _history = <SharingObject>[];
  final _globalKey = GlobalKey();

  @override
  void initState() {
    _history = Hive.box<SharingObject>('history').values.toList();

    super.initState();
  }

  Future<void> _saveLatest() async {
    await Hive.box<SharingObject>('history').clear();
    await Hive.box<SharingObject>('history').addAll(_history);
  }

  Future<void> _shareFile(SharingObject file) async {
    setState(() {
      _history.removeWhere((element) => element.name == file.name);

      _history.insert(0, file);
    });

    await _saveLatest();

    SharikRouter.navigateTo(
      _globalKey,
      Screens.sharing,
      RouteDirection.right,
      file,
    );
  }

  bool _dragging = false;

  @override
  Widget build(BuildContext c) {
    return DropTarget(
      onDragDone: (detail) {
        if (detail.files.isNotEmpty) {
          _handleDroppedFile(detail.files);
        }
      },
      onDragEntered: (detail) {
        setState(() {
          _dragging = true;
        });
      },
      onDragExited: (detail) {
        setState(() {
          _dragging = false;
        });
      },
      child: _mainContentWidget(c),
    );
  }

  void _handleDroppedFile(List<XFile> xFiles) {
    // final sharingObject = SharingObject(
    //     data: xFile.path,
    //     type: SharingObjectType.file,
    //     name: SharingObject.getSharingName(
    //       SharingObjectType.file,
    //       xFile.path,),
    // );
    final pathsString = xFiles.map((f) => f.path).toList().join(multipleFilesDelimiter);
    final sharingObject = SharingObject(
        data: pathsString,
        type: SharingObjectType.file,
        name: SharingObject.getSharingName(SharingObjectType.file, pathsString),
    );
    _shareFile(sharingObject);
  }

  Widget _mainContentWidget(BuildContext c) => RepaintBoundary(
    key: _globalKey,
    child: Scaffold(
      body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SafeArea(
              bottom: false,
              left: false,
              right: false,
              child: SizedBox(
                height: 12,
              ),
            ),
            Hero(
              tag: 'icon',
              child: SharikLogo(),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // todo review constraints
                  if (constraints.maxWidth < 720) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        children: [
                          _sharingButtons(c),
                          const SizedBox(
                            height: 12,
                          ),
                          Expanded(
                            child: _sharingHistoryList(c),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(width: 12),
                        Expanded(child: _sharingButtons(c)),
                        const SizedBox(width: 12),
                        Expanded(child: _sharingHistoryList(c)),
                        const SizedBox(width: 12),
                      ],
                    );
                  }
                },
              ),
            ),
            _bottomBar(),
            Container(
              color: Colors.deepPurple.shade100,
              child: SafeArea(
                top: false,
                right: false,
                left: false,
                child: Container(),
              ),
            )
          ],
        ),
      ),
    );

  Container _bottomBar() {
    return Container(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            height: 64,
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                TransparentButton(
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: Icon(
                      LucideIcons.languages,
                      color: Colors.deepPurple.shade700,
                      size: 20,
                    ),
                  ),
                      () => SharikRouter.navigateTo(
                    _globalKey,
                    Screens.languagePicker,
                    RouteDirection.left,
                  ),
                  TransparentButtonBackground.purpleLight,
                ),
                const SizedBox(width: 2),
                TransparentButton(
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: Icon(
                      LucideIcons.settings,
                      color: Colors.deepPurple.shade700,
                      size: 20,
                    ),
                  ),
                      () => SharikRouter.navigateTo(
                    _globalKey,
                    Screens.settings,
                    RouteDirection.right,
                  ),
                  TransparentButtonBackground.purpleLight,
                ),
                const Spacer(),
                Text(
                  'sharik v$currentVersion',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 16,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
              ],
            ),
          );
  }

  Widget _sharingHistoryList(BuildContext c) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      // shrinkWrap: true,
      // todo there's probably a more elegant way to do this
      itemCount: _history.length + 1,
      itemBuilder: (context, index) => index == 0
          ? _sharingHistoryHeader(c)
          : _card(context, _history[index - 1]),
    );
  }

  Widget _sharingHistoryHeader(BuildContext c) {
    if (_history.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Text(
              c.l.homeHistory,
              style: GoogleFonts.getFont(c.l.fontComfortaa, fontSize: 24),
            ),
            const Spacer(),
            TransparentButton(
              const Icon(LucideIcons.trash),
              () {
                setState(() => _history.clear());

                _saveLatest();
              },
              TransparentButtonBackground.purpleDark,
            )
          ],
        ),
      );
    } else {
      return const SizedBox();
    }
  }

  Widget _sharingButtons(BuildContext c) {
    return Column(
      children: [
        _sendFileButton(c),
        const SizedBox(height: 12),
        _sendTextButton(c),
        if (Platform.isAndroid || Platform.isIOS) const SizedBox(height: 12),
        if (Platform.isAndroid) _sendAppButton(c),
        if (Platform.isIOS) _sendImageButton(c),
        const SizedBox(height: 12),
        _receiverButton(c)
      ],
    );
  }

  PrimaryButton _receiverButton(BuildContext c) {
    return PrimaryButton(
        height: 60,
        onClick: () async {
          openDialog(context, ReceiverDialog());
        },
        text: c.l.homeReceive,
      );
  }

  PrimaryButton _sendFileButton(BuildContext c) {
    return PrimaryButton(
        height: 60,
        onClick: () => _chooseFileToSend(),
        text: c.l.homeSelectFile,
        secondaryIcon: Icon(
          LucideIcons.send,
          size: 42,
          color: Colors.deepPurple.shade200.withOpacity(0.8),
        ),
      );
  }

  PrimaryButton _sendTextButton(BuildContext c) {
    return PrimaryButton(
      height: 60,
      onClick: () async {
        final text = await openDialog(context, ShareTextDialog());
        if (text != null) {
          _shareFile(text);
        }
      },
      text: c.l.homeSelectText,
      secondaryIcon: Icon(
        LucideIcons.textCursorInput,
        size: 42,
        color: Colors.deepPurple.shade200.withOpacity(0.8),
      ),
    );
  }

  PrimaryButton _sendAppButton(BuildContext c) {
    return PrimaryButton(
      height: 60,
      onClick: () async {
        final f = await openDialog(context, ShareAppDialog());
        if (f != null) {
          _shareFile(f);
        }
      },
      text: c.l.homeSelectApp,
      secondaryIcon: Icon(
        LucideIcons.fileDigit,
        size: 42,
        color: Colors.deepPurple.shade200.withOpacity(0.8),
      ),
    );
  }

  PrimaryButton _sendImageButton(BuildContext c) {
    return PrimaryButton(
      height: 60,
      onClick: () async {
        final f = await FilePicker.platform
            .pickFiles(type: FileType.media, allowMultiple: true);

        if (f != null) {
            final object = SharingObject(
              data: f.paths.join(multipleFilesDelimiter),
              type: SharingObjectType.file,
              name: SharingObject.getSharingName(
                SharingObjectType.file,
                f.paths.join(multipleFilesDelimiter),
              ),
            );
            _shareFile(object);
        }
      },
      text: '${c.l.homeSend} ${c.l.homeSelectApp}',
      secondaryIcon: Icon(
        LucideIcons.fileDigit,
        size: 42,
        color: Colors.deepPurple.shade200.withOpacity(0.8),
      ),
    );
  }

  Widget _card(BuildContext c, SharingObject f) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ListButton(
        Row(
          children: [
            Icon(
              f.icon,
              size: 22,
              color: Colors.grey.shade100,
              // semanticsLabel: 'file',
              // width: 18,
            ),
            const SizedBox(
              width: 12,
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  f.name,
                  style: GoogleFonts.getFont(
                    c.l.fontAndika,
                    color: Colors.white,
                    fontSize: 18,
                  ),
                  maxLines: 1,
                ),
              ),
            )
          ],
        ),
        () => _shareFile(f),
      ),
    );
  }

  Future<void>_chooseFileToSend() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final f = await FilePicker.platform.pickFiles(allowMultiple: true);

      if (f != null) {
          final object = SharingObject(
            data: f.paths.join(multipleFilesDelimiter),
            type: SharingObjectType.file,
            name: SharingObject.getSharingName(
              SharingObjectType.file,
              f.paths.join(multipleFilesDelimiter),
            ),
          );
          _shareFile(object);
      }
    } else {
      final f = await openFiles();
      if (f.isNotEmpty) {
        final data =
        f.map((e) => e.path).join(multipleFilesDelimiter);
        final object = SharingObject(
          data: data,
          type: SharingObjectType.file,
          name: SharingObject.getSharingName(
            SharingObjectType.file,
            data,
          ),
        );
        _shareFile(object);
      }
    }
  }
}
