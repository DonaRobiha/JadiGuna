import 'dart:math';
import 'package:flutter/material.dart';
import '../models/listing_model.dart';
import '../models/category_model.dart';
import '../services/listing_service.dart';
import '../services/favorite_service.dart';
import '../services/location_service.dart';

class ListingProvider extends ChangeNotifier {
  final ListingService _listingService = ListingService();
  final FavoriteService _favoriteService = FavoriteService();
  final LocationService _locationService = LocationService();

  List<ListingModel> _listings = [];
  List<ListingModel> _favorites = [];
  List<ListingModel> _myListings = [];
  List<CategoryModel> _categories = [];

  bool _isLoading = false;
  String? _errorMessage;

  // Filters
  String _selectedCategorySlug = 'semua';
  String _searchQuery = '';
  bool _onlyFree = false;
  String? _selectedCondition;
  int? _maxPrice;
  String _sortBy = 'terbaru'; // 'terbaru', 'termurah', 'termahal', 'terdekat'

  // Location
  Map<String, double> _userLocation = {'latitude': -7.797068, 'longitude': 110.370529};
  String _userCityName = 'Sleman, D.I. Yogyakarta';
  String? _currentUserId;

  List<ListingModel> get listings => _getFilteredAndSortedListings();
  List<ListingModel> get rawListings => _listings;
  List<ListingModel> get freeListings => _listings.where((l) => l.isFree).toList();
  List<ListingModel> get favorites => _favorites;
  List<ListingModel> get myListings => _myListings;
  List<CategoryModel> get categories => _categories;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedCategorySlug => _selectedCategorySlug;
  String get searchQuery => _searchQuery;
  bool get onlyFree => _onlyFree;
  String? get selectedCondition => _selectedCondition;
  String get sortBy => _sortBy;
  String get userCityName => _userCityName;
  Map<String, double> get userLocation => _userLocation;

  Future<void> init(String? currentUserId) async {
    _currentUserId = currentUserId;
    _categories = CategoryModel.defaultCategories;
    await refreshLocation();
    await loadListings();
    if (currentUserId != null) {
      await loadFavorites(currentUserId);
      await loadMyListings(currentUserId);
    } else {
      _favorites = [];
      _myListings = [];
      notifyListeners();
    }
  }

  Future<void> refreshLocation() async {
    try {
      final pos = await _locationService.getCurrentLocation();
      if (pos != null) {
        _userLocation = {'latitude': pos.latitude, 'longitude': pos.longitude};
      } else {
        _userLocation = await _locationService.getLastKnownOrCoordinates();
      }
      notifyListeners();
    } catch (_) {}
  }

  void setUserCity(String cityName, double lat, double lng) {
    _userCityName = cityName;
    _userLocation = {'latitude': lat, 'longitude': lng};
    notifyListeners();
  }

