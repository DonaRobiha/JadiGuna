class ConversationModel {
  final String id;
  final String listingId;
  final String listingTitle;
  final String listingImage;
  final int? listingPrice;
  final String buyerId;
  final String buyerName;
  final String sellerId;
  final String sellerName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  ConversationModel({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.listingImage,
    this.listingPrice,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    required this.sellerName,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'listing_id': listingId,
      'listing_title': listingTitle,
      'listing_image': listingImage,
      'listing_price': listingPrice,
      'buyer_id': buyerId,
      'buyer_name': buyerName,
      'seller_id': sellerId,
      'seller_name': sellerName,
      'last_message': lastMessage,
      'last_message_time': lastMessageTime.toIso8601String(),
      'unread_count': unreadCount,
    };
  }

  factory ConversationModel.fromMap(Map<String, dynamic> map) {
    return ConversationModel(
      id: map['id'] as String,
      listingId: map['listing_id'] as String? ?? '',
      listingTitle: map['listing_title'] as String? ?? 'Barang jadiGuna',
      listingImage: map['listing_image'] as String? ?? '',
      listingPrice: map['listing_price'] != null ? int.tryParse(map['listing_price'].toString()) : null,
      buyerId: map['buyer_id'] as String? ?? '',
      buyerName: map['buyer_name'] as String? ?? 'Pembeli',
      sellerId: map['seller_id'] as String? ?? '',
      sellerName: map['seller_name'] as String? ?? 'Penjual',
      lastMessage: map['last_message'] as String? ?? '',
      lastMessageTime: map['last_message_time'] != null
          ? DateTime.tryParse(map['last_message_time'].toString()) ?? DateTime.now()
          : DateTime.now(),
      unreadCount: map['unread_count'] as int? ?? 0,
    );
  }
}

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'sender_name': senderName,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead ? 1 : 0,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] as String,
      conversationId: map['conversation_id'] as String,
      senderId: map['sender_id'] as String,
      senderName: map['sender_name'] as String? ?? 'Pengguna',
      message: map['message'] as String,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead: map['is_read'] == 1 || map['is_read'] == true,
    );
  }
}
