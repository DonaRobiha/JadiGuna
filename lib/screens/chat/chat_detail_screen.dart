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

  const ChatDetailScreen({super.key, required this.conversation});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

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
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _handleSend([String? customText]) async {
    final text = customText ?? _textController.text.trim();
    if (text.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    final currentUserId = authProvider.user?.id ?? 'user-current-1';
    final currentUserName = authProvider.user?.name ?? 'Saya';

    if (customText == null) _textController.clear();

    await chatProvider.sendMessage(
      senderId: currentUserId,
      senderName: currentUserName,
      message: text,
    );

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.user?.id ?? 'user-current-1';
    final rawMessages = chatProvider.currentMessages;

    final sellerName = widget.conversation.sellerName.isNotEmpty ? widget.conversation.sellerName : 'Budi Santoso';
    const sellerAvatar = 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200';

    final effectiveMessages = rawMessages.isNotEmpty
        ? rawMessages
        : [
            MessageModel(
              id: 'm-1',
              conversationId: widget.conversation.id,
              senderId: widget.conversation.sellerId,
              senderName: sellerName,
              message: 'Halo Dimas! Meja masih ada ya. Kapan kira-kira ada waktu buat cek barang ke kos atau mau COD di minimarket dekat kampus?',
              createdAt: DateTime.now().subtract(const Duration(minutes: 60)),
              isRead: true,
            ),
            MessageModel(
              id: 'm-2',
              conversationId: widget.conversation.id,
              senderId: currentUserId,
              senderName: 'Saya',
              message: 'Sore Mas Budi. Bisa COD nanti malam jam 19.30 di Indomaret Point Pandega Marta? Saya bawa motor bisa bawa tali buat iket di jok belakang.',
              createdAt: DateTime.now().subtract(const Duration(minutes: 50)),
              isRead: true,
            ),
            MessageModel(
              id: 'm-3',
              conversationId: widget.conversation.id,
              senderId: widget.conversation.sellerId,
              senderName: sellerName,
              message: 'Bisa banget mas, nanti saya bantu angkat dan ikatkan ke motornya. Saya standby jam 19.30 ya.',
              createdAt: DateTime.now().subtract(const Duration(minutes: 40)),
              isRead: true,
            ),
            MessageModel(
              id: 'm-4',
              conversationId: widget.conversation.id,
              senderId: currentUserId,
              senderName: 'Saya',
              message: 'Siap mas, sudah saya tandai di kartu janji temu ya. Terima kasih banyak!',
              createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
              isRead: true,
            ),
          ];

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F5),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
            child: Row(
              children: [
                // Back Button
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),

                // Brand Circle Logo
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 17,
                      height: 17,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFC29B72), width: 1.8),
                      ),
                      child: Center(
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFFC29B72),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Title "Ruang Obrolan"
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

                // Share Button
                IconButton(
                  icon: const Icon(Icons.share_outlined, color: AppColors.textPrimary, size: 22),
                  onPressed: () {},
                ),

                // User Profile Picture
                const CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: NetworkImage(
                    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200',
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
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // 1. Seller Info Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        // Avatar with online status
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.primaryLight,
                              backgroundImage: NetworkImage(sellerAvatar),
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
                                  border: Border.all(color: Colors.white, width: 2),
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
                                  Text(
                                    sellerName,
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.primary),
                                ],
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                '★ 4.9 • Aktif 5 mnt lalu',
                                style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1EFEA),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary, size: 20),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 2. Product Card in Chat
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ListingDetailScreen(listingId: widget.conversation.listingId),
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
                            borderRadius: BorderRadius.circular(24),
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: Image.network(
                                widget.conversation.listingImage.isNotEmpty
                                    ? widget.conversation.listingImage
                                    : 'https://images.unsplash.com/photo-1518455027359-f3f8164ba6bd?w=400',
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, _) => Container(color: AppColors.primaryLight),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.conversation.listingTitle.isNotEmpty
                                      ? widget.conversation.listingTitle
                                      : 'Meja Belajar Kayu Jati Minimalis',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  CurrencyFormatter.format(widget.conversation.listingPrice ?? 150000),
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F2EA),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Text(
                                        '• Menunggu Kesepakatan COD',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF2E6B4A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 3. COD Appointment Card ("Rencana Janji Temu Disepakati")
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9DF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                    child: Icon(Icons.token_rounded, color: Colors.white, size: 15),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Rencana Janji Temu Disepakati',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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

                        // Store item
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.store_mall_directory_outlined, color: AppColors.terracotta, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'Indomaret Point Pandega Marta',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: const [
                                  Icon(Icons.shield_outlined, size: 12, color: Color(0xFF2E6B4A)),
                                  SizedBox(width: 3),
                                  Text(
                                    'Titik Aman Komunitas  •  1.4 km',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2E6B4A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: const [
                                  Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textPrimary),
                                  SizedBox(width: 6),
                                  Text(
                                    'Hari ini, 19:30 WIB ',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '(Dalam 5 jam)',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.terracotta,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Minimap Preview Card
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
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.near_me_outlined, size: 12, color: AppColors.terracotta),
                                      SizedBox(width: 4),
                                      Text(
                                        'Titik kumpul area parkir depan ATM',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
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

                        // Action Buttons Row (Petunjuk Arah & Ubah Jadwal)
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF27382B),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                                icon: const Icon(Icons.explore_rounded, size: 14),
                                label: const Text('Petunjuk Arah', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Membuka rute panduan lokasi COD...'), duration: Duration(seconds: 1)),
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
                                  side: const BorderSide(color: Color(0xFFDCD6CA), width: 1),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                                icon: const Icon(Icons.calendar_month_outlined, size: 14),
                                label: const Text('Ubah Jadwal', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Fitur perubahan jadwal janji temu'), duration: Duration(seconds: 1)),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 4. Safety Tip Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDECE8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.shield_outlined, size: 14, color: AppColors.terracotta),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Tips Aman: Hindari transfer di luar platform & periksa fisik barang saat COD.',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: AppColors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 5. Date Divider: "Hari Ini"
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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

                  // 6. Messages List
                  ...effectiveMessages.map((msg) {
                    final isMe = msg.senderId == currentUserId;

                    if (isMe) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.76),
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
                                  msg.message,
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
                                      '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        color: Colors.white.withValues(alpha: 0.7),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.done_all_rounded, size: 12, color: Colors.white),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    // Seller message on left with avatar
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundImage: NetworkImage(sellerAvatar),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.74),
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
                                    Text(
                                      msg.message,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: AppColors.textPrimary,
                                        height: 1.35,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${msg.createdAt.hour.toString().padLeft(2, '0')}:${msg.createdAt.minute.toString().padLeft(2, '0')}',
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
                  }),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),

          // Quick Replies Row
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _quickReplies.length,
              itemBuilder: (context, idx) {
                final reply = _quickReplies[idx];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ActionChip(
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 10),
                    label: Text(
                      reply,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFE8E5DF)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onPressed: () => _handleSend(reply),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 6),

          // Message Input Field matching Image 1
          Container(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // "+" Circle Button
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
                      icon: const Icon(Icons.add, size: 20, color: AppColors.textPrimary),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Lampiran gambar atau lokasi COD'), duration: Duration(seconds: 1)),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),

                  // TextField with camera icon inside
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
                              decoration: const InputDecoration(
                                hintText: 'Ketik pesan...',
                                hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 13),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                contentPadding: EdgeInsets.symmetric(vertical: 10),
                              ),
                              onSubmitted: (_) => _handleSend(),
                            ),
                          ),
                          const Icon(Icons.camera_alt_outlined, color: AppColors.textSecondary, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Dark Green Send Button
                  Material(
                    color: const Color(0xFF27382B),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _handleSend(),
                      child: const Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
