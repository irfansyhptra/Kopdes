import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

class PlatformFileData {
  final Uint8List bytes;
  final String filename;

  const PlatformFileData({required this.bytes, required this.filename});
}

String _extension(Uint8List bytes) {
  if (bytes.length >= 3 &&
      bytes[0] == 0xff &&
      bytes[1] == 0xd8 &&
      bytes[2] == 0xff) {
    return 'jpg';
  }
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4e &&
      bytes[3] == 0x47) {
    return 'png';
  }
  if (bytes.length >= 12 &&
      String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
      String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
    return 'webp';
  }
  return 'jpg';
}

Future<int> platformFileLength(String path) => XFile(path).length();

Future<PlatformFileData> readPlatformFile(String path) async {
  final file = XFile(path);
  final bytes = await file.readAsBytes();
  final pickedName = file.name;
  final filename = pickedName.contains('.')
      ? pickedName
      : 'komit-product.${_extension(bytes)}';
  return PlatformFileData(bytes: bytes, filename: filename);
}
