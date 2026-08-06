import 'dart:io';

import 'package:flutter/material.dart';

/// Mobile-only implementation: renders an image from a local file path.
Widget fileImage({
  required String path,
  double? width,
  double? height,
  BoxFit? fit,
}) {
  return Image.file(
    File(path),
    width: width,
    height: height,
    fit: fit,
    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
  );
}
