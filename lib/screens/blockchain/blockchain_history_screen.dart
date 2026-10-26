import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/block_model.dart';
import '../../services/blockchain_service.dart';

class BlockchainHistoryScreen extends StatefulWidget {
  final String? filterListingId;
  final String? filterItemTitle;

  const BlockchainHistoryScreen({
    super.key,
    this.filterListingId,
    this.filterItemTitle,
  });

  @override
  State<BlockchainHistoryScreen> createState() =>
      _BlockchainHistoryScreenState();
}

class _BlockchainHistoryScreenState extends State<BlockchainHistoryScreen> {
  final BlockchainService _blockchainService = BlockchainService();
  List<BlockModel> _fullChain = [];
  bool _isLoading = true;
  bool _isVerifying = false;
  BlockchainVerificationResult? _verificationResult;
  final Set<int> _expandedTechnicalDetails = {};

  String? _activeListingId;
  String? _activeItemTitle;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _activeListingId = widget.filterListingId;
    _activeItemTitle = widget.filterItemTitle;
    _loadChain();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadChain() async {
    setState(() => _isLoading = true);
    final blocks = await _blockchainService.getChain();
    final verification = await _blockchainService.verifyChain();
    setState(() {
      _fullChain = blocks;
      _verificationResult = verification;
      _isLoading = false;
    });
  }

