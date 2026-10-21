import 'package:uuid/uuid.dart';
import '../models/message_model.dart';
import '../models/listing_model.dart';
import '../core/database/local_database.dart';
import 'notification_service.dart';

class ChatService {
  final LocalDatabase _localDb = LocalDatabase.instance;
  final NotificationService _notificationService = NotificationService.instance;

  Future<List<ConversationModel>> getConversations({String? userId}) async {
    return await _localDb.getConversations(userId: userId);
  }

  Future<ConversationModel?> getConversationById(String convId) async {
    return await _localDb.getConversationById(convId);
  }

  Future<List<MessageModel>> getMessages(String conversationId) async {
    return await _localDb.getMessages(conversationId);
  }

  /// Start or get existing conversation for a listing
  Future<ConversationModel> startConversation({
    required ListingModel listing,
    required String buyerId,
    required String buyerName,
  }) async {
    final existingConvs = await getConversations();
    for (var c in existingConvs) {
      if (c.listingId == listing.id && c.buyerId == buyerId) {
        return c;
      }
    }

    final newConv = ConversationModel(
      id: 'conv-${const Uuid().v4().substring(0, 8)}',
      listingId: listing.id,
      listingTitle: listing.title,
      listingImage: listing.images.isNotEmpty ? listing.images.first : '',
      listingPrice: listing.price,
      buyerId: buyerId,
      buyerName: buyerName,
      sellerId: listing.userId,
      sellerName: listing.sellerName,
      lastMessage: 'Halo kak, apakah barang "${listing.title}" masih ada?',
      lastMessageTime: DateTime.now(),
      unreadCount: 0,
    );

    await _localDb.saveConversation(newConv);

    // Initial greeting message
    final initMessage = MessageModel(
      id: 'msg-${const Uuid().v4().substring(0, 8)}',
      conversationId: newConv.id,
      senderId: buyerId,
      senderName: buyerName,
      message: 'Halo kak, apakah barang "${listing.title}" masih ada?',
      createdAt: DateTime.now(),
      isRead: true,
    );
    await _localDb.insertMessage(initMessage);

    return newConv;
  }

  /// Send message
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String message,
    String? listingTitle,
  }) async {
    final msg = MessageModel(
      id: 'msg-${const Uuid().v4().substring(0, 8)}',
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      message: message,
      createdAt: DateTime.now(),
      isRead: true,
    );

    await _localDb.insertMessage(msg);

    // Simulate seller auto-reply for realistic interactive demo if buyer sends message
    _scheduleSimulatedReply(conversationId, listingTitle ?? 'Barang');

    return msg;
  }

  void _scheduleSimulatedReply(String conversationId, String listingTitle) {
    Future.delayed(const Duration(seconds: 4), () async {
      final replies = [
        'Halo kak! Masih ada nih, kondisinya sesuai foto ya.',
        'Bisa banget kak, mau COD di sekitar kampus mana?',
        'Siap kak, barang sudah saya siapkan. Nanti kabari saja kalau sudah dekat ya!',
      ];
      final replyText = replies[DateTime.now().second % replies.length];

      final replyMsg = MessageModel(
        id: 'msg-${const Uuid().v4().substring(0, 8)}',
        conversationId: conversationId,
        senderId: 'seller-simulated',
        senderName: 'Pemilik Barang',
        message: replyText,
        createdAt: DateTime.now(),
        isRead: false,
      );

      await _localDb.insertMessage(replyMsg);
      await _notificationService.showNewMessageNotification(
        senderName: 'Pemilik Barang',
        message: replyText,
        itemTitle: listingTitle,
      );
    });
  }
}
