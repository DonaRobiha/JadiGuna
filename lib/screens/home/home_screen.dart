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
import '../sensors/sensors_screen.dart';
import '../maps/gps_full_map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedSortFilter = 'Terdekat';

  void _showCityPicker(BuildContext context, ListingProvider provider) {
    final cities = [
      {'name': 'Sleman, DIY (1.5 km)', 'lat': -7.760124, 'lng': 110.375492},
      {'name': 'Depok, Sleman (Area Kampus)', 'lat': -7.771245, 'lng': 110.388712},
      {'name': 'Kota Yogyakarta (Malioboro)', 'lat': -7.797068, 'lng': 110.370529},
      {'name': 'Bantul, D.I. Yogyakarta', 'lat': -7.889123, 'lng': 110.334123},
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
    final userName = authProvider.user?.name ?? 'Dimas';
    final firstName = userName.split(' ').first;

    final userLat = listingProvider.userLocation['latitude'];
    final userLng = listingProvider.userLocation['longitude'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                // Circular Brand Logo
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFC29B72), width: 2.2),
                      ),
                      child: Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFC29B72),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'jadiGuna',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                const Spacer(),

                // Accelerometer / Shake shortcut
                IconButton(
                  tooltip: 'Sensor Interaktif',
                  icon: const Icon(Icons.sensors_rounded, color: AppColors.textSecondary, size: 22),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SensorsScreen()),
                    );
                  },
                ),

                // Notification Bell
                IconButton(
                  tooltip: 'Notifikasi',
                  icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary, size: 24),
                  onPressed: () {
                    listingProvider.randomizeRecommendations();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notifikasi terbaru telah diperbarui.'),
                        duration: Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),

                // User Profile Picture
                CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: const NetworkImage(
                    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200',
                  ),
                ),
              ],
            ),
          ),
        ),
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
              const SizedBox(height: 6),

              // Greeting & Location Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Halo, Dimas! 👋
                    Text(
                      'Halo, $firstName! 👋',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),

                    // Location Pill on the right
                    InkWell(
                      onTap: () => _showCityPicker(context, listingProvider),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: AppColors.terracotta,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 130),
                              child: Text(
                                listingProvider.userCityName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Search Bar Trigger
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppColors.border, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search_rounded, color: AppColors.textTertiary, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Cari meja belajar, buku, sofa...',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(Icons.mic_none_rounded, color: AppColors.textTertiary, size: 20),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Categories Grid (Exact 6 choices from Image 3: 2 cols x 3 rows)
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
                    childAspectRatio: 3.5,
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

              const SizedBox(height: 18),

              // Promo Banner ("JadiGuna, yang tak berguna jadi Berguna")
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      // Left content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 100% GRATIS Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: AppColors.terracotta,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    '100% GRATIS',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Title
                            const Text(
                              'JadiGuna, yang tak berguna\njadi Berguna',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                height: 1.25,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Subtitle
                            Text(
                              'Bebaskan rumah dari barang tak\nterpakai & bantu sesama',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 11,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Terracotta Button
                            InkWell(
                              onTap: () {
                                listingProvider.setOnlyFree(true);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const SearchScreen()),
                                );
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
                                decoration: BoxDecoration(
                                  color: AppColors.terracotta,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Lihat Barang Gratis',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 13),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Right Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          width: 110,
                          height: 110,
                          child: Image.network(
                            'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=400',
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, _) => Container(color: AppColors.primaryLight),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // Section Header: "Barang Terdekat Sekitar Anda"
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Barang Terdekat Sekitar Anda',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Bisa diambil langsung atau COD santai',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SearchScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Semua',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.terracotta,
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.terracotta),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Filter Chips: Terdekat | Terbaru | Harga Terendah | Terverifikasi
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildSortPill('Terdekat', isSelected: _selectedSortFilter == 'Terdekat', onTap: () {
                      setState(() => _selectedSortFilter = 'Terdekat');
                      listingProvider.setSortBy('terdekat');
                    }),
                    const SizedBox(width: 8),
                    _buildSortPill('Terbaru', isSelected: _selectedSortFilter == 'Terbaru', onTap: () {
                      setState(() => _selectedSortFilter = 'Terbaru');
                      listingProvider.setSortBy('terbaru');
                    }),
                    const SizedBox(width: 8),
                    _buildSortPill('Harga Terendah', isSelected: _selectedSortFilter == 'Harga Terendah', onTap: () {
                      setState(() => _selectedSortFilter = 'Harga Terendah');
                      listingProvider.setSortBy('termurah');
                    }),
                    const SizedBox(width: 8),
                    _buildSortPill(
                      'Terverifikasi',
                      isSelected: _selectedSortFilter == 'Terverifikasi',
                      icon: Icons.check_circle_outline_rounded,
                      onTap: () {
                        setState(() => _selectedSortFilter = 'Terverifikasi');
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Product Grid
              if (listingProvider.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (listingProvider.listings.isEmpty)
                const EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Belum Ada Barang di Kategori Ini',
                  message: 'Coba pilih kategori lain atau bagikan barang tak terpakai Anda!',
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.69,
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

  Widget _buildSortPill(String title, {required bool isSelected, IconData? icon, required VoidCallback onTap}) {
    return Material(
      color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
