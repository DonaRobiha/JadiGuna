class FeedbackModel {
  final String id;
  final String userId;
  final String userName;
  final String category; // 'Fitur', 'Tampilan', 'Kendala/Bug', 'Lainnya'
  final int rating; // 1-5
  final String message;
  final DateTime createdAt;

  FeedbackModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.category,
    required this.rating,
    required this.message,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'category': category,
      'rating': rating,
      'message': message,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FeedbackModel.fromMap(Map<String, dynamic> map) {
    return FeedbackModel(
      id: map['id'] as String,
      userId: map['user_id'] as String? ?? '',
      userName: map['user_name'] as String? ?? 'Anonim',
      category: map['category'] as String? ?? 'Fitur',
      rating: map['rating'] as int? ?? 5,
      message: map['message'] as String? ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
