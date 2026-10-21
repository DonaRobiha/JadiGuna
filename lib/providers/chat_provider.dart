import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../models/listing_model.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();

  List<ConversationModel> _conversations = [];
  List<MessageModel> _currentMessages = [];
  ConversationModel? _activeConversation;
  bool _isLoading = false;

  List<ConversationModel> get conversations => _conversations;
  List<MessageModel> get currentMessages => _currentMessages;
  ConversationModel? get activeConversation => _activeConversation;
  bool get isLoading => _isLoading;

  Future<void> loadConversations({String? currentUserId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _conversations = await _chatService.getConversations(userId: currentUserId);
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<ConversationModel> openConversationForListing({
    required ListingModel listing,
    required String buyerId,
    required String buyerName,
  }) async {
    final conv = await _chatService.startConversation(
      listing: listing,
      buyerId: buyerId,
      buyerName: buyerName,
    );
    _activeConversation = conv;
    await loadMessages(conv.id);
    await loadConversations();
    return conv;
  }

  Future<void> selectConversation(ConversationModel conv) async {
    _activeConversation = conv;
    await loadMessages(conv.id);
  }

  Future<void> loadMessages(String conversationId) async {
    _currentMessages = await _chatService.getMessages(conversationId);
    notifyListeners();
  }

  Future<void> sendMessage({
    required String senderId,
    required String senderName,
    required String message,
  }) async {
    if (_activeConversation == null || message.trim().isEmpty) return;

    final msg = await _chatService.sendMessage(
      conversationId: _activeConversation!.id,
      senderId: senderId,
      senderName: senderName,
      message: message.trim(),
      listingTitle: _activeConversation!.listingTitle,
    );

    _currentMessages.add(msg);
    notifyListeners();

    // Reload conversations to update last message snippet
    await loadConversations();

    // Check for simulated reply after a few seconds
    Future.delayed(const Duration(seconds: 4), () async {
      if (_activeConversation != null) {
        await loadMessages(_activeConversation!.id);
        await loadConversations();
      }
    });
  }
}
