import 'package:flutter/material.dart';

/// Web fallback: file paths are unavailable on the web platform.
Widget fileImage({
  required String path,
  double? width,
  double? height,
  BoxFit? fit,
}) {
  return const SizedBox.shrink();
}
