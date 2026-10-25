
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../listing/listing_detail_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  final ConversationModel conversation;

  const ChatDetailScreen({
    super.key,
    required this.conversation,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const String _fallbackAvatar =
      'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200';

  final List<String> _quickReplies = [
    'Saya sudah sampai di lokasi 👋',
    'Minta foto tampak belakang ya mas',
    'Bisa COD malam ini?',
    'Terima kasih banyak ya mas!',
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollToBottom();
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _handleSend([String? customText]) async {
    final text = (customText ?? _textController.text).trim();

    if (text.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(
      context,
      listen: false,
    );
    final chatProvider = Provider.of<ChatProvider>(
      context,
      listen: false,
    );

    final currentUserId = authProvider.user?.id ?? 'user-current-1';
    final currentUserName = authProvider.user?.name ?? 'Saya';

    if (customText == null) {
      _textController.clear();
    }

    try {
      await chatProvider.sendMessage(
        senderId: currentUserId,
        senderName: currentUserName,
        message: text,
      );

      if (!mounted) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToBottom();
      });
    } catch (e, stackTrace) {
      debugPrint('Gagal mengirim pesan: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pesan gagal dikirim. Silakan coba lagi.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    final currentUserId = authProvider.user?.id ?? 'user-current-1';
    final rawMessages = chatProvider.currentMessages;

    final sellerName = widget.conversation.sellerName.isNotEmpty
        ? widget.conversation.sellerName
        : 'Penjual';

    final effectiveMessages = rawMessages.isNotEmpty
        ? rawMessages
        : <MessageModel>[
            MessageModel(
              id: 'm-1',
              conversationId: widget.conversation.id,
              senderId: widget.conversation.sellerId,
              senderName: sellerName,
              message:
                  'Halo! Barangnya masih tersedia. Kapan kira-kira ada waktu untuk cek barang atau COD?',
              createdAt: DateTime.now().subtract(
                const Duration(minutes: 60),
              ),
              isRead: true,
            ),
            MessageModel(
              id: 'm-2',
              conversationId: widget.conversation.id,
              senderId: currentUserId,
              senderName: 'Saya',
              message:
                  'Sore, Mas. Apakah bisa COD nanti malam?',
              createdAt: DateTime.now().subtract(
                const Duration(minutes: 50),
              ),
              isRead: true,
            ),
            MessageModel(
              id: 'm-3',
              conversationId: widget.conversation.id,
              senderId: widget.conversation.sellerId,
              senderName: sellerName,
              message:
                  'Bisa, silakan kabari saya untuk waktu dan lokasi yang disepakati.',
              createdAt: DateTime.now().subtract(
                const Duration(minutes: 40),
              ),
              isRead: true,
            ),
            MessageModel(
              id: 'm-4',
              conversationId: widget.conversation.id,
              senderId: currentUserId,
              senderName: 'Saya',
              message: 'Siap, terima kasih banyak!',
              createdAt: DateTime.now().subtract(
                const Duration(minutes: 20),
              ),
              isRead: true,
            ),
          ];

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F5),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.textPrimary,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Ruang Obrolan',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.share_outlined,
                    color: AppColors.textPrimary,
                    size: 22,
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fitur berbagi percakapan'),
                      ),
                    );
                  },
                ),
                const CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(
                    Icons.person,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 6),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // Informasi penjual.
                  _buildSellerCard(sellerName),

                  const SizedBox(height: 10),

                  // Informasi barang yang sedang dibicarakan.
                  _buildListingCard(context),

                  const SizedBox(height: 12),

                  // Kartu janji temu COD.
                  _buildAppointmentCard(context),

                  const SizedBox(height: 12),

                  // Pengingat keamanan transaksi.
                  _buildSafetyBanner(),

                  const SizedBox(height: 14),

                  // Pemisah tanggal.
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9DF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Hari Ini',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Daftar pesan.
                  ...effectiveMessages.map((message) {
                    final isMe = message.senderId == currentUserId;

                    return _buildMessageBubble(
                      message: message,
                      isMe: isMe,
                      context: context,
                    );
                  }),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),

          // Balasan cepat.
          SizedBox(
            height: 42,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _quickReplies.length,
              itemBuilder: (context, index) {
                final reply = _quickReplies[index];

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                    ),
                    label: Text(
                      reply,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    backgroundColor: Colors.white,
                    side: const BorderSide(
                      color: Color(0xFFE8E5DF),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onPressed: () => _handleSend(reply),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 6),

          // Kolom penulisan dan pengiriman pesan.
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildSellerCard(String sellerName) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primaryLight,
                child: Icon(
                  Icons.person,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF48BB78),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        sellerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  '★ 4.9 • Aktif 5 mnt lalu',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Opsi percakapan',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opsi percakapan'),
                ),
              );
            },
            icon: const Icon(
              Icons.more_vert_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingCard(BuildContext context) {
    final listing = widget.conversation;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ListingDetailScreen(
              listingId: listing.listingId,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 52,
                height: 52,
                child: Image.network(
                  listing.listingImage.isNotEmpty
                      ? listing.listingImage
                      : 'https://images.unsplash.com/photo-1518455027359-f3f8164ba6bd?w=400',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.primaryLight,
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.listingTitle.isNotEmpty
                        ? listing.listingTitle
                        : 'Barang yang dibicarakan',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    CurrencyFormatter.format(
                      listing.listingPrice ?? 150000,
                    ),
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F2EA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '• Menunggu Kesepakatan COD',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2E6B4A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9DF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: Color(0xFF27382B),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.token_rounded,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Rencana Janji Temu COD',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Terjadwal',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.store_mall_directory_outlined,
                      color: AppColors.terracotta,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Indomaret Point Pandega Marta',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 12,
                      color: Color(0xFF2E6B4A),
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Titik Aman Komunitas • 1.4 km',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E6B4A),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 13,
                      color: AppColors.textPrimary,
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Hari ini, 19:30 WIB',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFFE5ECE7),
              image: const DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1524661135-423995f22d0b?w=600',
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.near_me_outlined,
                          size: 12,
                          color: AppColors.terracotta,
                        ),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Titik kumpul area parkir depan ATM',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27382B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: const Icon(
                    Icons.explore_rounded,
                    size: 14,
                  ),
                  label: const Text(
                    'Petunjuk Arah',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Fitur petunjuk arah belum tersedia.',
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(
                      color: Color(0xFFDCD6CA),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: const Icon(
                    Icons.calendar_month_outlined,
                    size: 14,
                  ),
                  label: const Text(
                    'Ubah Jadwal',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Fitur perubahan jadwal belum tersedia.',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECE8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.shield_outlined,
            size: 14,
            color: AppColors.terracotta,
          ),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              'Tips Aman: Hindari transfer di luar platform dan periksa fisik barang saat COD.',
              style: TextStyle(
                fontSize: 10.5,
                color: AppColors.textSecondary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required MessageModel message,
    required bool isMe,
    required BuildContext context,
  }) {
    final time =
        '${message.createdAt.hour.toString().padLeft(2, '0')}:'
        '${message.createdAt.minute.toString().padLeft(2, '0')}';

    if (isMe) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.76,
            ),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            decoration: const BoxDecoration(
              color: Color(0xFF27382B),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message.message,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Colors.white,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 9.5,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.done_all_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primaryLight,
            child: Icon(
              Icons.person,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.74,
                ),
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        message.message,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textPrimary,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF1EFEA),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                tooltip: 'Lampiran',
                icon: const Icon(
                  Icons.add,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Fitur lampiran gambar atau lokasi belum tersedia.',
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF9F5),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.send,
                        decoration: const InputDecoration(
                          hintText: 'Ketik pesan...',
                          hintStyle: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        onSubmitted: (_) => _handleSend(),
                      ),
                    ),
                    const Icon(
                      Icons.camera_alt_outlined,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: const Color(0xFF27382B),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _handleSend(),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
