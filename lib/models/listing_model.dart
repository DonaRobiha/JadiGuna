class ListingModel {
  final String id;
  final String userId;
  final String categoryId;
  final String categoryName;
  final String title;
  final String description;
  final int? price; // 0 or null means FREE / Gratis
  final String condition;
  final String locationName;
  final double? latitude;
  final double? longitude;
  final String status; // 'Tersedia', 'Dalam Kesepakatan', 'Selesai'
  final List<String> images;
  final String sellerName;
  final String? sellerAvatar;
  final String? sellerPhone;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isFavorite;

  ListingModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.categoryName,
    required this.title,
    required this.description,
    this.price,
    required this.condition,
    required this.locationName,
    this.latitude,
    this.longitude,
    this.status = 'Tersedia',
    required this.images,
    required this.sellerName,
    this.sellerAvatar,
    this.sellerPhone,
    required this.createdAt,
    this.updatedAt,
    this.isFavorite = false,
  });

  bool get isFree => price == null || price == 0;
  bool get isAvailable => status == 'Tersedia';
  bool get isNegotiating => status == 'Dalam Kesepakatan';
  bool get isCompleted => status == 'Selesai';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'category_name': categoryName,
      'title': title,
      'description': description,
      'price': price,
      'condition': condition,
      'location_name': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'images_csv': images.join(','),
      'seller_name': sellerName,
      'seller_avatar': sellerAvatar,
      'seller_phone': sellerPhone,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory ListingModel.fromMap(Map<String, dynamic> map, {bool isFav = false}) {
    List<String> imageList = [];
    if (map['images_csv'] != null && map['images_csv'].toString().isNotEmpty) {
      imageList = map['images_csv'].toString().split(',');
    } else if (map['images'] is List) {
      imageList = (map['images'] as List).map((e) => e.toString()).toList();
    }

    return ListingModel(
      id: map['id'] as String,
      userId: map['user_id'] as String? ?? '',
      categoryId: map['category_id'] as String? ?? 'cat_1',
      categoryName: map['category_name'] as String? ?? 'Umum',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: map['price'] != null ? int.tryParse(map['price'].toString()) : 0,
      condition: map['condition'] as String? ?? 'Baik (Layak Pakai)',
      locationName: map['location_name'] as String? ?? 'Indonesia',
      latitude: map['latitude'] != null ? double.tryParse(map['latitude'].toString()) : null,
      longitude: map['longitude'] != null ? double.tryParse(map['longitude'].toString()) : null,
      status: map['status'] as String? ?? 'Tersedia',
      images: imageList.isNotEmpty ? imageList : ['https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=600'],
      sellerName: map['seller_name'] as String? ?? 'Pengguna jadiGuna',
      sellerAvatar: map['seller_avatar'] as String?,
      sellerPhone: map['seller_phone'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
      isFavorite: isFav,
    );
  }

  ListingModel copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? categoryName,
    String? title,
    String? description,
    int? price,
    String? condition,
    String? locationName,
    double? latitude,
    double? longitude,
    String? status,
    List<String>? images,
    String? sellerName,
    String? sellerAvatar,
    String? sellerPhone,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
  }) {
    return ListingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      condition: condition ?? this.condition,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      images: images ?? this.images,
      sellerName: sellerName ?? this.sellerName,
      sellerAvatar: sellerAvatar ?? this.sellerAvatar,
      sellerPhone: sellerPhone ?? this.sellerPhone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
