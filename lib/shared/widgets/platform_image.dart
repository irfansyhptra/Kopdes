import 'package:flutter/material.dart';

import 'platform_image_io.dart'
    if (dart.library.html) 'platform_image_web.dart'
    as implementation;

Widget platformImage(
  String path, {
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
  int? cacheWidth,
  ImageErrorWidgetBuilder? errorBuilder,
}) => implementation.platformImage(
  path,
  fit: fit,
  width: width,
  height: height,
  cacheWidth: cacheWidth,
  errorBuilder: errorBuilder,
);
