import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────
// KMP Mitra Unified Apple Design System — token aplikasi.
//
// Pasangannya ada di `website/shared/design/tokens.css`. Angkanya sama persis,
// bukan mirip: itulah yang membuat web dan aplikasi terasa satu produk. Kalau
// salah satu berubah, keduanya harus berubah.
// ─────────────────────────────────────────────────────────

class AppColors {
  // Brand — single accent strategy
  static const Color primary = Color(0xFFE31B23);
  static const Color primaryActive = Color(0xFFC9141C);

  /// Merah untuk TEKS di atas permukaan terang.
  ///
  /// [primary] hanya 4,34:1 di atas [surfaceSoft] — di bawah 4,5:1 yang
  /// dituntut teks kecil. Merah gelap sistemnya sendiri mencapai 5,36:1.
  /// [primary] tetap untuk isian tombol, yang dipasangkan teks putih.
  static const Color primaryText = Color(0xFFC9141C);
  static const Color primarySoft = Color(0x1AE31B23);
  static const Color primaryTint = Color(0x0FE31B23);

  // Gradien header beranda. Aksen produk tetap [primary]; dua warna ini hanya
  // titik awal/akhir gradien, bukan aksen kedua.
  static const Color darkRed = Color(0xFF79000D);
  static const Color brightRed = Color(0xFFED102D);

  /// Badge terverifikasi & sorotan pada banner.
  static const Color yellowAccent = Color(0xFFFFC400);

  /// Isian indikator terpilih (12% aksen) — const, jadi tak perlu withOpacity.
  static const Color primaryFaint = Color(0x1FE31B23);

  // Neutrals
  static const Color ink = Color(0xFF1D1D1F);
  static const Color body = Color(0xFF424245);
  static const Color muted = Color(0xFF6E6E73);
  static const Color mutedSoft = Color(0xFF86868B);
  static const Color hairline = Color(0x0F000000);
  static const Color hairlineSoft = Color(0x0A000000);
  static const Color borderStrong = Color(0x1F000000);

  // Surfaces
  static const Color canvas = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF5F5F7);
  static const Color surfaceStrong = Color(0xFFF8F8FA);

  // On‑color
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onDark = Color(0xFFFFFFFF);

  // Semantic
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9F0A);
  static const Color error = Color(0xFFFF3B30);
  static const Color errorText = Color(0xFFC13515);

  // Dark mode surfaces
  static const Color darkBg = Color(0xFF111111);
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkBorder = Color(0xFF333333);
}

class AppRadius {
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 28.0;
  static const double xxxl = 32.0;

  /// Tombol berbentuk pil.
  static const double button = 999.0;
  static const double card = 24.0;
  static const double modal = 28.0;
  static const double pill = 999.0;
}

/// Kekuatan blur kaca. Dipakai dengan `ImageFilter.blur` di dalam
/// `BackdropFilter` — sigma, bukan piksel CSS, jadi nilainya kira-kira
/// setengah dari padanan webnya.
class AppBlur {
  static const double light = 8.0;
  static const double standard = 12.0;
  static const double strong = 16.0;

  /// Opasitas permukaan kaca, sama dengan `--glass*` di web.
  static const double surfaceOpacity = 0.68;
  static const double surfaceOpacityStrong = 0.82;
  static const double surfaceOpacityLight = 0.48;
}

class AppSpacing {
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double base = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double section = 64.0;
}

class AppElevation {
  /// Bayangan lembut dan menyebar — kartu mengambang sedikit di atas latar,
  /// bukan ditindih kotak gelap. Tidak ada nilai di atas 14% kehitaman.
  static const List<BoxShadow> subtle = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.03),
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.06),
      offset: Offset(0, 8),
      blurRadius: 30,
    ),
  ];

  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.055),
      offset: Offset(0, 10),
      blurRadius: 35,
    ),
  ];

  static const List<BoxShadow> floating = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.09),
      offset: Offset(0, 18),
      blurRadius: 50,
    ),
  ];

  static const List<BoxShadow> modal = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.14),
      offset: Offset(0, 25),
      blurRadius: 80,
    ),
  ];

  /// Bayangan beraksen untuk tombol utama.
  static const List<BoxShadow> accent = [
    BoxShadow(
      color: Color.fromRGBO(227, 27, 35, 0.18),
      offset: Offset(0, 8),
      blurRadius: 24,
    ),
  ];

  /// Nama lama, dipetakan ke skala baru supaya pemakaian lama ikut berubah.
  static const List<BoxShadow> cardHover = floating;
  static const List<BoxShadow> hairline = subtle;
}

