import 'package:uuid/uuid.dart';
import '../models/listing_model.dart';
import '../core/database/local_database.dart';
import 'blockchain_service.dart';
import 'notification_service.dart';

class ListingService {
  final LocalDatabase _localDb = LocalDatabase.instance;
  final BlockchainService _blockchainService = BlockchainService();
  final NotificationService _notificationService = NotificationService.instance;

  Future<List<ListingModel>> getListings({
    String? categorySlug,
    String? searchQuery,
    bool onlyFree = false,
    String? condition,
    int? maxPrice,
    String? status,
    String? userId,
    String? currentUserId,
  }) async {
    return await _localDb.getListings(
      categorySlug: categorySlug,
      searchQuery: searchQuery,
      onlyFree: onlyFree,
      condition: condition,
      maxPrice: maxPrice,
      status: status,
      userId: userId,
      currentUserId: currentUserId,
    );
  }

  Future<ListingModel?> getListingById(String id, {String? currentUserId}) async {
    return await _localDb.getListingById(id, currentUserId: currentUserId);
  }

  Future<List<ListingModel>> getMyListings(String userId) async {
    return await _localDb.getListings(userId: userId);
  }

  /// Create new listing and record into blockchain ledger
  Future<ListingModel> createListing({
    required String userId,
    required String categoryId,
    required String categoryName,
    required String title,
    required String description,
    int? price,
    required String condition,
    required String locationName,
    double? latitude,
    double? longitude,
    required List<String> images,
    required String sellerName,
    String? sellerAvatar,
    String? sellerPhone,
  }) async {
    final id = 'item-${const Uuid().v4().substring(0, 8)}';
    final listing = ListingModel(
      id: id,
      userId: userId,
      categoryId: categoryId,
      categoryName: categoryName,
      title: title,
      description: description,
      price: price,
      condition: condition,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
      status: 'Tersedia',
      images: images.isNotEmpty ? images : ['https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=600'],
      sellerName: sellerName,
      sellerAvatar: sellerAvatar,
      sellerPhone: sellerPhone,
      createdAt: DateTime.now(),
    );

    await _localDb.insertListing(listing);

    // Record block on immutable ledger
    await _blockchainService.addBlock(
      listingId: listing.id,
      itemTitle: listing.title,
      previousStatus: 'Draft Baru',
      newStatus: 'Tersedia',
      actorName: sellerName,
      notes: 'Iklan berhasil dipublikasikan di jadiGuna',
    );

    await _notificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Iklan Berhasil Diterbitkan! 🎉',
      body: 'Barang "${listing.title}" kini dapat dilihat oleh pengguna di sekitar Anda.',
    );

    return listing;
  }

  /// Update existing listing
  Future<ListingModel> updateListing(ListingModel listing) async {
    final updated = listing.copyWith(updatedAt: DateTime.now());
    await _localDb.updateListing(updated);

    await _blockchainService.addBlock(
      listingId: listing.id,
      itemTitle: listing.title,
      previousStatus: listing.status,
      newStatus: listing.status,
      actorName: listing.sellerName,
      notes: 'Detail informasi iklan diperbarui oleh pemilik',
    );

    return updated;
  }

  /// Update listing status (Tersedia -> Dalam Kesepakatan -> Selesai)
  Future<void> updateStatus({
    required String listingId,
    required String currentStatus,
    required String newStatus,
    required String itemTitle,
    required String actorName,
  }) async {
    await _localDb.updateListingStatus(listingId, newStatus);

    // Add block to blockchain
    await _blockchainService.addBlock(
      listingId: listingId,
      itemTitle: itemTitle,
      previousStatus: currentStatus,
      newStatus: newStatus,
      actorName: actorName,
      notes: 'Status iklan diubah menjadi $newStatus',
    );

    await _notificationService.showListingStatusNotification(
      itemTitle: itemTitle,
      newStatus: newStatus,
    );
  }

  /// Delete listing
  Future<void> deleteListing(String id) async {
    await _localDb.deleteListing(id);
  }

  /// Report listing
  Future<void> reportListing({
    required String listingId,
    required String reporterId,
    required String reason,
    required String details,
  }) async {
    // Save report in local db or Supabase
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
