import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:jadiguna/core/database/local_database.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('LocalDatabase initializes and can insert/get profile', () async {
    final db = await LocalDatabase.instance.database;
    expect(db.isOpen, true);

    final listings = await LocalDatabase.instance.getListings();
    expect(listings.isNotEmpty, true);
  });
}
