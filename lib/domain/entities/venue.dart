enum Venue {
  binance('Binance', 'binance'),
  bybit('Bybit', 'bybit'),
  okx('OKX', 'okx'),
  coinbase('Coinbase', 'coinbase');

  const Venue(this.displayName, this.id);

  final String displayName;
  final String id;
}
