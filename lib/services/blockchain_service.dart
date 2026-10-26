import '../models/block_model.dart';
import '../core/database/local_database.dart';

class BlockchainVerificationResult {
  final bool isValid;
  final int? corruptedBlockIndex;
  final String message;

  const BlockchainVerificationResult({
    required this.isValid,
    this.corruptedBlockIndex,
    required this.message,
  });
}

class BlockchainService {
  final LocalDatabase _db = LocalDatabase.instance;

  Future<List<BlockModel>> getChain() async {
    return await _db.getBlockchainRecords();
  }

  /// Get blockchain records filtered for a specific listing
  Future<List<BlockModel>> getChainForListing(String listingId) async {
    final all = await getChain();
    return all.where((b) => b.listingId == listingId).toList();
  }

  /// Add a new status transition block to the blockchain ledger
  Future<BlockModel> addBlock({
    required String listingId,
    required String itemTitle,
    required String previousStatus,
    required String newStatus,
    required String actorName,
    String notes = '',
  }) async {
    final latest = await _db.getLatestBlock();
    final nextIndex = (latest?.index ?? 0) + 1;
    final prevHash = latest?.hash ?? '0000000000000000000000000000000000000000000000000000000000000000';
    final timestamp = DateTime.now();

    final hash = BlockModel.calculateHash(
      index: nextIndex,
      timestamp: timestamp,
      listingId: listingId,
      itemTitle: itemTitle,
      previousStatus: previousStatus,
      newStatus: newStatus,
      actorName: actorName,
      notes: notes,
      previousHash: prevHash,
    );

    final newBlock = BlockModel(
      index: nextIndex,
      timestamp: timestamp,
      listingId: listingId,
      itemTitle: itemTitle,
      previousStatus: previousStatus,
      newStatus: newStatus,
      actorName: actorName,
      notes: notes,
      previousHash: prevHash,
      hash: hash,
    );

    await _db.insertBlock(newBlock);
    return newBlock;
  }

  /// Verify the cryptographic integrity of the entire chain
  Future<BlockchainVerificationResult> verifyChain() async {
    final chain = await getChain();
    if (chain.isEmpty) {
      return const BlockchainVerificationResult(
        isValid: true,
        message: 'Rantai blockchain masih kosong.',
      );
    }

    for (int i = 0; i < chain.length; i++) {
      final current = chain[i];

      // 1. Verify block self-hash
      if (!current.isValid) {
        return BlockchainVerificationResult(
          isValid: false,
          corruptedBlockIndex: current.index,
          message:
              'Pelanggaran integritas terdeteksi pada Blok #${current.index}: Konten data telah dimanipulasi sehingga nilai hash SHA-256 tidak lagi cocok!',
        );
      }

      // 2. Verify previous hash link (except genesis block 0)
      if (i > 0) {
        final previous = chain[i - 1];
        if (current.previousHash != previous.hash) {
          return BlockchainVerificationResult(
            isValid: false,
            corruptedBlockIndex: current.index,
            message:
                'Tautan rantai terputus pada Blok #${current.index}: Previous Hash tidak cocok dengan Hash Blok #${previous.index}!',
          );
        }
      }
    }

    return BlockchainVerificationResult(
      isValid: true,
      message:
          'Semua ${chain.length} blok terverifikasi valid! Rantai SHA-256 utuh tanpa ada perubahan ilegal.',
    );
  }

  /// Tamper with a block to demonstrate integrity verification failure
  Future<void> simulateTampering(int blockIndex, String maliciousStatus) async {
    await _db.tamperBlockForTesting(blockIndex, maliciousStatus);
  }

  /// Reset chain to initial verified state
  Future<void> resetChain() async {
    await _db.resetBlockchain();
  }
}
