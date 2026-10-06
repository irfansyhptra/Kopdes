import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/storage/storage_bootstrap.dart';
import 'core/routing/url_strategy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureUrlStrategy();

  try {
    await initializeLocalStorage();
  } catch (e) {
    if (kDebugMode) debugPrint('Failed to initialize Isar database: $e');
  }

  runApp(const ProviderScope(child: KopdesApp()));
}
