import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/symbol.dart';
import '../../domain/entities/venue.dart';

final selectedSymbolProvider = StateProvider<TradingSymbol>(
  (ref) => TradingSymbol(
    base: 'BTC',
    quote: 'USDT',
    venue: Venue.bybit,
    rawSymbol: 'BTCUSDT',
  ),
);
