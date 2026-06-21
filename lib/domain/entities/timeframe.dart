enum Timeframe {
  m1('1m', 60),
  m5('5m', 300),
  m15('15m', 900),
  m30('30m', 1800),
  h1('1h', 3600),
  h4('4h', 14400),
  d1('1d', 86400);

  const Timeframe(this.code, this.seconds);

  final String code;
  final int seconds;
}
