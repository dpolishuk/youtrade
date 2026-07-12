final class WalletCoin {
  const WalletCoin({
    required this.coin,
    required this.walletBalance,
    required this.equity,
  });

  final String coin;
  final double walletBalance;
  final double equity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletCoin &&
          coin == other.coin &&
          walletBalance == other.walletBalance &&
          equity == other.equity;

  @override
  int get hashCode => Object.hash(coin, walletBalance, equity);

  @override
  String toString() =>
      'WalletCoin($coin: balance=$walletBalance, equity=$equity)';
}

final class WalletBalance {
  const WalletBalance({
    required this.accountType,
    required this.totalEquity,
    required this.coins,
  });

  final String accountType;
  final double totalEquity;
  final List<WalletCoin> coins;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletBalance &&
          accountType == other.accountType &&
          totalEquity == other.totalEquity &&
          coins == other.coins;

  @override
  int get hashCode => Object.hash(accountType, totalEquity, coins);

  @override
  String toString() =>
      'WalletBalance($accountType: equity=$totalEquity, ${coins.length} coins)';
}
