import 'dart:convert';

import 'package:flutter/material.dart';

import 'chat_image_stub.dart' if (dart.library.io) 'chat_image_io.dart' as impl;

/// Renders a chat image: on mobile uses the local file path, on web falls
/// back to the base64 payload. If neither is available, renders nothing.
Widget chatImage({
  required String path,
  required String base64,
  double? width,
  double? height,
  BoxFit? fit,
}) {
  if (base64.isNotEmpty) {
    return Image.memory(
      base64Decode(base64),
      width: width,
      height: height,
      fit: fit,
      gaplessPlayback: true,
    );
  }
  return impl.fileImage(path: path, width: width, height: height, fit: fit);
}
