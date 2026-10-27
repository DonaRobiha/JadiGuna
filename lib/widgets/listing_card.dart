import 'dart:io';
import 'package:flutter/material.dart';
import '../models/listing_model.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../core/utils/location_helper.dart';

class ListingCard extends StatelessWidget {
  final ListingModel listing;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;
  final double? userLatitude;
  final double? userLongitude;
  final bool isHorizontal;

  const ListingCard({
    super.key,
    required this.listing,
    required this.onTap,
    this.onFavoriteToggle,
    this.userLatitude,
    this.userLongitude,
    this.isHorizontal = false,
  });

  Widget _buildListingImage(String imgPath) {
    if (imgPath.startsWith('http://') || imgPath.startsWith('https://')) {
      return Image.network(
        imgPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    if (imgPath.startsWith('assets/')) {
      return Image.asset(
        imgPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    return Image.file(
      File(imgPath),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.primarySurface,
      child: const Center(
        child: Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 36),
      ),
    );
  }

  String _formatCardPrice(int? price, bool isFree) {
    if (isFree || price == null || price == 0) return 'RP.0';
    if (price >= 1000 && price % 1000 == 0) {
      return 'Rp ${(price / 1000).toInt()}rb';
    }
    return CurrencyFormatter.format(price);
  }

  String _formatShortSeller(String name) {
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0]} ${parts[1][0]}.';
    }
    return name;
  }

  String _formatShortCondition(String cond) {
    if (cond.isEmpty) return 'Sangat Baik';
    if (cond.contains('Layak')) return 'Layak Pakai';
    if (cond.contains('Mulus')) return 'Mulus';
    if (cond.contains('Baru')) return 'Baru';
    if (cond.contains('Sangat Baik')) return 'Sangat Baik';
    if (cond.contains('Baik')) return 'Baik';
    return cond;
  }

  @override
  Widget build(BuildContext context) {
    final hasUserCoords = userLatitude != null &&
        userLongitude != null &&
        listing.latitude != null &&
        listing.longitude != null;

    final distanceMeters = hasUserCoords
        ? LocationHelper.calculateDistanceInMeters(
            userLatitude!,
            userLongitude!,
            listing.latitude!,
            listing.longitude!,
          )
        : null;

    final isFree = listing.isFree;
    final sellerInitial = listing.sellerName.isNotEmpty
        ? listing.sellerName[0].toUpperCase()
        : 'U';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Container with Badges
              Padding(
                padding: const EdgeInsets.all(7.0),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 1.28,
                        child: _buildListingImage(
                          listing.images.isNotEmpty
                              ? listing.images.first
                              : 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=600',
                        ),
                      ),
                    ),

                    // Free Badge (Top Left)
                    if (isFree)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: AppColors.terracotta,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'GRATIS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),

                    // Favorite Button (Top Right)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Material(
                        color: Colors.white.withValues(alpha: 0.85),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onFavoriteToggle,
                          child: Padding(
                            padding: const EdgeInsets.all(5.5),
                            child: Icon(
                              listing.isFavorite ? Icons.favorite : Icons.favorite_border_rounded,
                              color: listing.isFavorite ? AppColors.terracotta : AppColors.textPrimary,
                              size: 15,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Distance Pill (Bottom Left)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 11,
                              color: AppColors.terracotta,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              distanceMeters != null
                                  ? LocationHelper.formatDistance(distanceMeters)
                                  : '0.8 km',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(9, 0, 9, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Condition Tag
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F2EA),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              _formatShortCondition(listing.condition),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF27553A),
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),

                          // Title
                          Text(
                            listing.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),

                          // Location text
                          Text(
                            listing.locationName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      // Price and Seller Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Price
                          Flexible(
                            child: Text(
                              _formatCardPrice(listing.price, isFree),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: isFree ? AppColors.terracotta : AppColors.textPrimary,
                              ),
                            ),
                          ),

                          // Seller Info
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFDECE8),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    sellerInitial,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.terracotta,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 55),
                                child: Text(
                                  _formatShortSeller(listing.sellerName),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
