import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/location_helper.dart';
import '../../models/listing_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_provider.dart';
import '../../providers/chat_provider.dart';
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
  bool _isBookmarked = false;

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
        categoryId: 'cat_furnitur',
        categoryName: 'Furnitur',
        title: 'Meja Belajar Kayu Jati Minimalis',
        description: 'Kondisi kayu jati belanda kokoh tanpa jejak rayap, permukaan mulus baru di-finishing ulang vernis doff. Pemilik melepas karena telah wisuda & persiapan pindah kota.',
        price: 150000,
        condition: 'Sangat Baik',
        locationName: 'Jl. Kaliurang Km 5, Sleman',
        images: ['https://images.unsplash.com/photo-1518455027359-f3f8164ba6bd?w=800'],
        sellerName: 'Budi Santoso',
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
    final totalImages = listing.images.isNotEmpty ? listing.images.length : 1;

    return Scaffold(
      backgroundColor: AppColors.background,
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

                // Circle Brand Logo
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 18,
                      height: 18,
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
                const SizedBox(width: 10),

                // Title "Detail Barang"
                const Text(
                  'Detail Barang',
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
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tautan barang berhasil disalin!'),
                        duration: Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),

                // User Avatar
                const CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: NetworkImage(
                    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200',
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: AppColors.textPrimary, size: 20),
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
                          Text('Riwayat Ledger'),
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
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // Breadcrumb / Category Row with Favorite & Bookmark icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.near_me_outlined, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            'Sleman • ${listing.categoryName}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              listing.isFavorite ? Icons.favorite : Icons.favorite_border_rounded,
                              color: listing.isFavorite ? AppColors.terracotta : AppColors.textPrimary,
                              size: 22,
                            ),
                            onPressed: () {
                              listingProvider.toggleFavorite(currentUserId, listing);
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              _isBookmarked ? Icons.bookmark : Icons.bookmark_border_rounded,
                              color: AppColors.textPrimary,
                              size: 22,
                            ),
                            onPressed: () {
                              setState(() => _isBookmarked = !_isBookmarked);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Photo Carousel with rounded container matching Image 2
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        SizedBox(
                          height: 290,
                          width: double.infinity,
                          child: PageView.builder(
                            controller: _imagePageController,
                            itemCount: totalImages,
                            onPageChanged: (i) => setState(() => _activeImageIndex = i),
                            itemBuilder: (context, index) {
                              final imgUrl = listing.images.isNotEmpty
                                  ? listing.images[index]
                                  : 'https://images.unsplash.com/photo-1518455027359-f3f8164ba6bd?w=800';
                              return _buildDetailImage(imgUrl);
                            },
                          ),
                        ),

                        // Badges at top-left: "• Tersedia" and "✔ Terverifikasi"
                        Positioned(
                          top: 14,
                          left: 14,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1B281E),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  '• ${listing.status}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle_outline_rounded, size: 12, color: AppColors.primary),
                                    SizedBox(width: 4),
                                    Text(
                                      'Terverifikasi',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Expand icon (Bottom Left)
                        Positioned(
                          bottom: 14,
                          left: 14,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.35),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.crop_free_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        // Image Counter "1/4" (Bottom Right)
                        Positioned(
                          bottom: 14,
                          right: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_activeImageIndex + 1}/$totalImages',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Title & Subtitle
                  Text(
                    listing.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.25,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Bonus rak buku kecil serasi • Dijual cepat karena relokasi kos',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Price Row & Bisa Nego Tag
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        isFree ? 'RP.0' : CurrencyFormatter.format(listing.price),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: isFree ? AppColors.terracotta : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDECE8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isFree ? '100% Gratis' : 'Bisa Nego Santai',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.terracotta,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Condition Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1EFEA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Kondisi: 9/10 (${listing.condition})',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Location Row
                  Row(
                    children: [
                      const Icon(Icons.near_me_outlined, size: 14, color: AppColors.terracotta),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          distanceMeters != null
                              ? '${listing.locationName} • ${LocationHelper.formatDistance(distanceMeters)} dari lokasimu'
                              : 'Jl. Kaliurang Km 5, Sleman • 800 m dari lokasimu',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // RINGKASAN CERDAS AI Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3EFE7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE5DFD5), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.auto_awesome, size: 16, color: AppColors.primary),
                                SizedBox(width: 6),
                                Text(
                                  'RINGKASAN CERDAS AI',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF27382B),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'LLM Analisis',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          '“Kondisi kayu jati belanda kokoh tanpa jejak rayap, permukaan mulus baru di-finishing ulang vernis doff. Pemilik melepas karena telah wisuda & persiapan pindah kota. Sangat mudah diangkut motor roda dua karena sistem kaki baut modular knock-down.”',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.45,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: const [
                            Icon(Icons.verified_outlined, size: 13, color: AppColors.textSecondary),
                            SizedBox(width: 4),
                            Text(
                              '98% Relevansi Real',
                              style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                            ),
                            SizedBox(width: 14),
                            Icon(Icons.auto_awesome_outlined, size: 13, color: AppColors.textSecondary),
                            SizedBox(width: 4),
                            Text(
                              'Dianalisis 5 mnt lalu',
                              style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Spesifikasi & Deskripsi Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Spesifikasi & Deskripsi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 3 Dimension Boxes (Panjang | Lebar | Tinggi)
                        Row(
                          children: [
                            _buildDimensionBox('PANJANG', '100 cm'),
                            const SizedBox(width: 8),
                            _buildDimensionBox('LEBAR', '50 cm'),
                            const SizedBox(width: 8),
                            _buildDimensionBox('TINGGI', '75 cm'),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Checklist Bullets
                        _buildChecklistRow('Bahan utama: Kayu Solid Jati Belanda tahan lembap, serat natural cantik.'),
                        _buildChecklistRow('Dilengkapi 1 unit rak buku susun portabel (bisa dipindah kiri/kanan).'),
                        _buildChecklistRow('Seluruh baut & ring L original masih lengkap, dapat kunci L bawaan.'),
                        _buildChecklistRow('Tidak ada retak struktural, hanya goresan mikro wajar bekas laptop.'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // PEMILIK BARANG Section
                  const Text(
                    'PEMILIK BARANG',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.primarySurface,
                          backgroundImage: NetworkImage(
                            listing.sellerAvatar ?? 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    listing.sellerName,
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
                                '★ 4.9 • 24 transaksi sirkular',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 1),
                              const Text(
                                'Warga aktif Sleman sejak 2023',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F2EA),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shield_outlined, size: 11, color: AppColors.primary),
                              SizedBox(width: 3),
                              Text(
                                'Terverifikasi',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Titik Temu Aman (COD)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.location_on_outlined, color: AppColors.terracotta, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'Titik Temu Aman\n(COD)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDECE8),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Rekomendasi LBS',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.terracotta,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Area publik ramai, terang, dan dipantau CCTV 24 jam untuk transaksi tenang tanpa was-was.',
                          style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.35),
                        ),
                        const SizedBox(height: 12),

                        // Minimap card preview
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                                child: SizedBox(
                                  height: 120,
                                  child: PickupLocationMapWidget(
                                    latitude: listing.latitude ?? -7.7601,
                                    longitude: listing.longitude ?? 110.3752,
                                    locationName: listing.locationName,
                                    distanceMeters: distanceMeters,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: const [
                                          Text(
                                            'Indomaret Point Pandega Marta',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                          ),
                                          Text(
                                            'Aman • Parkir luas • Terang',
                                            style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1B281E),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.near_me_rounded, color: Colors.white, size: 11),
                                          SizedBox(width: 4),
                                          Text(
                                            'Rute',
                                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
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
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Verifikasi Status Rantai
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BlockchainHistoryScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.token_rounded, color: AppColors.primary, size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    'Verifikasi Status\nRantai',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD4E8D7),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'SHA-256 Valid',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF265438),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textSecondary),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Jejak riwayat kepemilikan dan integritas harga dicatat permanen dalam ledger sirkular lokal.',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 12),

                          // Block #1204
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F7F3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: const [
                                    Text('Block #1204 • Genesis Created', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700)),
                                    Text('18 Okt • 14:20 WIB', style: TextStyle(fontSize: 9.5, color: AppColors.textTertiary)),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: const [
                                    Text('Listing Awal (Rp 180.000)', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                    Text('0x7f8a...b23d', style: TextStyle(fontSize: 9.5, color: AppColors.textTertiary)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Block #1205
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDECE8).withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: const [
                                    Text('Block #1205 • Price Updated', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.terracotta)),
                                    Text('19 Okt • 09:15 WIB', style: TextStyle(fontSize: 9.5, color: AppColors.textTertiary)),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: const [
                                    Text('Penyesuaian Harga (Rp 150.000)', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                    Text('0x3c9e...fe84', style: TextStyle(fontSize: 9.5, color: AppColors.textTertiary)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.lock_outline_rounded, size: 12, color: AppColors.textTertiary),
                              SizedBox(width: 4),
                              Text(
                                'Ledger Konsensus Komunitas Sleman Utara',
                                style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),

          // Bottom Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.8), width: 1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
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
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                            icon: const Icon(Icons.sync_alt_rounded, size: 18),
                            label: const Text('Ubah Status Barang', style: TextStyle(fontWeight: FontWeight.w700)),
                            onPressed: () => _showStatusDialog(context, listing, listingProvider, currentUserName),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        // Nego Button
                        InkWell(
                          onTap: () async {
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
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1EFEA),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppColors.textPrimary),
                                SizedBox(width: 6),
                                Text(
                                  'Nego',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Ambil Barang Button
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF27382B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              elevation: 0,
                            ),
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
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Ambil Barang',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                ),
                                SizedBox(width: 6),
                                Icon(Icons.arrow_forward_rounded, size: 16),
                              ],
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

  Widget _buildDimensionBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F3EC),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
