import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/storage/isar_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await IsarService.initialize();
  } catch (e) {
    if (kDebugMode) debugPrint('Failed to initialize Isar database: $e');
  }

  runApp(const ProviderScope(child: KopdesApp()));
}
