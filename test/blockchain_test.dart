import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:jadiguna/models/block_model.dart';
import 'package:jadiguna/services/blockchain_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Blockchain Unit Tests', () {
    test('BlockModel generates consistent SHA-256 hash', () {
      final now = DateTime(2026, 1, 1, 12, 0, 0);
      final hash1 = BlockModel.calculateHash(
        index: 1,
        timestamp: now,
        listingId: 'item-101',
        itemTitle: 'Meja Belajar',
        previousStatus: 'Baru',
        newStatus: 'Tersedia',
        actorName: 'Ahmad',
        notes: 'Daftar pertama',
        previousHash: '0000000000000000000000000000000000000000000000000000000000000000',
      );

      final hash2 = BlockModel.calculateHash(
        index: 1,
        timestamp: now,
        listingId: 'item-101',
        itemTitle: 'Meja Belajar',
        previousStatus: 'Baru',
        newStatus: 'Tersedia',
        actorName: 'Ahmad',
        notes: 'Daftar pertama',
        previousHash: '0000000000000000000000000000000000000000000000000000000000000000',
      );

      expect(hash1, equals(hash2));
      expect(hash1.length, equals(64)); // SHA-256 hex string is 64 characters
    });

    test('BlockModel isValid detects tampered content', () {
      final now = DateTime(2026, 1, 1, 12, 0, 0);
      final validHash = BlockModel.calculateHash(
        index: 1,
        timestamp: now,
        listingId: 'item-101',
        itemTitle: 'Kipas Angin',
        previousStatus: 'Baru',
        newStatus: 'Tersedia',
        actorName: 'Budi',
        notes: '',
        previousHash: '0000000000000000000000000000000000000000000000000000000000000000',
      );

      final block = BlockModel(
        index: 1,
        timestamp: now,
        listingId: 'item-101',
        itemTitle: 'Kipas Angin',
        previousStatus: 'Baru',
        newStatus: 'Tersedia',
        actorName: 'Budi',
        notes: '',
        previousHash: '0000000000000000000000000000000000000000000000000000000000000000',
        hash: validHash,
      );

      expect(block.isValid, isTrue);

      // Simulasikan pemalsuan hash
      final tamperedBlock = BlockModel(
        index: 1,
        timestamp: now,
        listingId: 'item-101',
        itemTitle: 'Kipas Angin',
        previousStatus: 'Baru',
        newStatus: 'DIUBAH_ILEGAL',
        actorName: 'Budi',
        notes: '',
        previousHash: '0000000000000000000000000000000000000000000000000000000000000000',
        hash: validHash, // hash lama tidak cocok lagi dengan status baru
      );

      expect(tamperedBlock.isValid, isFalse);
    });

    test('BlockchainService can verify chain integrity and filter by listing', () async {
      final service = BlockchainService();
      await service.resetChain();

      final chain = await service.getChain();
      expect(chain.isNotEmpty, isTrue);

      // Verifikasi integritas rantai awal
      final result = await service.verifyChain();
      expect(result.isValid, isTrue);

      // Tambah blok baru untuk item khusus
      final testListingId = 'test-item-999';
      await service.addBlock(
        listingId: testListingId,
        itemTitle: 'Laptop Gaming Bekas',
        previousStatus: 'Baru',
        newStatus: 'Tersedia',
        actorName: 'Mahasiswa Tester',
        notes: 'Pengujian Blockchain Unit Test',
      );

      // Cek filter per listing
      final filtered = await service.getChainForListing(testListingId);
      expect(filtered.length, equals(1));
      expect(filtered.first.itemTitle, equals('Laptop Gaming Bekas'));

      // Verifikasi integritas tetap valid setelah penambahan blok
      final verifyAfterAdd = await service.verifyChain();
      expect(verifyAfterAdd.isValid, isTrue);

      // Bersihkan kembali ke kondisi semula
      await service.resetChain();
    });
  });
}
