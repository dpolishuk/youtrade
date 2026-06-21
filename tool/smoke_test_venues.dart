import 'dart:async';
import 'dart:developer';

import 'package:youtrade/data/datasources/remote/coinbase/coinbase_rest_client.dart';
import 'package:youtrade/data/datasources/remote/okx/okx_rest_client.dart';
import 'package:youtrade/domain/entities/symbol.dart';
import 'package:youtrade/domain/entities/timeframe.dart';
import 'package:youtrade/domain/entities/venue.dart';

Future<void> main() async {
  await _testOKX();
  await _testCoinbase();
  log('Smoke tests completed.');
}

Future<void> _testOKX() async {
  log('--- OKX smoke test ---');
  final client = OKXRestClient();
  final symbol = TradingSymbol(
    base: 'BTC',
    quote: 'USDT',
    venue: Venue.okx,
    rawSymbol: 'BTC-USDT',
  );

  final ticker = await client.fetchTicker(symbol);
  log('Ticker: $ticker');

  final candles = await client.fetchCandles(symbol, Timeframe.h1, limit: 2);
  log('Candles: $candles');

  final orderBook = await client.fetchOrderBook(symbol, depth: 2);
  log('Order book: $orderBook');

  final trades = await client.fetchTrades(symbol, limit: 2);
  log('Trades: $trades');
}

Future<void> _testCoinbase() async {
  log('--- Coinbase smoke test ---');
  final client = CoinbaseRestClient();
  final symbol = TradingSymbol(
    base: 'BTC',
    quote: 'USD',
    venue: Venue.coinbase,
    rawSymbol: 'BTC-USD',
  );

  final ticker = await client.fetchTicker(symbol);
  log('Ticker: $ticker');

  final candles = await client.fetchCandles(symbol, Timeframe.h1, limit: 2);
  log('Candles: $candles');

  final orderBook = await client.fetchOrderBook(symbol);
  log('Order book: $orderBook');

  final trades = await client.fetchTrades(symbol, limit: 2);
  log('Trades: $trades');
}
