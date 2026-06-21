import 'package:drift/drift.dart';

class CachedTickers extends Table {
  TextColumn get symbolId => text()();
  RealColumn get lastPrice => real()();
  RealColumn get bid => real()();
  RealColumn get ask => real()();
  RealColumn get change24h => real()();
  RealColumn get change24hPercent => real()();
  RealColumn get volume => real()();
  DateTimeColumn get timestamp => dateTime()();

  @override
  Set<Column> get primaryKey => {symbolId};
}

class CachedCandles extends Table {
  TextColumn get symbolId => text()();
  TextColumn get timeframeCode => text()();
  RealColumn get open => real()();
  RealColumn get high => real()();
  RealColumn get low => real()();
  RealColumn get close => real()();
  RealColumn get volume => real()();
  DateTimeColumn get timestamp => dateTime()();

  @override
  Set<Column> get primaryKey => {symbolId, timeframeCode, timestamp};
}

class CachedOrderBooks extends Table {
  TextColumn get symbolId => text()();
  TextColumn get bidsJson => text()();
  TextColumn get asksJson => text()();
  DateTimeColumn get timestamp => dateTime()();

  @override
  Set<Column> get primaryKey => {symbolId};
}

class CachedTrades extends Table {
  TextColumn get symbolId => text()();
  TextColumn get tradesJson => text()();
  DateTimeColumn get timestamp => dateTime()();

  @override
  Set<Column> get primaryKey => {symbolId};
}
