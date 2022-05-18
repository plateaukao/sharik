import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:widget_to_image/widget_to_image.dart';

import '../conf.dart';
import '../main.dart';

class SharikRouter extends PageRouteBuilder {
  final Widget enterPage;
  final Widget exitPageImage;
  final RouteDirection direction;

  SharikRouter({
    required this.exitPageImage,
    required this.enterPage,
    required this.direction,
  }) : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) => enterPage,
        );

  static Future<void> navigateTo(
    GlobalKey screenKey,
    Screens screen,
    RouteDirection direction, [
    Object? args,
  ]) async {
    navigateToFromImage(ByteData(0).buffer.asUint8List(), screen, direction, args);
  }

  static Future<void> navigateToFromImage(
    Uint8List data,
    Screens screen,
    RouteDirection direction, [
    Object? args,
      ]) async {
    navigatorKey.currentState!.pushReplacement(
      SharikRouter(
        exitPageImage: Image.memory(data),
        enterPage: screen2widget(screen, args),
        direction: direction,
      ),
    );
  }
}

enum RouteDirection { left, right }
