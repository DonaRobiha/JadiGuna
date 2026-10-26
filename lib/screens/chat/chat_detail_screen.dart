import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/listing_service.dart';
import '../../services/location_service.dart';
import '../listing/listing_detail_screen.dart';
import '../maps/gps_full_map_screen.dart';

/// Titik pertemuan aman untuk COD.
/// Koordinat masih perkiraan; sesuaikan dengan data lokasi yang sebenarnya.
class _SafePoint {
  final String name;
  final String note;
  final double latitude;
  final double longitude;

  const _SafePoint(this.name, this.note, this.latitude, this.longitude);
}

const List<_SafePoint> _safePoints = [
  _SafePoint(
    'Indomaret Point Pandega Marta',
    'Titik kumpul area parkir depan ATM',
    -7.7737,
    110.3790,
  ),
  _SafePoint(
    'Gerbang Utama UGM',
    'Titik kumpul di dekat pos satpam',
    -7.7714,
    110.3776,
  ),
  _SafePoint(
    'Tugu Yogyakarta',
    'Titik kumpul area pedestrian',
    -7.7829,
    110.3671,
  ),
];

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
  final ImagePicker _picker = ImagePicker();
  final LocationService _locationService = LocationService();

  double? _distanceMeters;
  int _lastMessageCount = 0;

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

    // Pastikan format tanggal Indonesia siap dipakai.
    DateFormatter.ensureInitialized().then((_) {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToBottom();
      final conv = Provider.of<ChatProvider>(
        context,
        listen: false,
      ).activeConversation;
      final point = _pickupPoint(conv ?? widget.conversation);
      _loadDistance(point.latitude, point.longitude);
    });
  }

  // ---------------------------------------------------------------------
  // Janji temu COD
  // ---------------------------------------------------------------------

  /// Titik COD aktif; memakai titik default bila belum pernah diubah.
  ({String name, String note, double latitude, double longitude})
      _pickupPoint(ConversationModel conv) {
    if (conv.pickupName != null &&
        conv.pickupLatitude != null &&
        conv.pickupLongitude != null) {
      final match = _safePoints.where((s) => s.name == conv.pickupName);
      return (
        name: conv.pickupName!,
        note: match.isNotEmpty ? match.first.note : 'Titik pertemuan COD',
        latitude: conv.pickupLatitude!,
        longitude: conv.pickupLongitude!,
      );
    }
    final d = _safePoints.first;
    return (
      name: d.name,
      note: d.note,
      latitude: d.latitude,
      longitude: d.longitude,
    );
  }

  DateTime _pickupTime(ConversationModel conv) {
    if (conv.pickupTime != null) return conv.pickupTime!;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 19, 30);
  }

  String _formatPickupTime(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(t.year, t.month, t.day);
    final diff = day.difference(today).inDays;

    final prefix = diff == 0
        ? 'Hari ini'
        : diff == 1
            ? 'Besok'
            : DateFormatter.formatDate(t);
    return '$prefix, ${DateFormatter.formatTime(t)} WIB';
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  Future<void> _loadDistance(double lat, double lng) async {
    try {
      final d = await _locationService.calculateDistanceFromUser(lat, lng);
      if (mounted) setState(() => _distanceMeters = d);
    } catch (_) {
      // Jarak hanya pelengkap; abaikan bila gagal.
    }
  }

  void _openDirections(ConversationModel conv) {
    final point = _pickupPoint(conv);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GpsFullMapScreen(
          mode: GpsMapMode.pickupLocation,
          initialLatitude: point.latitude,
          initialLongitude: point.longitude,
          locationTitle: point.name,
          locationSubtitle: point.note,
        ),
      ),
    );
  }

  Future<void> _openReschedule(ConversationModel conv) async {
    final current = _pickupPoint(conv);
    final currentTime = _pickupTime(conv);

    final result = await showModalBottomSheet<_PickupChoice>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _RescheduleSheet(
        initialPointName: current.name,
        initialTime: currentTime.isBefore(DateTime.now())
            ? DateTime.now().add(const Duration(hours: 1))
            : currentTime,
        formatTime: _formatPickupTime,
      ),
    );

    if (result == null || !mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    try {
      await chatProvider.updatePickup(
        senderId: authProvider.user?.id ?? 'user-current-1',
        senderName: authProvider.user?.name ?? 'Saya',
        name: result.point.name,
        latitude: result.point.latitude,
        longitude: result.point.longitude,
        time: result.time,
        announcement:
            'Saya ingin mengubah jadwal COD ke ${_formatPickupTime(result.time)} '
            'di ${result.point.name}.',
      );

      if (!mounted) return;
      _loadDistance(result.point.latitude, result.point.longitude);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jadwal COD berhasil diubah.')),
      );
    } catch (e) {
      debugPrint('Gagal mengubah jadwal: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengubah jadwal. Silakan coba lagi.'),
        ),
      );
    }
  }

  // ---------------------------------------------------------------------
  // Bagikan dan laporkan
  // ---------------------------------------------------------------------

  /// Menyalin ringkasan percakapan ke clipboard (tanpa paket tambahan).
  Future<void> _copyConversationSummary(ConversationModel conv) async {
    final currentUserId =
        Provider.of<AuthProvider>(context, listen: false).user?.id ??
            'user-current-1';
    final messages =
        Provider.of<ChatProvider>(context, listen: false).currentMessages;
    final point = _pickupPoint(conv);

    final buffer = StringBuffer()
      ..writeln('Percakapan jadiGuna: ${conv.listingTitle}')
      ..writeln('COD: ${point.name}, ${_formatPickupTime(_pickupTime(conv))}')
      ..writeln();

    for (final m in messages) {
      final who = m.senderId == currentUserId ? 'Saya' : m.senderName;
      final text = m.message.isEmpty && m.hasImage ? '[Foto]' : m.message;
      buffer.writeln('[${DateFormatter.formatTime(m.createdAt)}] $who: $text');
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ringkasan percakapan disalin.')),
    );
  }

  void _showReportDialog() {
    var reason = 'Konten Menyesatkan/Penipuan';
    final detailsController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final reporterId =
        Provider.of<AuthProvider>(context, listen: false).user?.id ??
            'user-current-1';
    final listingId = widget.conversation.listingId;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Laporkan Iklan/Penjual',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: reason,
                isExpanded: true,
                items: const [
                  'Konten Menyesatkan/Penipuan',
                  'Meminta transfer di luar platform',
                  'Perilaku tidak pantas',
                  'Spam',
                  'Lainnya',
                ]
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e, style: const TextStyle(fontSize: 13)),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => reason = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailsController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Keterangan tambahan (opsional)...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await ListingService().reportListing(
                    listingId: listingId,
                    reporterId: reporterId,
                    reason: reason,
                    details: detailsController.text.trim(),
                  );
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Laporan diterima. Tim admin akan meninjaunya.'),
                    ),
                  );
                } catch (_) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Gagal mengirim laporan. Coba lagi.'),
                    ),
                  );
                }
              },
              child: const Text('Kirim Laporan'),
            ),
          ],
        ),
      ),
    ).then((_) => detailsController.dispose());
  }

  // ---------------------------------------------------------------------
  // Lampiran gambar
  // ---------------------------------------------------------------------

  void _showAttachmentSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Pilih dari galeri'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickAndSendImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Ambil foto'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickAndSendImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1280,
        maxHeight: 1280,
      );
      if (picked == null) return;

      var path = picked.path;

      // Di Android, salin ke penyimpanan aplikasi supaya tidak hilang
      // saat cache dibersihkan. Di web, path berupa blob URL dan dipakai apa adanya.
      if (!kIsWeb) {
        final dir = await getApplicationDocumentsDirectory();
        final chatDir = Directory(p.join(dir.path, 'chat_images'));
        if (!await chatDir.exists()) {
          await chatDir.create(recursive: true);
        }
        final ext = p.extension(picked.path).isNotEmpty
            ? p.extension(picked.path)
            : '.jpg';
        final dest = p.join(
          chatDir.path,
          '${DateTime.now().millisecondsSinceEpoch}$ext',
        );
        await File(picked.path).copy(dest);
        path = dest;
      }

      if (!mounted) return;
      await _handleSend(imagePath: path);
    } catch (e) {
      debugPrint('Gagal memilih gambar: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tidak bisa mengakses kamera/galeri. Periksa izin aplikasi.',
          ),
        ),
      );
    }
  }

  Widget _buildChatImage(String path, {double width = 200}) {
    final isRemote = kIsWeb ||
        path.startsWith('http://') ||
        path.startsWith('https://') ||
        path.startsWith('blob:');

    final errorBox = Container(
      width: width,
      height: 120,
      color: AppColors.primaryLight,
      child: const Icon(
        Icons.broken_image_outlined,
        color: AppColors.textSecondary,
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: isRemote
          ? Image.network(
              path,
              width: width,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => errorBox,
            )
          : Image.file(
              File(path),
              width: width,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => errorBox,
            ),
    );
  }

  void _openImageViewer(String path) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(child: _buildChatImage(path, width: 600)),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
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

  Future<void> _handleSend({String? customText, String? imagePath}) async {
    final text = (customText ?? _textController.text).trim();
    final hasImage = imagePath != null && imagePath.isNotEmpty;

    if (text.isEmpty && !hasImage) return;

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

    if (customText == null && !hasImage) {
      _textController.clear();
    }

    try {
      await chatProvider.sendMessage(
        senderId: currentUserId,
        senderName: currentUserName,
        message: text,
        imagePath: imagePath,
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
    final conv = chatProvider.activeConversation ?? widget.conversation;

    // Gulir otomatis saat ada pesan baru (termasuk balasan penjual).
    if (rawMessages.length != _lastMessageCount) {
      _lastMessageCount = rawMessages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToBottom();
      });
    }

    final sellerName = widget.conversation.sellerName.isNotEmpty
        ? widget.conversation.sellerName
        : 'Penjual';

    final effectiveMessages = rawMessages;

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
                  tooltip: 'Salin ringkasan percakapan',
                  onPressed: () => _copyConversationSummary(conv),
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
                  _buildAppointmentCard(context, conv),

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

                  // Keadaan kosong: belum ada pesan.
                  if (effectiveMessages.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'Belum ada pesan. Sapa penjual untuk memulai percakapan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),

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
                    onPressed: () => _handleSend(customText: reply),
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
                  'Pemilik barang',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Opsi percakapan',
            icon: const Icon(
              Icons.more_vert_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            onSelected: (value) {
              if (value == 'listing') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ListingDetailScreen(
                      listingId: widget.conversation.listingId,
                    ),
                  ),
                );
              } else if (value == 'report') {
                _showReportDialog();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'listing', child: Text('Lihat iklan')),
              PopupMenuItem(value: 'report', child: Text('Laporkan iklan/penjual')),
            ],
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

  Widget _buildAppointmentCard(
    BuildContext context,
    ConversationModel conv,
  ) {
    final point = _pickupPoint(conv);
    final time = _pickupTime(conv);
    final subtitle = _distanceMeters != null
        ? 'Titik Aman Komunitas • ${_formatDistance(_distanceMeters!)}'
        : 'Titik Aman Komunitas';

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
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.store_mall_directory_outlined,
                      color: AppColors.terracotta,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        point.name,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 12,
                      color: Color(0xFF2E6B4A),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E6B4A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 13,
                      color: AppColors.textPrimary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _formatPickupTime(time),
                        style: const TextStyle(
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

          // Pratinjau peta titik pertemuan; ketuk untuk membuka peta penuh.
          GestureDetector(
            onTap: () => _openDirections(conv),
            child: Container(
              height: 110,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: const Color(0xFFE5ECE7),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  IgnorePointer(
                    child: FlutterMap(
                      key: ValueKey('${point.latitude}_${point.longitude}'),
                      options: MapOptions(
                        initialCenter: LatLng(point.latitude, point.longitude),
                        initialZoom: 15.5,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                          userAgentPackageName: 'com.jadiguna.jadiguna',
                          fallbackUrl:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          maxZoom: 20,
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(point.latitude, point.longitude),
                              width: 36,
                              height: 36,
                              child: const Icon(
                                Icons.location_on,
                                color: AppColors.terracotta,
                                size: 32,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 8,
                    child: Center(
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.near_me_outlined,
                              size: 12,
                              color: AppColors.terracotta,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                point.note,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
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
                  ),
                ],
              ),
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
                  icon: const Icon(Icons.explore_rounded, size: 14),
                  label: const Text(
                    'Petunjuk Arah',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () => _openDirections(conv),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: Color(0xFFDCD6CA)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: const Icon(Icons.calendar_month_outlined, size: 14),
                  label: const Text(
                    'Ubah Jadwal',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () => _openReschedule(conv),
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
                if (message.hasImage)
                  GestureDetector(
                    onTap: () => _openImageViewer(message.imagePath!),
                    child: _buildChatImage(message.imagePath!),
                  ),
                if (message.hasImage && message.message.isNotEmpty)
                  const SizedBox(height: 6),
                if (message.message.isNotEmpty)
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
                    if (message.hasImage)
                      GestureDetector(
                        onTap: () => _openImageViewer(message.imagePath!),
                        child: _buildChatImage(message.imagePath!),
                      ),
                    if (message.hasImage && message.message.isNotEmpty)
                      const SizedBox(height: 6),
                    if (message.message.isNotEmpty)
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
                tooltip: 'Kirim gambar',
                icon: const Icon(
                  Icons.add,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
                onPressed: _showAttachmentSheet,
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
                    IconButton(
                      tooltip: 'Ambil foto',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      icon: const Icon(
                        Icons.camera_alt_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () => _pickAndSendImage(ImageSource.camera),
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


// -----------------------------------------------------------------------
// Bottom sheet ubah jadwal COD
// -----------------------------------------------------------------------

class _PickupChoice {
  final _SafePoint point;
  final DateTime time;

  const _PickupChoice(this.point, this.time);
}

class _RescheduleSheet extends StatefulWidget {
  final String initialPointName;
  final DateTime initialTime;
  final String Function(DateTime) formatTime;

  const _RescheduleSheet({
    required this.initialPointName,
    required this.initialTime,
    required this.formatTime,
  });

  @override
  State<_RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends State<_RescheduleSheet> {
  late DateTime _date;
  late TimeOfDay _time;
  late int _pointIndex;
  String? _error;

  @override
  void initState() {
    super.initState();
    _date = DateTime(
      widget.initialTime.year,
      widget.initialTime.month,
      widget.initialTime.day,
    );
    _time = TimeOfDay.fromDateTime(widget.initialTime);
    final idx = _safePoints.indexWhere((s) => s.name == widget.initialPointName);
    _pointIndex = idx >= 0 ? idx : 0;
  }

  DateTime get _selected =>
      DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(DateTime(now.year, now.month, now.day))
          ? now
          : _date,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _error = null;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) {
      setState(() {
        _time = picked;
        _error = null;
      });
    }
  }

  void _submit() {
    if (!_selected.isAfter(DateTime.now())) {
      setState(() => _error = 'Pilih waktu yang belum lewat.');
      return;
    }
    Navigator.pop(context, _PickupChoice(_safePoints[_pointIndex], _selected));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ubah Jadwal COD',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today_outlined, size: 16),
                      label: Text(DateFormatter.formatDate(_date)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.access_time_rounded, size: 16),
                      label: Text(_time.format(context)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Titik pertemuan',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              for (var i = 0; i < _safePoints.length; i++)
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _pointIndex = i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          _pointIndex == i
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          size: 20,
                          color: _pointIndex == i
                              ? AppColors.primary
                              : AppColors.textTertiary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _safePoints[i].name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                _safePoints[i].note,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_error != null) ...[
                const SizedBox(height: 6),
                Text(
                  _error!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.terracotta,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: _submit,
                  child: const Text('Simpan Jadwal'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}