import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/location_helper.dart';
import '../../models/listing_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/custom_button.dart';
import '../chat/chat_detail_screen.dart';
import '../blockchain/blockchain_history_screen.dart';
import 'add_edit_listing_screen.dart';
import 'pickup_location_map_widget.dart';

class ListingDetailScreen extends StatefulWidget {
  final String listingId;

  const ListingDetailScreen({super.key, required this.listingId});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  final PageController _imagePageController = PageController();
  int _activeImageIndex = 0;

  Widget _buildDetailImage(String imgUrl) {
    if (imgUrl.startsWith('http://') || imgUrl.startsWith('https://')) {
      return Image.network(
        imgUrl,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, _) => Container(
          color: AppColors.primarySurface,
          child: const Center(
            child: Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.primary),
          ),
        ),
      );
    }
    return Image.file(
      File(imgUrl),
      fit: BoxFit.cover,
      errorBuilder: (ctx, err, _) => Container(
        color: AppColors.primarySurface,
        child: const Center(
          child: Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.primary),
        ),
      ),
    );
  }

  void _showStatusDialog(BuildContext context, ListingModel listing, ListingProvider listingProvider, String currentUserName) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Perbarui Status Iklan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Setiap perubahan status akan dicatat secara otomatis ke dalam riwayat aktivitas yang aman dan konsisten.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_circle_outline, color: AppColors.statusAvailable),
                title: const Text('Tersedia', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Barang masih aktif dan dapat ditawar'),
                onTap: () {
                  Navigator.pop(ctx);
                  _changeStatus(listing, 'Tersedia', listingProvider, currentUserName);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.handshake_outlined, color: AppColors.statusNegotiating),
                title: const Text('Dalam Kesepakatan', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Sedang janjian COD atau negosiasi'),
                onTap: () {
                  Navigator.pop(ctx);
                  _changeStatus(listing, 'Dalam Kesepakatan', listingProvider, currentUserName);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.task_alt, color: AppColors.statusCompleted),
                title: const Text('Selesai / Terjual', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Barang sudah berpindah tangan atau diserahkan'),
                onTap: () {
                  Navigator.pop(ctx);
                  _changeStatus(listing, 'Selesai', listingProvider, currentUserName);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _changeStatus(
    ListingModel listing,
    String newStatus,
    ListingProvider provider,
    String currentUserName,
  ) async {
    await provider.updateListingStatus(
      listingId: listing.id,
      currentStatus: listing.status,
      newStatus: newStatus,
      itemTitle: listing.title,
      actorName: currentUserName,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Status diubah menjadi: $newStatus (Tercatat di Riwayat)'),
        backgroundColor: AppColors.primary,
        action: SnackBarAction(
          label: 'Lihat Riwayat',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BlockchainHistoryScreen()),
            );
          },
        ),
      ),
    );
    setState(() {});
  }

  void _showReportDialog(BuildContext context, ListingModel listing) {
    String selectedReason = 'Konten Menyesatkan/Penipuan';
    final detailsController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Laporkan Iklan Ini', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pilih alasan pelaporan:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedReason,
                    isExpanded: true,
                    items: [
                      'Konten Menyesatkan/Penipuan',
                      'Barang Ilegal/Dilarang',
                      'Spam atau Duplikat',
                      'Informasi Kontak Tidak Pantas',
                      'Lainnya',
                    ].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedReason = val);
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
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Laporan Anda telah diterima. Tim admin akan meninjaunya.'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                  child: const Text('Kirim Laporan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final listingProvider = Provider.of<ListingProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);

    final listing = listingProvider.rawListings.firstWhere(
      (l) => l.id == widget.listingId,
      orElse: () => ListingModel(
        id: widget.listingId,
        userId: '',
        categoryId: 'cat_1',
        categoryName: 'Umum',
        title: 'Barang tidak ditemukan',
        description: 'Detail barang tidak dapat dimuat atau telah dihapus.',
        price: 0,
        condition: '-',
        locationName: '-',
        images: [],
        sellerName: 'Tidak Diketahui',
        createdAt: DateTime.now(),
      ),
    );

    final currentUserId = authProvider.user?.id ?? 'user-current-1';
    final currentUserName = authProvider.user?.name ?? 'Pengguna jadiGuna';
    final isOwner = listing.userId == currentUserId;

    final userLat = listingProvider.userLocation['latitude'];
    final userLng = listingProvider.userLocation['longitude'];
    final distanceMeters = (userLat != null && userLng != null && listing.latitude != null && listing.longitude != null)
        ? LocationHelper.calculateDistanceInMeters(userLat, userLng, listing.latitude!, listing.longitude!)
        : null;

    final isFree = listing.isFree;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(listing.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: Icon(
              listing.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: listing.isFavorite ? Colors.redAccent : AppColors.textPrimary,
            ),
            onPressed: () {
              listingProvider.toggleFavorite(currentUserId, listing);
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (val) {
              if (val == 'blockchain') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BlockchainHistoryScreen()),
                );
              } else if (val == 'report') {
                _showReportDialog(context, listing);
              } else if (val == 'edit') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddEditListingScreen(listingToEdit: listing),
                  ),
                );
              } else if (val == 'delete') {
                listingProvider.deleteListing(listing.id);
                Navigator.pop(context);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'blockchain',
                child: Row(
                  children: [
                    Icon(Icons.history_rounded, color: AppColors.primary, size: 18),
                    SizedBox(width: 8),
                    Text('Riwayat Aktivitas'),
                  ],
                ),
              ),
              if (isOwner) ...[
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Edit Iklan'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                      SizedBox(width: 8),
                      Text('Hapus Iklan', style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ] else ...[
                const PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.flag_outlined, color: AppColors.error, size: 18),
                      SizedBox(width: 8),
                      Text('Laporkan Iklan', style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo Carousel
                  Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      SizedBox(
                        height: 280,
                        width: double.infinity,
                        child: PageView.builder(
                          controller: _imagePageController,
                          itemCount: listing.images.isNotEmpty ? listing.images.length : 1,
                          onPageChanged: (i) => setState(() => _activeImageIndex = i),
                          itemBuilder: (context, index) {
                            final imgUrl = listing.images.isNotEmpty
                                ? listing.images[index]
                                : 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=600';
                            return _buildDetailImage(imgUrl);
                          },
                        ),
                      ),

                      // Indicators
                      if (listing.images.length > 1)
                        Positioned(
                          bottom: 12,
                          child: Row(
                            children: List.generate(
                              listing.images.length,
                              (idx) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                height: 6,
                                width: _activeImageIndex == idx ? 16 : 6,
                                decoration: BoxDecoration(
                                  color: _activeImageIndex == idx ? Colors.white : Colors.white.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Status Overlay if not Tersedia
                      if (listing.status != 'Tersedia')
                        Positioned(
                          top: 16,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: listing.isNegotiating ? AppColors.secondary : AppColors.statusCompleted,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              listing.status.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Header Info
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Price Tag / Free badge
                        Row(
                          children: [
                            if (isFree)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.freeBadge,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.volunteer_activism, size: 14, color: Colors.white),
                                    SizedBox(width: 6),
                                    Text(
                                      'GRATIS / FREE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Text(
                                CurrencyFormatter.format(listing.price),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            const Spacer(),
                            // Category Tag
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                listing.categoryName,
                                style: const TextStyle(
                                  color: AppColors.primaryDark,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Title
                        Text(
                          listing.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Time & Condition Badge
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.border.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Kondisi: ${listing.condition}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '•  ${DateFormatter.formatRelative(listing.createdAt)}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 12),

                        // Location & LBS Details
                        const Text(
                          'Lokasi Pengambilan & Pertemuan',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        // Short description above the map
                        const Text(
                          'Titik temu pengambilan barang disepakati langsung (COD) di sekitar area berikut. Disarankan memilih tempat umum yang aman dan ramai seperti minimarket, kafe, atau lobi kampus.',
                          style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
                        ),
                        const SizedBox(height: 12),

                        // Location name and distance pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primaryLight),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 16),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      listing.locationName,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                    if (distanceMeters != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          'Perkiraan Jarak: ${LocationHelper.formatDistance(distanceMeters)} dari posisi Anda',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Interactive Pickup Location Map (Draggable, Zoom In/Out, Google Maps style)
                        PickupLocationMapWidget(
                          latitude: listing.latitude ?? -7.7601,
                          longitude: listing.longitude ?? 110.3752,
                          locationName: listing.locationName,
                          distanceMeters: distanceMeters,
                        ),
                        const SizedBox(height: 10),

                        // Safety tip below map
                        const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.shield_outlined, color: AppColors.textSecondary, size: 14),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Tips Keamanan: Sepakati titik temu (COD) di tempat umum yang ramai. Hindari tempat sepi atau waktu larut malam.',
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Description
                        const Text(
                          'Deskripsi Barang',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          listing.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 12),

                        // Seller Card
                        const Text(
                          'Informasi Pemilik Barang',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.primarySurface,
                                backgroundImage: listing.sellerAvatar != null
                                    ? NetworkImage(listing.sellerAvatar!)
                                    : null,
                                child: listing.sellerAvatar == null
                                    ? const Icon(Icons.person, color: AppColors.primary)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      listing.sellerName,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 2),
                                    const Row(
                                      children: [
                                        Icon(Icons.verified_rounded, size: 14, color: AppColors.primary),
                                        SizedBox(width: 4),
                                        Text(
                                          'Anggota Terverifikasi jadiGuna',
                                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Blockchain audit provenance link
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const BlockchainHistoryScreen()),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.primaryLight),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.history_rounded, color: AppColors.primary, size: 22),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Riwayat Aktivitas Barang',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primaryDark,
                                        ),
                                      ),
                                      Text(
                                        'Setiap perubahan status tercatat aman dan terverifikasi konsisten.',
                                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: isOwner
                  ? Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Ubah Status Barang',
                            icon: Icons.sync_alt_rounded,
                            onPressed: () => _showStatusDialog(context, listing, listingProvider, currentUserName),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: isFree ? 'Hubungi untuk Mengambil' : 'Hubungi Penjual (Chat)',
                            icon: Icons.chat_bubble_rounded,
                            onPressed: () async {
                              final navigator = Navigator.of(context);
                              final conv = await chatProvider.openConversationForListing(
                                listing: listing,
                                buyerId: currentUserId,
                                buyerName: currentUserName,
                              );
                              if (!mounted) return;
                              navigator.push(
                                MaterialPageRoute(
                                  builder: (_) => ChatDetailScreen(conversation: conv),
                                ),
                              );
                            },
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