/// Material "liquid glass" — hanya untuk lapisan yang benar-benar mengambang di
/// atas konten (bottom nav, floating bar, overlay chip). Bukan untuk kartu isi.
/// Selalu punya fallback solid bila blur tidak tersedia.
class AppGlass {
  static const double blur = 16.0;
  static const double blurSubtle = 12.0;

  // Light
  static const Color fill = Color(0xF0FFFFFF); // 94% putih
  static const Color fillSolid = Color(0xFFFFFFFF);

  /// Isian translusen tanpa blur — untuk kontrol kecil di atas media.
  static const Color fillSolidSoft = Color(0xF2FFFFFF);
  static const Color stroke = Color(0x33FFFFFF);
  static const Color hairline = Color(0x1F3C3C43); // separator iOS

  // Dark
  static const Color fillDark = Color(0xCC1C1C1E);
  static const Color fillDarkSolid = Color(0xFF1C1C1E);
  static const Color strokeDark = Color(0x1FFFFFFF);

  /// Elevasi tunggal untuk material mengambang.
  static const List<BoxShadow> lift = [
    BoxShadow(color: Color(0x1F000000), offset: Offset(0, 8), blurRadius: 28),
  ];
}

class AppAnimation {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);
  static const Curve defaultCurve = Curves.easeInOut;
}

class AppTypography {
  static const String fontFamily = 'Plus Jakarta Sans';

  static const TextStyle displayXl = TextStyle(
    fontFamily: fontFamily,
    fontSize: 40,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
    color: AppColors.ink,
  );

  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.25,
    color: AppColors.ink,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.ink,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.ink,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: AppColors.ink,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.ink,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.43,
    color: AppColors.body,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.29,
    color: AppColors.muted,
  );

  static const TextStyle captionSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.33,
    color: AppColors.mutedSoft,
  );

  static const TextStyle buttonMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.25,
    color: AppColors.ink,
  );

  static const TextStyle buttonSm = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.29,
    color: AppColors.ink,
  );

  static const TextStyle navLink = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.25,
    color: AppColors.ink,
  );

  static const TextStyle badge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.18,
    color: AppColors.ink,
  );
}

// ─────────────────────────────────────────────────────────
// AppScrollBehavior
//
// Android + Material 3 memasang StretchingOverscrollIndicator di setiap
// scrollable. Saat halaman ditarik ke paling atas, indikator itu meregangkan
// piksel teratas — yang di Beranda & Marketplace kebetulan gradien merah header
// — sehingga tampak seperti kilatan merah. Menyetel ClampingScrollPhysics per
// layar tidak menolongnya: peregangan datang dari indikator, bukan dari physics.
//
// Dimatikan sekali di sini agar berlaku untuk seluruh aplikasi; RefreshIndicator
// tetap jadi satu-satunya umpan balik tarik-ke-bawah.
// ─────────────────────────────────────────────────────────

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics());
}

