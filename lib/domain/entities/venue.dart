enum Venue {
  binance('Binance', 'binance', 'BIN'),
  bybit('Bybit', 'bybit', 'BYB'),
  okx('OKX', 'okx', 'OKX'),
  coinbase('Coinbase', 'coinbase', 'CB'),
  unknown('Unknown', 'unknown', '—');

  const Venue(this.displayName, this.id, this.shortCode);

  final String displayName;
  final String id;
  final String shortCode;
}
