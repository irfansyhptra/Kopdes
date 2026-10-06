import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<String> isarDirectory() async =>
    (await getApplicationDocumentsDirectory()).path;

Future<void> deleteIsarFiles(String directory, String name) async {
  for (final suffix in const ['.isar', '.isar.lock']) {
    final file = File('$directory/$name$suffix');
    if (file.existsSync()) await file.delete();
  }
}
