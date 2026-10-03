import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../core/routing/router.dart';
import '../core/theme/theme.dart';
import '../localization/app_localizations.dart';

class KopdesApp extends ConsumerWidget {
  const KopdesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'KOPDES Smart Cooperative',
      // Hanya satu tema. Mode gelap dihapus dari sistem atas keputusan
      // pemilik produk — aplikasi ini tidak akan pernah memakainya, jadi
      // tidak ada `darkTheme` maupun `themeMode` untuk dijaga tetap sinkron.
      theme: AppTheme.lightTheme,

      routerConfig: router,
      scrollBehavior: const AppScrollBehavior(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
      locale: const Locale('id', 'ID'), // Bahasa Indonesia as default
    );
  }
}