// ─────────────────────────────────────────────────────────
// AppTheme — Material ThemeData wired to design tokens
// ─────────────────────────────────────────────────────────

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: AppTypography.fontFamily,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.canvas,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.primary,
      surface: AppColors.canvas,
      onSurface: AppColors.ink,
      error: AppColors.error,
      outline: AppColors.hairline,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.canvas,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
      iconTheme: IconThemeData(color: AppColors.ink),
    ),
    cardTheme: CardThemeData(
      color: AppColors.canvas,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        textStyle: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        side: const BorderSide(color: AppColors.ink),
        textStyle: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.ink,
        textStyle: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.canvas,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: const BorderSide(
          color: AppColors.primaryActive,
          width: 2.0,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: const BorderSide(color: AppColors.errorText, width: 2.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: const BorderSide(color: AppColors.error, width: 2.5),
      ),
      hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.mutedSoft),
      labelStyle: AppTypography.caption.copyWith(color: AppColors.muted),
      floatingLabelStyle: AppTypography.caption.copyWith(
        color: AppColors.primary,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceSoft,
      selectedColor: AppColors.primaryTint,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      labelStyle: AppTypography.buttonSm,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.canvas,
      elevation: 0,
      indicatorColor: AppColors.primaryTint,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppTypography.captionSmall.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          );
        }
        return AppTypography.captionSmall.copyWith(color: AppColors.muted);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.primary, size: 24);
        }
        return const IconThemeData(color: AppColors.muted, size: 24);
      }),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: AppColors.canvas,
      elevation: 0,
      indicatorColor: AppColors.primaryTint,
      selectedIconTheme: const IconThemeData(
        color: AppColors.primary,
        size: 24,
      ),
      unselectedIconTheme: const IconThemeData(
        color: AppColors.muted,
        size: 24,
      ),
      selectedLabelTextStyle: AppTypography.captionSmall.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: AppTypography.captionSmall.copyWith(
        color: AppColors.muted,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.hairlineSoft,
      thickness: 1,
      space: 0,
    ),
    textTheme: const TextTheme(
      displayLarge: AppTypography.displayLarge,
      displayMedium: AppTypography.displayMedium,
      titleLarge: AppTypography.titleLarge,
      titleMedium: AppTypography.titleMedium,
      bodyLarge: AppTypography.bodyLarge,
      bodyMedium: AppTypography.bodyMedium,
      bodySmall: AppTypography.caption,
      labelSmall: AppTypography.captionSmall,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: AppTypography.fontFamily,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.darkBg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.primary,
      surface: AppColors.darkSurface,
      onSurface: AppColors.onDark,
      error: AppColors.error,
      outline: AppColors.darkBorder,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.onDark,
      ),
      iconTheme: IconThemeData(color: AppColors.onDark),
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkSurface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        textStyle: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.canvas,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: const BorderSide(
          color: AppColors.primaryActive,
          width: 2.0,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: const BorderSide(color: AppColors.errorText, width: 2.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: const BorderSide(color: AppColors.error, width: 2.5),
      ),
      hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.mutedSoft),
      labelStyle: AppTypography.caption.copyWith(color: AppColors.muted),
      floatingLabelStyle: AppTypography.caption.copyWith(
        color: AppColors.primary,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.darkBg,
      elevation: 0,
      indicatorColor: AppColors.primary.withOpacity(0.15),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppTypography.captionSmall.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          );
        }
        return AppTypography.captionSmall.copyWith(color: AppColors.mutedSoft);
      }),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.darkBorder,
      thickness: 1,
      space: 0,
    ),
    textTheme: TextTheme(
      displayLarge: AppTypography.displayLarge.copyWith(
        color: AppColors.onDark,
      ),
      displayMedium: AppTypography.displayMedium.copyWith(
        color: AppColors.onDark,
      ),
      titleLarge: AppTypography.titleLarge.copyWith(color: AppColors.onDark),
      titleMedium: AppTypography.titleMedium.copyWith(color: AppColors.onDark),
      bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.onDark),
      bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.mutedSoft),
      bodySmall: AppTypography.caption.copyWith(color: AppColors.mutedSoft),
      labelSmall: AppTypography.captionSmall.copyWith(
        color: AppColors.mutedSoft,
      ),
    ),
  );

  // ─── Backward Compatibility Aliases ───
  // These map legacy AppTheme.xxxColor references to the new design tokens.
  // Screens will be migrated off these over time.
  static const Color primaryColor = AppColors.primary;
  static const Color secondaryColor = AppColors.primary;
  static const Color accentColor = AppColors.warning;
}
