import 'dart:io';
import 'package:flutter/material.dart';
import '../models/listing_model.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../core/utils/date_formatter.dart';
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

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image Container with Badges
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: SizedBox(
                      height: 118,
                      width: double.infinity,
                      child: _buildListingImage(
                        listing.images.isNotEmpty
                            ? listing.images.first
                            : 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=600',
                      ),
                    ),
                  ),

                  // Free Badge (Only shown for free items; priced items show price once below)
                  if (isFree)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.freeBadge,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.volunteer_activism, color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'GRATIS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Status Badge if not "Tersedia"
                  if (listing.status != 'Tersedia')
                    Positioned(
                      top: 10,
                      right: onFavoriteToggle == null ? 10 : 44,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: listing.isNegotiating
                              ? AppColors.secondary
                              : AppColors.statusCompleted,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          listing.status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Favorite Button
                  if (onFavoriteToggle != null)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onFavoriteToggle,
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Icon(
                              listing.isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: listing.isFavorite ? Colors.redAccent : Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Content Details
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      listing.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Price display
                    Text(
                      CurrencyFormatter.format(listing.price),
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: isFree ? AppColors.freeBadge : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Location & LBS Distance
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            distanceMeters != null
                                ? LocationHelper.formatDistance(distanceMeters)
                                : listing.locationName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Time relative
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            listing.categoryName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: AppColors.textTertiary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormatter.formatRelative(listing.createdAt),
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