  Future<void> loadListings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _listings = await _listingService.getListings(currentUserId: _currentUserId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFavorites(String userId) async {
    try {
      _favorites = await _favoriteService.getFavorites(userId);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadMyListings(String userId) async {
    try {
      _myListings = await _listingService.getMyListings(userId);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> toggleFavorite(String userId, ListingModel listing) async {
    await _favoriteService.toggleFavorite(userId, listing.id);

    // Update locally in lists
    final index = _listings.indexWhere((l) => l.id == listing.id);
    if (index != -1) {
      final isNowFav = !_listings[index].isFavorite;
      _listings[index] = _listings[index].copyWith(isFavorite: isNowFav);
    }

    await loadFavorites(userId);
    notifyListeners();
  }

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
    final newListing = await _listingService.createListing(
      userId: userId,
      categoryId: categoryId,
      categoryName: categoryName,
      title: title,
      description: description,
      price: price,
      condition: condition,
      locationName: locationName,
      latitude: latitude ?? _userLocation['latitude'],
      longitude: longitude ?? _userLocation['longitude'],
      images: images,
      sellerName: sellerName,
      sellerAvatar: sellerAvatar,
      sellerPhone: sellerPhone,
    );

    _listings.insert(0, newListing);
    _myListings.insert(0, newListing);
    notifyListeners();
    return newListing;
  }

  Future<void> updateListing(ListingModel updated) async {
    await _listingService.updateListing(updated);
    final idx = _listings.indexWhere((l) => l.id == updated.id);
    if (idx != -1) _listings[idx] = updated;

    final myIdx = _myListings.indexWhere((l) => l.id == updated.id);
    if (myIdx != -1) _myListings[myIdx] = updated;

    notifyListeners();
  }

  Future<void> updateListingStatus({
    required String listingId,
    required String currentStatus,
    required String newStatus,
    required String itemTitle,
    required String actorName,
  }) async {
    await _listingService.updateStatus(
      listingId: listingId,
      currentStatus: currentStatus,
      newStatus: newStatus,
      itemTitle: itemTitle,
      actorName: actorName,
    );

    final idx = _listings.indexWhere((l) => l.id == listingId);
    if (idx != -1) {
      _listings[idx] = _listings[idx].copyWith(status: newStatus);
    }
    final myIdx = _myListings.indexWhere((l) => l.id == listingId);
    if (myIdx != -1) {
      _myListings[myIdx] = _myListings[myIdx].copyWith(status: newStatus);
    }

    notifyListeners();
  }

  Future<void> deleteListing(String id) async {
    await _listingService.deleteListing(id);
    _listings.removeWhere((l) => l.id == id);
    _myListings.removeWhere((l) => l.id == id);
    _favorites.removeWhere((l) => l.id == id);
    notifyListeners();
  }

  // --- Filtering & Sorting ---
  void setCategory(String slug) {
    _selectedCategorySlug = slug;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setOnlyFree(bool value) {
    _onlyFree = value;
    notifyListeners();
  }

  void setCondition(String? condition) {
    _selectedCondition = condition;
    notifyListeners();
  }

  void setMaxPrice(int? price) {
    _maxPrice = price;
    notifyListeners();
  }

  void setSortBy(String sort) {
    _sortBy = sort;
    notifyListeners();
  }

  void resetFilters() {
    _selectedCategorySlug = 'semua';
    _searchQuery = '';
    _onlyFree = false;
    _selectedCondition = null;
    _maxPrice = null;
    _sortBy = 'terbaru';
    notifyListeners();
  }

  /// Shuffle/randomize listings when phone is shaken (Accelerometer feature)
  void randomizeRecommendations() {
    _listings.shuffle(Random());
    notifyListeners();
  }

  List<ListingModel> _getFilteredAndSortedListings() {
    var result = List<ListingModel>.from(_listings);

    // 1. Category Filter
    if (_selectedCategorySlug != 'semua' && _selectedCategorySlug.isNotEmpty) {
      result = result.where((l) {
        final slug = _selectedCategorySlug.toLowerCase();
        return l.categoryId.toLowerCase().contains(slug) ||
            l.categoryName.toLowerCase().contains(slug);
      }).toList();
    }

    // 2. Search Query Filter
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      result = result.where((l) {
        return l.title.toLowerCase().contains(q) ||
            l.description.toLowerCase().contains(q) ||
            l.locationName.toLowerCase().contains(q);
      }).toList();
    }

    // 3. Free only Filter
    if (_onlyFree) {
      result = result.where((l) => l.isFree).toList();
    }

    // 4. Max Price Filter
    if (_maxPrice != null && _maxPrice! > 0) {
      result = result.where((l) => (l.price ?? 0) <= _maxPrice!).toList();
    }

    // 5. Condition Filter
    if (_selectedCondition != null &&
        _selectedCondition != 'Semua' &&
        _selectedCondition!.isNotEmpty) {
      result = result.where((l) => l.condition.contains(_selectedCondition!)).toList();
    }

    // 6. Sorting
    switch (_sortBy) {
      case 'termurah':
        result.sort((a, b) => (a.price ?? 0).compareTo(b.price ?? 0));
        break;
      case 'termahal':
        result.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
        break;
      case 'terdekat':
        final userLat = _userLocation['latitude']!;
        final userLng = _userLocation['longitude']!;
        result.sort((a, b) {
          final distA = (a.latitude != null && a.longitude != null)
              ? pow(a.latitude! - userLat, 2) + pow(a.longitude! - userLng, 2)
              : 99999.0;
          final distB = (b.latitude != null && b.longitude != null)
              ? pow(b.latitude! - userLat, 2) + pow(b.longitude! - userLng, 2)
              : 99999.0;
          return distA.compareTo(distB);
        });
        break;
      case 'terbaru':
      default:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return result;
  }
}
