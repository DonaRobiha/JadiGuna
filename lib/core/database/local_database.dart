import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../models/listing_model.dart';
import '../../models/message_model.dart';
import '../../models/block_model.dart';
import '../../models/feedback_model.dart';
import '../../models/user_model.dart';
import 'sample_data.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static Database? _database;

  LocalDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('jadiguna.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Inisialisasi SQLite untuk Windows, Linux, dan macOS.
    // Android tetap menggunakan SQLite bawaan sqflite.
    if (!kIsWeb &&
        (Platform.isWindows ||
            Platform.isLinux ||
            Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    // Menentukan lokasi database sesuai platform.
    late final String path;

    if (kIsWeb) {
      // Browser menggunakan nama database, bukan path filesystem.
      path = 'jadiguna_web.db';
    } else {
      // Android dan desktop menggunakan lokasi database lokal.
      final dbPath = await getDatabasesPath();
      path = join(dbPath, filePath);
    }

    // Membuka database dan membuat tabel saat pertama kali digunakan.
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onOpen: (db) async {
        // Membersihkan data percakapan contoh tertentu.
        try {
          await db.delete(
            'conversations',
            where: "id = 'conv-001' OR buyer_id = 'current-user-1'",
          );

          await db.delete(
            'messages',
            where: "conversation_id = 'conv-001'",
          );

          await db.delete(
            'favorites',
            where: "user_id = 'current-user-1'",
          );

          // Update/insert sample listings with diverse seller names
          for (var item in SampleData.sampleListings) {
            final exists = await db.query('listings', where: 'id = ?', whereArgs: [item.id]);
            if (exists.isNotEmpty) {
              await db.update(
                'listings',
                {
                  'category_id': item.categoryId,
                  'category_name': item.categoryName,
                  'title': item.title,
                  'description': item.description,
                  'price': item.price,
                  'seller_name': item.sellerName,
                  'condition': item.condition,
                  'location_name': item.locationName,
                  'seller_avatar': item.sellerAvatar,
                  'seller_phone': item.sellerPhone,
                  'images_csv': item.images.join(','),
                },
                where: 'id = ?',
                whereArgs: [item.id],
              );
            } else {
              await db.insert('listings', item.toMap());
            }
          }
        } catch (e) {
          debugPrint('Gagal membersihkan data contoh: $e');
        }
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Listings table
    await db.execute('''
      CREATE TABLE listings (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        category_id TEXT NOT NULL,
        category_name TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        price INTEGER,
        condition TEXT NOT NULL,
        location_name TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        status TEXT NOT NULL,
        images_csv TEXT NOT NULL,
        seller_name TEXT NOT NULL,
        seller_avatar TEXT,
        seller_phone TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // 2. Categories table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        slug TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // 3. Favorites table
    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        listing_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        UNIQUE(user_id, listing_id)
      )
    ''');

    // 4. Conversations table
    await db.execute('''
      CREATE TABLE conversations (
        id TEXT PRIMARY KEY,
        listing_id TEXT NOT NULL,
        listing_title TEXT NOT NULL,
        listing_image TEXT NOT NULL,
        listing_price INTEGER,
        buyer_id TEXT NOT NULL,
        buyer_name TEXT NOT NULL,
        seller_id TEXT NOT NULL,
        seller_name TEXT NOT NULL,
        last_message TEXT NOT NULL,
        last_message_time TEXT NOT NULL,
        unread_count INTEGER DEFAULT 0
      )
    ''');

    // 5. Messages table
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        sender_id TEXT NOT NULL,
        sender_name TEXT NOT NULL,
        message TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_read INTEGER DEFAULT 0
      )
    ''');

    // 6. Blockchain status history table
    await db.execute('''
      CREATE TABLE blockchain_records (
        block_index INTEGER PRIMARY KEY,
        timestamp TEXT NOT NULL,
        listing_id TEXT NOT NULL,
        item_title TEXT NOT NULL,
        previous_status TEXT NOT NULL,
        new_status TEXT NOT NULL,
        actor_name TEXT NOT NULL,
        notes TEXT,
        previous_hash TEXT NOT NULL,
        hash TEXT NOT NULL
      )
    ''');

    // 7. Feedback table
    await db.execute('''
      CREATE TABLE feedback (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        user_name TEXT NOT NULL,
        category TEXT NOT NULL,
        rating INTEGER NOT NULL,
        message TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // 8. User profiles cache table
    await db.execute('''
      CREATE TABLE profiles (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        profile_photo_path TEXT,
        bio TEXT,
        city TEXT,
        phone_number TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // Pre-populate initial categories
    for (var cat in SampleData.categories) {
      await db.insert('categories', cat.toMap());
    }

    // Pre-populate sample listings
    for (var item in SampleData.sampleListings) {
      await db.insert('listings', item.toMap());
    }

    // Pre-populate genesis block for blockchain demonstration
    final genesisTimestamp = DateTime.now().subtract(const Duration(days: 3));
    final genesisHash = BlockModel.calculateHash(
      index: 0,
      timestamp: genesisTimestamp,
      listingId: 'genesis-000',
      itemTitle: 'Genesis Block - jadiGuna Network Init',
      previousStatus: 'None',
      newStatus: 'Initialized',
      actorName: 'System',
      notes: 'Initial block for jadiGuna immutable item provenance ledger',
      previousHash: '0000000000000000000000000000000000000000000000000000000000000000',
    );

    final genesisBlock = BlockModel(
      index: 0,
      timestamp: genesisTimestamp,
      listingId: 'genesis-000',
      itemTitle: 'Genesis Block - jadiGuna Network Init',
      previousStatus: 'None',
      newStatus: 'Initialized',
      actorName: 'System',
      notes: 'Initial block for jadiGuna immutable item provenance ledger',
      previousHash: '0000000000000000000000000000000000000000000000000000000000000000',
      hash: genesisHash,
    );
    await db.insert('blockchain_records', genesisBlock.toMap());

    // Add initial item creation blocks for sample items
    String lastHash = genesisHash;
    for (int i = 0; i < 3; i++) {
      final sample = SampleData.sampleListings[i];
      final blockTime = sample.createdAt;
      final curHash = BlockModel.calculateHash(
        index: i + 1,
        timestamp: blockTime,
        listingId: sample.id,
        itemTitle: sample.title,
        previousStatus: 'Draft',
        newStatus: 'Tersedia',
        actorName: sample.sellerName,
        notes: 'Iklan diterbitkan dan diverifikasi di sistem',
        previousHash: lastHash,
      );
      final block = BlockModel(
        index: i + 1,
        timestamp: blockTime,
        listingId: sample.id,
        itemTitle: sample.title,
        previousStatus: 'Draft',
        newStatus: 'Tersedia',
        actorName: sample.sellerName,
        notes: 'Iklan diterbitkan dan diverifikasi di sistem',
        previousHash: lastHash,
        hash: curHash,
      );
      await db.insert('blockchain_records', block.toMap());
      lastHash = curHash;
    }
  }

  // --- Listings Operations ---
  Future<List<ListingModel>> getListings({
    String? categorySlug,
    String? searchQuery,
    bool onlyFree = false,
    String? condition,
    int? maxPrice,
    String? status,
    String? userId,
    String? currentUserId,
  }) async {
    final db = await database;
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (userId != null && userId.isNotEmpty) {
      whereClauses.add('user_id = ?');
      whereArgs.add(userId);
    }

    if (categorySlug != null && categorySlug != 'semua' && categorySlug.isNotEmpty) {
      whereClauses.add('(category_id = ? OR category_name LIKE ?)');
      whereArgs.add(categorySlug);
      whereArgs.add('%$categorySlug%');
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereClauses.add('(title LIKE ? OR description LIKE ? OR location_name LIKE ?)');
      final term = '%${searchQuery.trim()}%';
      whereArgs.addAll([term, term, term]);
    }

    if (onlyFree) {
      whereClauses.add('(price IS NULL OR price = 0)');
    } else if (maxPrice != null && maxPrice > 0) {
      whereClauses.add('price <= ?');
      whereArgs.add(maxPrice);
    }

    if (condition != null && condition.isNotEmpty && condition != 'Semua') {
      whereClauses.add('condition = ?');
      whereArgs.add(condition);
    }

    if (status != null && status.isNotEmpty) {
      whereClauses.add('status = ?');
      whereArgs.add(status);
    }

    final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final maps = await db.query(
      'listings',
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'created_at DESC',
    );

    // Get favorite IDs for current user to mark isFavorite
    Set<String> favListingIds = {};
    if (currentUserId != null && currentUserId.isNotEmpty) {
      final favRows = await db.query(
        'favorites',
        where: 'user_id = ?',
        whereArgs: [currentUserId],
      );
      favListingIds = favRows.map((e) => e['listing_id'] as String).toSet();
    }

    return maps.map((m) {
      final id = m['id'] as String;
      return ListingModel.fromMap(m, isFav: favListingIds.contains(id));
    }).toList();
  }

  Future<ListingModel?> getListingById(String id, {String? currentUserId}) async {
    final db = await database;
    final maps = await db.query('listings', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;

    bool isFav = false;
    if (currentUserId != null && currentUserId.isNotEmpty) {
      final favRows = await db.query(
        'favorites',
        where: 'listing_id = ? AND user_id = ?',
        whereArgs: [id, currentUserId],
      );
      isFav = favRows.isNotEmpty;
    }

    return ListingModel.fromMap(maps.first, isFav: isFav);
  }

  Future<int> insertListing(ListingModel listing) async {
    final db = await database;
    return await db.insert('listings', listing.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateListing(ListingModel listing) async {
    final db = await database;
    return await db.update(
      'listings',
      listing.toMap(),
      where: 'id = ?',
      whereArgs: [listing.id],
    );
  }

  Future<int> updateListingStatus(String id, String newStatus) async {
    final db = await database;
    return await db.update(
      'listings',
      {
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteListing(String id) async {
    final db = await database;
    return await db.delete('listings', where: 'id = ?', whereArgs: [id]);
  }

  // --- Favorites Operations ---
  Future<bool> isFavorite(String userId, String listingId) async {
    final db = await database;
    final res = await db.query(
      'favorites',
      where: 'user_id = ? AND listing_id = ?',
      whereArgs: [userId, listingId],
    );
    return res.isNotEmpty;
  }

  Future<void> toggleFavorite(String userId, String listingId) async {
    final db = await database;
    final exists = await isFavorite(userId, listingId);
    if (exists) {
      await db.delete(
        'favorites',
        where: 'user_id = ? AND listing_id = ?',
        whereArgs: [userId, listingId],
      );
    } else {
      await db.insert('favorites', {
        'user_id': userId,
        'listing_id': listingId,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<List<ListingModel>> getFavorites(String userId) async {
    final db = await database;
    final favRows = await db.query(
      'favorites',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    final listingIds = favRows.map((e) => e['listing_id'] as String).toList();
    if (listingIds.isEmpty) return [];

    final placeholders = List.filled(listingIds.length, '?').join(',');
    final maps = await db.query(
      'listings',
      where: 'id IN ($placeholders)',
      whereArgs: listingIds,
    );

    return maps.map((m) => ListingModel.fromMap(m, isFav: true)).toList();
  }

  // --- Conversations & Messages ---
  Future<List<ConversationModel>> getConversations({String? userId}) async {
    final db = await database;
    if (userId != null && userId.isNotEmpty) {
      final maps = await db.query(
        'conversations',
        where: '(buyer_id = ? OR seller_id = ?) AND id != ?',
        whereArgs: [userId, userId, 'conv-001'],
        orderBy: 'last_message_time DESC',
      );
      return maps.map((m) => ConversationModel.fromMap(m)).toList();
    }

    final maps = await db.query(
      'conversations',
      where: 'id != ? AND buyer_id != ?',
      whereArgs: ['conv-001', 'current-user-1'],
      orderBy: 'last_message_time DESC',
    );
    return maps.map((m) => ConversationModel.fromMap(m)).toList();
  }

  Future<ConversationModel?> getConversationById(String convId) async {
    final db = await database;
    final maps = await db.query('conversations', where: 'id = ?', whereArgs: [convId]);
    if (maps.isEmpty) return null;
    return ConversationModel.fromMap(maps.first);
  }

  Future<void> saveConversation(ConversationModel conv) async {
    final db = await database;
    await db.insert('conversations', conv.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<MessageModel>> getMessages(String conversationId) async {
    final db = await database;
    final maps = await db.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'created_at ASC',
    );
    return maps.map((m) => MessageModel.fromMap(m)).toList();
  }

  Future<void> insertMessage(MessageModel msg) async {
    final db = await database;
    await db.insert('messages', msg.toMap());

    // Update conversation last message
    await db.update(
      'conversations',
      {
        'last_message': msg.message,
        'last_message_time': msg.createdAt.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [msg.conversationId],
    );
  }

  // --- Blockchain Records ---
  Future<List<BlockModel>> getBlockchainRecords() async {
    final db = await database;
    final maps = await db.query('blockchain_records', orderBy: 'block_index ASC');
    return maps.map((m) => BlockModel.fromMap(m)).toList();
  }

  Future<BlockModel?> getLatestBlock() async {
    final db = await database;
    final maps = await db.query(
      'blockchain_records',
      orderBy: 'block_index DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return BlockModel.fromMap(maps.first);
  }

  Future<void> insertBlock(BlockModel block) async {
    final db = await database;
    await db.insert('blockchain_records', block.toMap());
  }

  Future<void> tamperBlockForTesting(int index, String tamperedStatus) async {
    final db = await database;
    await db.update(
      'blockchain_records',
      {'new_status': tamperedStatus},
      where: 'block_index = ?',
      whereArgs: [index],
    );
  }

  Future<void> resetBlockchain() async {
    final db = await database;
    await db.delete('blockchain_records');
    // Re-create genesis
    final genesisTimestamp = DateTime.now().subtract(const Duration(days: 3));
    final genesisHash = BlockModel.calculateHash(
      index: 0,
      timestamp: genesisTimestamp,
      listingId: 'genesis-000',
      itemTitle: 'Genesis Block - jadiGuna Network Init',
      previousStatus: 'None',
      newStatus: 'Initialized',
      actorName: 'System',
      notes: 'Initial block for jadiGuna immutable item provenance ledger',
      previousHash: '0000000000000000000000000000000000000000000000000000000000000000',
    );
    final genesisBlock = BlockModel(
      index: 0,
      timestamp: genesisTimestamp,
      listingId: 'genesis-000',
      itemTitle: 'Genesis Block - jadiGuna Network Init',
      previousStatus: 'None',
      newStatus: 'Initialized',
      actorName: 'System',
      notes: 'Initial block for jadiGuna immutable item provenance ledger',
      previousHash: '0000000000000000000000000000000000000000000000000000000000000000',
      hash: genesisHash,
    );
    await db.insert('blockchain_records', genesisBlock.toMap());
  }

  // --- Feedback ---
  Future<void> insertFeedback(FeedbackModel feedback) async {
    final db = await database;
    await db.insert('feedback', feedback.toMap());
  }

  Future<List<FeedbackModel>> getFeedbackList() async {
    final db = await database;
    final maps = await db.query('feedback', orderBy: 'created_at DESC');
    return maps.map((m) => FeedbackModel.fromMap(m)).toList();
  }

  // --- Profiles Cache ---
  Future<UserModel?> getProfile(String id) async {
    final db = await database;
    final maps = await db.query('profiles', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  Future<void> saveProfile(UserModel user) async {
    final db = await database;
    await db.insert('profiles', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