  List<BlockModel> get _displayedChain {
    return _fullChain.where((block) {
      // 1. Filter by specific listing if set
      if (_activeListingId != null && block.listingId != _activeListingId) {
        return false;
      }
      // 2. Filter by search query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = block.itemTitle.toLowerCase().contains(q);
        final matchActor = block.actorName.toLowerCase().contains(q);
        final matchStatus =
            block.newStatus.toLowerCase().contains(q) ||
            block.previousStatus.toLowerCase().contains(q);
        final matchNotes = block.notes.toLowerCase().contains(q);
        return matchTitle || matchActor || matchStatus || matchNotes;
      }
      return true;
    }).toList();
  }

  Future<void> _handleVerify() async {
    setState(() => _isVerifying = true);
    final result = await _blockchainService.verifyChain();
    setState(() {
      _verificationResult = result;
      _isVerifying = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isValid
              ? 'Pemeriksaan berhasil: Tidak ada ketidaksesuaian data pada seluruh catatan.'
              : 'Peringatan: Ditemukan ketidaksesuaian pada data riwayat!',
        ),
        backgroundColor: result.isValid ? AppColors.success : AppColors.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _handleSimulateTamper() async {
    if (_fullChain.length <= 1) return;
    // Tamper block index 1
    await _blockchainService.simulateTampering(1, 'DIUBAH_SECARA_ILEGAL');
    await _loadChain();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Simulasi manipulasi: Status pada Catatan #1 telah diubah untuk pengujian keaslian data.',
        ),
        backgroundColor: AppColors.error,
        duration: Duration(seconds: 4),
      ),
    );
  }

  Future<void> _handleReset() async {
    await _blockchainService.resetChain();
    await _loadChain();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Riwayat aktivitas dikembalikan ke pencatatan awal yang sah.',
        ),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label berhasil disalin ke clipboard!'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _verificationResult?.isValid ?? true;
    final displayed = _displayedChain;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _activeItemTitle != null
              ? 'Riwayat: $_activeItemTitle'
              : 'Riwayat Aktivitas Barang',
        ),
        actions: [
          IconButton(
            tooltip: 'Muat Ulang',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadChain,
          ),
          PopupMenuButton<String>(
            tooltip: 'Opsi Pengujian',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (val) {
              if (val == 'tamper') _handleSimulateTamper();
              if (val == 'reset') _handleReset();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'tamper',
                child: Row(
                  children: [
                    Icon(
                      Icons.bug_report_outlined,
                      color: AppColors.error,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Uji Coba Manipulasi Data',
                      style: TextStyle(fontSize: 12, color: AppColors.error),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.restore_rounded, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Pulihkan Riwayat Asli',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Verification Banner Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isValid
                          ? AppColors.freeBadgeBg
                          : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isValid ? AppColors.freeBadge : AppColors.error,
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (isValid ? AppColors.freeBadge : AppColors.error)
                                  .withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isValid
                                    ? AppColors.success.withValues(alpha: 0.15)
                                    : AppColors.error.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isValid
                                    ? Icons.check_circle_rounded
                                    : Icons.warning_amber_rounded,
                                color: isValid
                                    ? AppColors.success
                                    : AppColors.error,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isValid
                                        ? 'Riwayat Terverifikasi Utuh'
                                        : 'Ketidaksesuaian Catatan Terdeteksi',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: isValid
                                          ? AppColors.primaryDark
                                          : AppColors.error,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isValid
                                        ? 'Seluruh data rantai terverifikasi aman melalui segel kriptografi SHA-256. Tidak ada catatan yang dimodifikasi tanpa izin.'
                                        : 'Sistem menemukan ketidaksesuaian hash kriptografi (terindikasi ada data yang diubah di luar konsensus).',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isValid
                                          ? AppColors.textPrimary
                                          : AppColors.error,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isValid
                                    ? AppColors.primary
                                    : AppColors.error,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: _isVerifying ? null : _handleVerify,
                              icon: _isVerifying
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.fact_check_rounded,
                                      size: 16,
                                    ),
                              label: const Text(
                                'Periksa Riwayat',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isValid
                                      ? AppColors.freeBadge.withValues(
                                          alpha: 0.5,
                                        )
                                      : AppColors.error.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.lock_outline_rounded,
                                    size: 13,
                                    color: isValid
                                        ? AppColors.primaryDark
                                        : AppColors.error,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Algoritma SHA-256',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isValid
                                          ? AppColors.primaryDark
                                          : AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari barang, pelaku, atau status...',
                        hintStyle: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textTertiary,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                      onChanged: (val) {
                        setState(() => _searchQuery = val.trim());
                      },
                    ),
                  ),

                  // Active Filter Banner if filtered by listing
                  if (_activeListingId != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primaryLight),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.filter_list_rounded,
                            size: 16,
                            color: AppColors.primaryDark,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Menampilkan riwayat untuk: ${_activeItemTitle ?? "Barang ini"}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: () {
                              setState(() {
                                _activeListingId = null;
                                _activeItemTitle = null;
                              });
                            },
                            child: const Text(
                              'Tampilkan Semua',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Section Title Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Linimasa Aktivitas',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primaryLight),
                        ),
                        child: Text(
                          '${displayed.length} Catatan',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Riwayat kronologis setiap perubahan status barang yang tercatat secara permanen.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Timeline List
                  if (displayed.isEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Tidak ada catatan riwayat yang cocok.',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Coba ubah kata kunci pencarian atau tampilkan seluruh catatan.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayed.length,
                      itemBuilder: (context, index) {
                        return _buildTimelineItem(displayed, index);
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildTimelineItem(List<BlockModel> list, int index) {
    final block = list[index];
    final isFirst = block.index == 0;
    final isLast = index == list.length - 1;
    final isCorrupted = !block.isValid;
    final isExpanded = _expandedTechnicalDetails.contains(block.index);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Axis (Nodes & Line)
          SizedBox(
            width: 38,
            child: Column(
              children: [
                // Node Icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCorrupted
                        ? Colors.red.shade100
                        : (isFirst
                              ? AppColors.primaryLight
                              : (block.newStatus.toLowerCase().contains(
                                      'selesai',
                                    )
                                    ? AppColors.freeBadgeBg
                                    : AppColors.primarySurface)),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCorrupted
                          ? AppColors.error
                          : (isFirst
                                ? AppColors.primary
                                : AppColors.primaryLight),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      isCorrupted
                          ? Icons.priority_high_rounded
                          : (isFirst
                                ? Icons.flag_rounded
                                : (block.newStatus.toLowerCase().contains(
                                        'selesai',
                                      )
                                      ? Icons.check_rounded
                                      : Icons.sync_alt_rounded)),
                      size: 16,
                      color: isCorrupted
                          ? AppColors.error
                          : AppColors.primaryDark,
                    ),
                  ),
                ),
                // Vertical Line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isCorrupted
                          ? Colors.red.shade200
                          : AppColors.border,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Timeline Content Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isCorrupted ? AppColors.error : AppColors.border,
                  width: isCorrupted ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card Header: Block Index, Badge & Timestamp
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Blok #${block.index}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                          if (isFirst) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Genesis',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormatter.formatTime(block.timestamp),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Item Name & Activity Summary
                  Text(
                    block.itemTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isFirst
                        ? 'Barang didaftarkan ke sistem jadiGuna'
                        : 'Pembaruan status aktivitas barang',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Status Change Box
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: isFirst
                        ? Row(
                            children: [
                              const Text(
                                'Status Awal: ',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              _buildStatusChip(block.newStatus, isNew: true),
                            ],
                          )
                        : Row(
                            children: [
                              _buildStatusChip(block.previousStatus),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              _buildStatusChip(block.newStatus, isNew: true),
                            ],
                          ),
                  ),
                  const SizedBox(height: 10),

                  // User Actor
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 15,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Dilakukan oleh: ',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        block.actorName,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),

                  // Notes if present
                  if (block.notes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.notes_rounded,
                            size: 14,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Keterangan: ${block.notes}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textTertiary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  // Button "Lihat Detail Teknis" (Hashes hidden by default)
                  InkWell(
                    onTap: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedTechnicalDetails.remove(block.index);
                        } else {
                          _expandedTechnicalDetails.add(block.index);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            isExpanded
                                ? Icons.tune_rounded
                                : Icons.code_rounded,
                            size: 15,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isExpanded
                                ? 'Sembunyikan Detail Teknis'
                                : 'Lihat Detail Teknis & Segel Hash',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Technical details revealed when expanded
                  if (isExpanded) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isCorrupted
                              ? AppColors.error
                              : AppColors.border,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.security_rounded,
                                size: 14,
                                color: AppColors.primaryDark,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Informasi Blockchain & Keamanan Data',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isCorrupted
                                      ? Colors.red.shade100
                                      : AppColors.freeBadgeBg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isCorrupted
                                      ? 'Modifikasi Terdeteksi'
                                      : 'Data Asli & Konsisten',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: isCorrupted
                                        ? AppColors.error
                                        : AppColors.primaryDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text(
                                'Nomor Blok: ',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                '#${block.index}',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Text(
                                'Algoritma: ',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const Text(
                                'SHA-256',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildHashRow(
                            'Segel Keamanan Digital (SHA-256 Hash)',
                            block.hash,
                            isCurrent: true,
                            isInvalid: isCorrupted,
                          ),
                          const SizedBox(height: 6),
                          _buildHashRow(
                            'Kode Tautan Sebelumnya (Previous Hash)',
                            block.previousHash,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, {bool isNew = false}) {
    Color chipColor = isNew ? AppColors.primarySurface : Colors.white;
    Color textColor = isNew ? AppColors.primaryDark : AppColors.textSecondary;
    Color borderColor = isNew ? AppColors.primary : AppColors.border;

    final lower = status.toLowerCase();
    if (lower.contains('selesai') || lower.contains('terjual')) {
      chipColor = isNew ? AppColors.freeBadgeBg : Colors.white;
      textColor = isNew ? AppColors.primaryDark : AppColors.textSecondary;
      borderColor = isNew ? AppColors.freeBadge : AppColors.border;
    } else if (lower.contains('kesepakatan') || lower.contains('nego')) {
      chipColor = isNew ? AppColors.secondaryLight : Colors.white;
      textColor = isNew ? Colors.amber.shade900 : AppColors.textSecondary;
      borderColor = isNew ? AppColors.secondary : AppColors.border;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isNew ? FontWeight.w700 : FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildHashRow(
    String label,
    String hash, {
    bool isCurrent = false,
    bool isInvalid = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            InkWell(
              onTap: () => _copyToClipboard(hash, label),
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      Icons.copy_rounded,
                      size: 11,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 3),
                    Text(
                      'Salin',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: isInvalid ? Colors.red.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isInvalid ? AppColors.error : AppColors.border,
            ),
          ),
          child: Text(
            hash,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 9.5,
              color: isInvalid ? AppColors.error : AppColors.textPrimary,
              letterSpacing: 0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
