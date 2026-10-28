class UserModel {
  final String id;
  final String name;
  final String email;
  final String? profilePhotoPath;
  final String? bio;
  final String? city;
  final String? phoneNumber;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profilePhotoPath,
    this.bio,
    this.city,
    this.phoneNumber,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profile_photo_path': profilePhotoPath,
      'bio': bio,
      'city': city,
      'phone_number': phoneNumber,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Pengguna',
      email: map['email'] as String? ?? '',
      profilePhotoPath: map['profile_photo_path'] as String?,
      bio: map['bio'] as String?,
      city: map['city'] as String?,
      phoneNumber: map['phone_number'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? profilePhotoPath,
    bool clearPhoto = false,
    String? bio,
    String? city,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profilePhotoPath: clearPhoto ? null : (profilePhotoPath ?? this.profilePhotoPath),
      bio: bio ?? this.bio,
      city: city ?? this.city,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
