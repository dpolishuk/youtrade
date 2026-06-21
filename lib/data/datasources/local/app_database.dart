import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'market_cache_tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [CachedTickers, CachedCandles, CachedOrderBooks, CachedTrades],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase({NativeDatabase? database})
    : super(database ?? _openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'youtrade.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
