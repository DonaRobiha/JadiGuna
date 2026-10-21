import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../widgets/listing_card.dart';
import '../../widgets/empty_state.dart';
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
        title: const Text('Barang Favorit'),
      ),
      body: favorites.isEmpty
          ? const EmptyState(
              icon: Icons.favorite_border_rounded,
              title: 'Belum Ada Favorit',
              message: 'Simpan barang yang menarik perhatian Anda dengan menekan ikon hati pada barang untuk melihatnya kembali di sini.',
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.79,
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
    );
  }
}
