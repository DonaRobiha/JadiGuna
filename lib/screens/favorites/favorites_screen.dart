
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/listing_card.dart';
import '../listing/listing_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final listingProvider = Provider.of<ListingProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    final currentUserId = authProvider.user?.id ?? 'user-current-1';
    final favorites = listingProvider.favorites;
    final userLat = listingProvider.userLocation['latitude'];
    final userLng = listingProvider.userLocation['longitude'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        title: const Row(
          children: [
            Image(
              image: AssetImage('assets/logo_jadiguna.png'),
              width: 34,
              height: 34,
              fit: BoxFit.contain,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Barang Favorit',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Barang yang kamu simpan',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.favorite_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${favorites.length} barang',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: favorites.isEmpty
                  ? _buildEmptyState()
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.58,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: favorites.length,
                      itemBuilder: (context, index) {
                        final item = favorites[index];

                        return ListingCard(
                          listing: item,
                          userLatitude: userLat,
                          userLongitude: userLng,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ListingDetailScreen(
                                  listingId: item.id,
                                ),
                              ),
                            );
                          },
                          onFavoriteToggle: () {
                            listingProvider.toggleFavorite(
                              currentUserId,
                              item,
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: EmptyState(
          icon: Icons.favorite_border_rounded,
          title: 'Belum Ada Favorit',
          message:
              'Temukan barang yang kamu suka, lalu tekan ikon hati untuk menyimpannya di sini.',
        ),
      ),
    );
  }
}