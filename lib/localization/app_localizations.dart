import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'id': {
      'appName': 'Koperasi Pintar KOPDES',
      'loginTitle': 'Masuk ke KOPDES',
      'emailLabel': 'Alamat Email',
      'passwordLabel': 'Kata Sandi',
      'loginButton': 'Masuk',
      'navHome': 'Beranda',
      'navProducts': 'Produk',
      'navCart': 'Keranjang',
      'navChat': 'AI Asisten',
      'navProfile': 'Profil',
      'logout': 'Keluar',
      'welcomeMessage': 'Selamat datang di Smart Cooperative KOPDES',
      'modulesTitle': 'Modul Koperasi Pintar',
      'productDetail': 'Detail Produk',
      'addToCart': 'Tambah ke Keranjang',
      'orderTracking': 'Pelacakan Pengiriman',
      'umkmDashboard': 'Dasbor UMKM',
      'adminDashboard': 'Dasbor Admin',
      'courierDashboard': 'Dasbor Kurir',
      'assistantTitle': 'Asisten Pintar KOPDES',
      'assistantSubtitle':
          'Tanyakan apa saja tentang produk desa, keuangan koperasi, atau bantuan usaha.',
    },
    'en': {
      'appName': 'KOPDES Smart Cooperative',
      'loginTitle': 'Log in to KOPDES',
      'emailLabel': 'Email Address',
      'passwordLabel': 'Password',
      'loginButton': 'Login',
      'navHome': 'Home',
      'navProducts': 'Products',
      'navCart': 'Cart',
      'navChat': 'AI Chat',
      'navProfile': 'Profile',
      'logout': 'Logout',
      'welcomeMessage': 'Welcome to KOPDES Smart Cooperative',
      'modulesTitle': 'Smart Cooperative Modules',
      'productDetail': 'Product Details',
      'addToCart': 'Add to Cart',
      'orderTracking': 'Delivery Tracking',
      'umkmDashboard': 'UMKM Dashboard',
      'adminDashboard': 'Admin Dashboard',
      'courierDashboard': 'Courier Dashboard',
      'assistantTitle': 'KOPDES Smart Assistant',
      'assistantSubtitle':
          'Ask anything about village products, cooperative finance, or business aid.',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['id']?[key] ??
        key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['id', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) => false;
}
