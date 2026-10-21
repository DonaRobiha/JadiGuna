import '../models/listing_model.dart';
import '../core/database/local_database.dart';

class FavoriteService {
  final LocalDatabase _localDb = LocalDatabase.instance;

  Future<List<ListingModel>> getFavorites(String userId) async {
    return await _localDb.getFavorites(userId);
  }

  Future<bool> isFavorite(String userId, String listingId) async {
    return await _localDb.isFavorite(userId, listingId);
  }

  Future<void> toggleFavorite(String userId, String listingId) async {
    await _localDb.toggleFavorite(userId, listingId);
  }
}
