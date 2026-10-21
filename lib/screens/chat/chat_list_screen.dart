import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/empty_state.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUserId = Provider.of<AuthProvider>(context, listen: false).user?.id;
      Provider.of<ChatProvider>(context, listen: false).loadConversations(currentUserId: currentUserId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final convs = chatProvider.conversations;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Pesan & Diskusi'),
      ),
      body: chatProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : convs.isEmpty
              ? const EmptyState(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Belum Ada Percakapan',
                  message: 'Mulai hubungi penjual dari halaman detail barang untuk bertanya kondisi atau menyepakati pengambilan barang.',
                )
              : ListView.separated(
                  itemCount: convs.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, indent: 80),
                  itemBuilder: (context, index) {
                    final conv = convs[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      onTap: () async {
                        await chatProvider.selectConversation(conv);
                        if (!context.mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatDetailScreen(conversation: conv),
                          ),
                        );
                      },
                      leading: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 54,
                              height: 54,
                              child: Image.network(
                                conv.listingImage.isNotEmpty
                                    ? conv.listingImage
                                    : 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=600',
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, _) => Container(
                                  color: AppColors.primarySurface,
                                  child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
                                ),
                              ),
                            ),
                          ),
                          if (conv.unreadCount > 0)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: AppColors.secondary,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${conv.unreadCount}',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              conv.sellerName,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            DateFormatter.formatChatTime(conv.lastMessageTime),
                            style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySurface,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  CurrencyFormatter.formatCompact(conv.listingPrice),
                                  style: const TextStyle(fontSize: 10, color: AppColors.primaryDark, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  conv.listingTitle,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            conv.lastMessage,
                            style: TextStyle(
                              fontSize: 12,
                              color: conv.unreadCount > 0 ? AppColors.textPrimary : AppColors.textTertiary,
                              fontWeight: conv.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
