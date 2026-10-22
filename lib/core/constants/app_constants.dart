class AppConstants {
  static const String appName = 'jadiGuna';
  static const String appTagline = 'Beri Guna Baru, Temukan Lebih Dekat';
  static const String appVersion = '1.0.0';

  // Item Categories (strictly matching reference UI)
  static const List<String> categories = [
    'Semua',
    'Elektronik',
    'Perlengkapan Rumah',
    'Furnitur',
    'Buku & Hobi',
    'Gratis',
  ];

  // Item Conditions (matching reference UI)
  static const List<String> conditions = [
    'Baru / Belum Dipakai',
    'Sangat Baik',
    'Layak Pakai',
    'Perlu Servis / Modif',
  ];

  // Item Status
  static const String statusAvailable = 'Tersedia';
  static const String statusNegotiating = 'Dalam Kesepakatan';
  static const String statusCompleted = 'Selesai';

  // SharedPreferences Keys
  static const String keyIsFirstInstall = 'is_first_install';
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyUserEmail = 'user_email';
  static const String keyUserName = 'user_name';
  static const String keyUserId = 'user_id';
  static const String keyBiometricEnabled = 'biometric_enabled';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyDarkModeEnabled = 'dark_mode_enabled';
  static const String keyUserLatitude = 'user_latitude';
  static const String keyUserLongitude = 'user_longitude';
  static const String keyUserCity = 'user_city';

  // Default User Location (Yogyakarta area as default college hub)
  static const double defaultLatitude = -7.797068;
  static const double defaultLongitude = 110.370529;
  static const String defaultCity = 'Sleman, D.I. Yogyakarta';
}
