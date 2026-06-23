enum Timeframe {
  m1('1m', 60),
  m5('5m', 300),
  m15('15m', 900),
  h1('1H', 3600),
  h4('4H', 14400),
  d1('1D', 86400),
  w1('1W', 604800);

  const Timeframe(this.code, this.seconds);

  final String code;
  final int seconds;
}
