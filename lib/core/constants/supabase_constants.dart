class SupabaseConstants {
  // Masukkan kredensial Supabase proyek Anda di sini jika ingin menggunakan Supabase Cloud.
  // Jika dibiarkan kosong, aplikasi otomatis berjalan dalam mode Offline/SQLite First!
  static const String supabaseUrl = 'https://cfmcjkvijfexcvxkcexc.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_a2kKH-SPiQV6XKOh6UxF3g_2WcXIgR1';

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseUrl.contains('xyzcompany');

  // Table names
  static const String tableProfiles = 'profiles';
  static const String tableCategories = 'categories';
  static const String tableListings = 'listings';
  static const String tableListingImages = 'listing_images';
  static const String tableFavorites = 'favorites';
  static const String tableConversations = 'conversations';
  static const String tableMessages = 'messages';
  static const String tableReports = 'reports';
  static const String tableFeedback = 'feedback';
  static const String tableBlockchain = 'listing_status_history';

  // Storage Bucket
  static const String bucketListingImages = 'listing-images';
  static const String bucketAvatars = 'avatars';
}
