final class AccountPosition {
  const AccountPosition({
    required this.symbol,
    required this.side,
    required this.size,
    required this.unrealisedPnl,
  });

  final String symbol;
  final String side;
  final double size;
  final double unrealisedPnl;

  bool get isLong => side == 'Buy';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountPosition &&
          symbol == other.symbol &&
          side == other.side &&
          size == other.size &&
          unrealisedPnl == other.unrealisedPnl;

  @override
  int get hashCode => Object.hash(symbol, side, size, unrealisedPnl);

  @override
  String toString() =>
      'AccountPosition($symbol $side: size=$size, pnl=$unrealisedPnl)';
}
