import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/blockchain_config.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/block_model.dart';
import '../../services/blockchain_service.dart';

class BlockchainHistoryScreen extends StatefulWidget {
  const BlockchainHistoryScreen({super.key});

  @override
  State<BlockchainHistoryScreen> createState() => _BlockchainHistoryScreenState();
}

class _BlockchainHistoryScreenState extends State<BlockchainHistoryScreen> {
  final BlockchainService _blockchainService = BlockchainService();
  List<BlockModel> _chain = [];
  bool _isLoading = true;
  bool _isVerifying = false;
  BlockchainVerificationResult? _verificationResult;
  final Set<int> _expandedTechnicalDetails = {};

  @override
  void initState() {
    super.initState();
    _loadChain();
  }

  Future<void> _loadChain() async {
    setState(() => _isLoading = true);
    final blocks = await _blockchainService.getChain();
    final verification = await _blockchainService.verifyChain();
    setState(() {
      _chain = blocks;
      _verificationResult = verification;
      _isLoading = false;
    });
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
    if (_chain.length <= 1) return;
    // Tamper block index 1
    await _blockchainService.simulateTampering(1, 'DIUBAH_SECARA_ILEGAL');
    await _loadChain();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Simulasi manipulasi: Status pada Catatan #1 telah diubah untuk pengujian keaslian data.'),
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
        content: Text('Riwayat aktivitas dikembalikan ke pencatatan awal yang sah.'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _verificationResult?.isValid ?? true;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Riwayat Aktivitas Barang'),
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
                    Icon(Icons.bug_report_outlined, color: AppColors.error, size: 18),
                    SizedBox(width: 8),
                    Text('Uji Coba Manipulasi Data', style: TextStyle(fontSize: 12, color: AppColors.error)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.restore_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Pulihkan Riwayat Asli', style: TextStyle(fontSize: 12)),
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
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Verification Banner Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isValid ? AppColors.freeBadgeBg : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isValid ? AppColors.freeBadge : AppColors.error,
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isValid ? AppColors.freeBadge : AppColors.error).withValues(alpha: 0.08),
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
                                color: isValid ? AppColors.success.withValues(alpha: 0.15) : AppColors.error.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isValid ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                                color: isValid ? AppColors.success : AppColors.error,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isValid ? 'Riwayat berhasil diperiksa' : 'Ketidaksesuaian Catatan Terdeteksi',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: isValid ? AppColors.primaryDark : AppColors.error,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isValid
                                        ? 'Sistem tidak menemukan ketidaksesuaian pada catatan yang diperiksa. Seluruh riwayat aktivitas tercatat secara konsisten dan terverifikasi aman.'
                                        : 'Sistem menemukan perbedaan pada catatan data riwayat (terindikasi ada perubahan yang tidak sah). Silakan periksa catatan bertanda peringatan.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isValid ? AppColors.textPrimary : AppColors.error,
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
                                backgroundColor: isValid ? AppColors.primary : AppColors.error,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: _isVerifying ? null : _handleVerify,
                              icon: _isVerifying
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.fact_check_rounded, size: 16),
                              label: const Text(
                                'Periksa Riwayat',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isValid ? AppColors.freeBadge.withValues(alpha: 0.5) : AppColors.error.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.lock_outline_rounded, size: 13, color: isValid ? AppColors.primaryDark : AppColors.error),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Algoritma SHA-256',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isValid ? AppColors.primaryDark : AppColors.error,
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

                  // Smart Contract & Wallet Configuration Card
                  _buildSmartContractCard(),

                  const SizedBox(height: 22),

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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primaryLight),
                        ),
                        child: Text(
                          '${_chain.length} Catatan Tersimpan',
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
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  // Timeline List
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _chain.length,
                    itemBuilder: (context, index) {
                      return _buildTimelineItem(index);
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildTimelineItem(int index) {
    final block = _chain[index];
    final isFirst = block.index == 0;
    final isLast = index == _chain.length - 1;
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
                            : (block.newStatus.toLowerCase().contains('selesai')
                                ? AppColors.freeBadgeBg
                                : AppColors.primarySurface)),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCorrupted
                          ? AppColors.error
                          : (isFirst
                              ? AppColors.primary
                              : (block.newStatus.toLowerCase().contains('selesai')
                                  ? AppColors.freeBadge
                                  : AppColors.primary)),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      isCorrupted
                          ? Icons.warning_amber_rounded
                          : (isFirst
                              ? Icons.inventory_2_rounded
                              : (block.newStatus.toLowerCase().contains('selesai')
                                  ? Icons.check_rounded
                                  : Icons.sync_alt_rounded)),
                      size: 16,
                      color: isCorrupted
                          ? AppColors.error
                          : (isFirst
                              ? AppColors.primaryDark
                              : (block.newStatus.toLowerCase().contains('selesai')
                                  ? AppColors.primaryDark
                                  : AppColors.primary)),
                    ),
                  ),
                ),
                // Connector line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Activity Card
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCorrupted ? AppColors.error : AppColors.border,
                  width: isCorrupted ? 1.8 : 1,
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
                  // Header Row: Friendly Record Title & Timestamp
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isCorrupted
                              ? Colors.red.shade50
                              : (isFirst ? Colors.purple.shade50 : AppColors.primarySurface),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isFirst ? 'Pencatatan Awal' : 'Catatan #${block.index}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isCorrupted
                                ? AppColors.error
                                : (isFirst ? Colors.purple.shade700 : AppColors.primaryDark),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time_rounded, size: 12, color: AppColors.textTertiary),
                          const SizedBox(width: 4),
                          Text(
                            DateFormatter.formatDate(block.timestamp),
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          const Text(' • ', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                          Text(
                            DateFormatter.formatTime(block.timestamp),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
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
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),

                  // Status Change Box
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: isFirst
                        ? Row(
                            children: [
                              const Text('Status Awal: ', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                              _buildStatusChip(block.newStatus, isNew: true),
                            ],
                          )
                        : Row(
                            children: [
                              _buildStatusChip(block.previousStatus),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.textSecondary),
                              ),
                              _buildStatusChip(block.newStatus, isNew: true),
                            ],
                          ),
                  ),
                  const SizedBox(height: 10),

                  // User Actor
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 15, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        'Dilakukan oleh: ',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                      Text(
                        block.actorName,
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
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
                          child: Icon(Icons.notes_rounded, size: 14, color: AppColors.textTertiary),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Keterangan: ${block.notes}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textTertiary, fontStyle: FontStyle.italic),
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
                            isExpanded ? Icons.tune_rounded : Icons.code_rounded,
                            size: 15,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isExpanded ? 'Sembunyikan Detail Teknis' : 'Lihat Detail Teknis',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
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
                        border: Border.all(color: isCorrupted ? AppColors.error : AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.security_rounded, size: 14, color: AppColors.primaryDark),
                              const SizedBox(width: 6),
                              const Text(
                                'Informasi Blockchain & Keamanan Data',
                                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isCorrupted ? Colors.red.shade100 : AppColors.freeBadgeBg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isCorrupted ? 'Modifikasi Terdeteksi' : 'Data Asli & Konsisten',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: isCorrupted ? AppColors.error : AppColors.primaryDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('Nomor Blok: ', style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                              Text('#${block.index}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 14),
                              const Text('Algoritma: ', style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                              const Text('SHA-256', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Text('Publisher Dompet: ', style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                              Text(
                                BlockchainConfig.shortWalletAddress(),
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                  color: AppColors.primaryDark,
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

  Widget _buildSmartContractCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryLight),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppColors.primaryDark,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Contract & Wallet Notarisasi',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Terhubung dengan Smart Contract Remix EVM',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.freeBadgeBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.freeBadge),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 12, color: AppColors.primaryDark),
                    SizedBox(width: 4),
                    Text(
                      'On-Chain',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
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

          // Contract Address Section
          _buildAddressTile(
            title: 'Alamat Smart Contract (Remix)',
            address: BlockchainConfig.contractAddress,
            icon: Icons.description_outlined,
            tag: 'Contract',
          ),
          const SizedBox(height: 10),

          // Wallet Owner Section
          _buildAddressTile(
            title: 'Dompet Wallet Pribadi (Owner / Notaris)',
            address: BlockchainConfig.walletAddress,
            icon: Icons.person_pin_circle_outlined,
            tag: 'Publisher / Owner',
          ),

          const SizedBox(height: 14),

          // Action Buttons: Quick Copy latest Hash & Guide
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    if (_chain.isEmpty) return;
                    final latest = _chain.last;
                    final bytes32 = BlockchainConfig.toBytes32(latest.hash);
                    Clipboard.setData(ClipboardData(text: bytes32));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Hash Blok #${latest.index} disalin (bytes32):\n$bytes32'),
                        backgroundColor: AppColors.primary,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  },
                  icon: const Icon(Icons.content_copy_rounded, size: 14),
                  label: const Text(
                    'Salin Hash Terbaru',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _showPublishGuideModal(context),
                  icon: const Icon(Icons.help_outline_rounded, size: 14),
                  label: const Text(
                    'Panduan publish',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressTile({
    required String title,
    required String address,
    required IconData icon,
    required String tag,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 5),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  address,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: address));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$title berhasil disalin!'),
                      backgroundColor: AppColors.primary,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.copy_rounded, size: 14, color: AppColors.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPublishGuideModal(BuildContext context) {
    final latestBlock = _chain.isNotEmpty ? _chain.last : null;
    final latestBytes32 = latestBlock != null ? BlockchainConfig.toBytes32(latestBlock.hash) : '';
    final tagSample = latestBlock != null
        ? 'jadiGuna Blok #${latestBlock.index} - ${latestBlock.itemTitle}'
        : 'jadiGuna Ledger';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.primarySurface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.terminal_rounded, color: AppColors.primaryDark, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Panduan publishHash di Remix',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Data yang perlu diisi di tombol publishHash',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // Step 1: Account
              _buildGuideField(
                label: '1. Pastikan Account Pengirim di Remix adalah Dompet Anda:',
                value: BlockchainConfig.walletAddress,
                tooltipText: 'Dompet Publisher',
              ),
              const SizedBox(height: 12),

              // Step 2: _hash (bytes32)
              _buildGuideField(
                label: '2. Masukkan ke kolom _hash (bytes32):',
                value: latestBytes32,
                tooltipText: 'Hash bytes32',
              ),
              const SizedBox(height: 12),

              // Step 3: _tag (string)
              _buildGuideField(
                label: '3. Masukkan ke kolom _tag (string):',
                value: tagSample,
                tooltipText: 'Tag catatan',
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.freeBadgeBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.freeBadge),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primaryDark),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Setelah mengisi dua kolom di atas, klik tombol "transact" oranye di Remix dan konfirmasi transaksi di wallet Anda. Tombol lainnya diabaikan saja.',
                        style: TextStyle(fontSize: 11.5, color: AppColors.primaryDark, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Saya Mengerti', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGuideField({
    required String label,
    required String value,
    required String tooltipText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$tooltipText disalin!'),
                      backgroundColor: AppColors.primary,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.copy_rounded, size: 15, color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ],
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

  Widget _buildHashRow(String label, String hash, {bool isCurrent = false, bool isInvalid = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            if (isCurrent)
              InkWell(
                onTap: () {
                  final bytes32 = BlockchainConfig.toBytes32(hash);
                  Clipboard.setData(ClipboardData(text: bytes32));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hash bytes32 disalin untuk Remix:\n$bytes32'),
                      backgroundColor: AppColors.primary,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.copy_rounded, size: 11, color: AppColors.primary),
                    SizedBox(width: 3),
                    Text(
                      'Salin bytes32 (Remix)',
                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ],
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
            border: Border.all(color: isInvalid ? AppColors.error : AppColors.border),
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
