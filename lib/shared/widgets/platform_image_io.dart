import 'dart:io';

import 'package:flutter/material.dart';

Widget platformImage(
  String path, {
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
  int? cacheWidth,
  ImageErrorWidgetBuilder? errorBuilder,
}) => Image.file(
  File(path),
  fit: fit,
  width: width,
  height: height,
  cacheWidth: cacheWidth,
  errorBuilder: errorBuilder,
);
