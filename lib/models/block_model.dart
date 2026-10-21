import 'dart:convert';
import 'package:crypto/crypto.dart';

class BlockModel {
  final int index;
  final DateTime timestamp;
  final String listingId;
  final String itemTitle;
  final String previousStatus;
  final String newStatus;
  final String actorName;
  final String notes;
  final String previousHash;
  String hash;

  BlockModel({
    required this.index,
    required this.timestamp,
    required this.listingId,
    required this.itemTitle,
    required this.previousStatus,
    required this.newStatus,
    required this.actorName,
    this.notes = '',
    required this.previousHash,
    required this.hash,
  });

  /// Generate SHA-256 hash based on block contents
  static String calculateHash({
    required int index,
    required DateTime timestamp,
    required String listingId,
    required String itemTitle,
    required String previousStatus,
    required String newStatus,
    required String actorName,
    required String notes,
    required String previousHash,
  }) {
    final payload = '$index'
        '${timestamp.toIso8601String()}'
        '$listingId'
        '$itemTitle'
        '$previousStatus'
        '$newStatus'
        '$actorName'
        '$notes'
        '$previousHash';
    return sha256.convert(utf8.encode(payload)).toString();
  }

  /// Verify if the stored hash matches recalculated hash
  bool get isValid {
    final calculated = calculateHash(
      index: index,
      timestamp: timestamp,
      listingId: listingId,
      itemTitle: itemTitle,
      previousStatus: previousStatus,
      newStatus: newStatus,
      actorName: actorName,
      notes: notes,
      previousHash: previousHash,
    );
    return calculated == hash;
  }

  Map<String, dynamic> toMap() {
    return {
      'block_index': index,
      'timestamp': timestamp.toIso8601String(),
      'listing_id': listingId,
      'item_title': itemTitle,
      'previous_status': previousStatus,
      'new_status': newStatus,
      'actor_name': actorName,
      'notes': notes,
      'previous_hash': previousHash,
      'hash': hash,
    };
  }

  factory BlockModel.fromMap(Map<String, dynamic> map) {
    return BlockModel(
      index: map['block_index'] as int,
      timestamp: DateTime.parse(map['timestamp'].toString()),
      listingId: map['listing_id'] as String,
      itemTitle: map['item_title'] as String? ?? 'Barang',
      previousStatus: map['previous_status'] as String? ?? '-',
      newStatus: map['new_status'] as String,
      actorName: map['actor_name'] as String? ?? 'Sistem',
      notes: map['notes'] as String? ?? '',
      previousHash: map['previous_hash'] as String,
      hash: map['hash'] as String,
    );
  }
}
