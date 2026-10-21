import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/listing_card.dart';
import '../../widgets/empty_state.dart';
import '../search/search_screen.dart';
import '../listing/listing_detail_screen.dart';
import '../listing/add_edit_listing_screen.dart';
import '../sensors/sensors_screen.dart';
import '../maps/gps_full_map_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showCityPicker(BuildContext context, ListingProvider provider) {
    final cities = [
      {'name': 'Sleman, D.I. Yogyakarta', 'lat': -7.760124, 'lng': 110.375492},
      {'name': 'Kota Yogyakarta (Malioboro)', 'lat': -7.797068, 'lng': 110.370529},
      {'name': 'Bantul, D.I. Yogyakarta', 'lat': -7.889123, 'lng': 110.334123},
      {'name': 'Depok, Sleman (Area Kampus)', 'lat': -7.771245, 'lng': 110.388712},
      {'name': 'Jakarta Selatan', 'lat': -6.261493, 'lng': 106.810600},
      {'name': 'Bandung (Coblong/Dago)', 'lat': -6.891480, 'lng': 107.610659},
      {'name': 'Surabaya (Gubeng)', 'lat': -7.275614, 'lng': 112.758385},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Pilih Lokasi Pencarian Barang',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.my_location_rounded, color: AppColors.primary),
                  title: const Text('Gunakan GPS Perangkat Terkini', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Mendeteksi koordinat otomatis lewat satelit GPS'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GpsFullMapScreen(
                          mode: GpsMapMode.userGps,
                        ),
                      ),
                    );
                  },
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: cities.length,
                    itemBuilder: (context, idx) {
                      final c = cities[idx];
                      return ListTile(
                        leading: const Icon(Icons.location_city_rounded, color: AppColors.textSecondary),
                        title: Text(c['name'] as String),
                        onTap: () {
                          provider.setUserCity(
                            c['name'] as String,
                            c['lat'] as double,
                            c['lng'] as double,
                          );
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final listingProvider = Provider.of<ListingProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.user?.id ?? 'user-current-1';

    final userLat = listingProvider.userLocation['latitude'];
    final userLng = listingProvider.userLocation['longitude'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 16,
        title: InkWell(
          onTap: () => _showCityPicker(context, listingProvider),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on, color: AppColors.primary, size: 18),
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 190),
                  child: Text(
                    listingProvider.userCityName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
        actions: [
          // Shake sensor shortcut button
          IconButton(
            tooltip: 'Sensor Goyang (Accelerometer)',
            icon: const Icon(Icons.vibration_rounded, color: AppColors.primary),
            onPressed: () {
              listingProvider.randomizeRecommendations();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Simulasi Goyang HP: Rekomendasi barang diacak!'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Sensor Interaktif',
            icon: const Icon(Icons.sensors_rounded, color: AppColors.textSecondary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SensorsScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await listingProvider.refreshLocation();
          await listingProvider.loadListings();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar Trigger
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Cari meja, monitor, baju, buku gratis...',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
                      ],
                    ),
                  ),
                ),
              ),

              // Eco Hero Banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.22),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.eco_rounded, color: Colors.white, size: 14),
                                SizedBox(width: 5),
                                Text(
                                  'Gaya Hidup Berkelanjutan',
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Beri Guna Baru, Temukan Lebih Dekat',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Temukan barang layak pakai dari tetangga kos atau bagikan barang tak terpakai secara gratis.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                            ),
                            onPressed: () {
                              listingProvider.setOnlyFree(true);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SearchScreen()),
                              );
                            },
                            icon: const Icon(Icons.volunteer_activism, size: 14, color: AppColors.freeBadge),
                            label: const Text('Jelajahi Barang Gratis', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AddEditListingScreen()),
                              );
                            },
                            child: const Text('Pasang Iklan +'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Categories Grid - 2 columns and 4 rows (No horizontal scroll, neatly aligned)
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Kategori Pilihan',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (listingProvider.selectedCategorySlug != 'semua')
                      TextButton(
                        onPressed: () => listingProvider.setCategory('semua'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(40, 24),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Reset', style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: listingProvider.categories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 3.2,
                  ),
                  itemBuilder: (context, index) {
                    final cat = listingProvider.categories[index];
                    final isSelected = listingProvider.selectedCategorySlug == cat.slug;
                    return CategoryChip(
                      category: cat,
                      isSelected: isSelected,
                      isGrid: true,
                      onTap: () {
                        listingProvider.setCategory(cat.slug);
                      },
                    );
                  },
                ),
              ),

              // Section 1: Barang Gratis (Free Items Section)
              if (listingProvider.freeListings.isNotEmpty) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.volunteer_activism_rounded, color: AppColors.freeBadge, size: 20),
                          SizedBox(width: 6),
                          Text(
                            'Barang Gratis di Sekitar',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          listingProvider.setOnlyFree(true);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SearchScreen()),
                          );
                        },
                        child: const Text('Lihat Semua', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 218,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: listingProvider.freeListings.length,
                    itemBuilder: (context, index) {
                      final item = listingProvider.freeListings[index];
                      return Container(
                        width: 175,
                        margin: const EdgeInsets.only(right: 12),
                        child: ListingCard(
                          listing: item,
                          userLatitude: userLat,
                          userLongitude: userLng,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ListingDetailScreen(listingId: item.id),
                              ),
                            );
                          },
                          onFavoriteToggle: () {
                            listingProvider.toggleFavorite(currentUserId, item);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],

              // Section 2: All Items / Latest
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      listingProvider.selectedCategorySlug == 'semua'
                          ? 'Barang Terbaru di Sekitar Anda'
                          : 'Kategori: ${listingProvider.selectedCategorySlug.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (listingProvider.selectedCategorySlug != 'semua')
                      TextButton(
                        onPressed: () => listingProvider.setCategory('semua'),
                        child: const Text('Reset', style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Listings Grid (childAspectRatio 0.79 to eliminate empty bottom space)
              if (listingProvider.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (listingProvider.listings.isEmpty)
                const EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Belum Ada Barang di Kategori Ini',
                  message: 'Coba pilih kategori lain atau jadilah yang pertama memasang iklan barang di sekitar Anda!',
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.79,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: listingProvider.listings.length,
                    itemBuilder: (context, index) {
                      final item = listingProvider.listings[index];
                      return ListingCard(
                        listing: item,
                        userLatitude: userLat,
                        userLongitude: userLng,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ListingDetailScreen(listingId: item.id),
                            ),
                          );
                        },
                        onFavoriteToggle: () {
                          listingProvider.toggleFavorite(currentUserId, item);
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
