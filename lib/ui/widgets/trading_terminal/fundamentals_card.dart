import 'package:flutter/material.dart';

import '../../../domain/entities/candle.dart';
import '../../../domain/entities/symbol.dart';
import '../../../domain/entities/ticker.dart';
import '../../../presentation/theme/app_theme.dart';
import '../../../presentation/theme/theme_extensions.dart';

class FundamentalsCard extends StatelessWidget {
  const FundamentalsCard({
    required this.symbol,
    required this.ticker,
    required this.candles,
    super.key,
  });

  final TradingSymbol symbol;
  final Ticker? ticker;
  final List<Candle> candles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>()!;
    final fund = _fundamentals(
      symbol.rawSymbol,
      ticker?.lastPrice ?? 0,
      appColors,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < fund.tags.length; i++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i == 0 ? 6 : 0),
                  child: _TagCard(tag: fund.tags[i]),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: appColors.borderSubtle,
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 3.2,
            children: [
              for (var i = 0; i < fund.stats.length; i++)
                Container(
                  margin: EdgeInsets.only(
                    left: i % 2 == 0 ? 0 : 1,
                    top: i < 2 ? 0 : 1,
                  ),
                  color: theme.cardColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        fund.stats[i].label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: appColors.tertiaryText,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        fund.stats[i].value,
                        style: AppTheme.mono(
                          color: appColors.foreground,
                          fontSize: 12,
                        ).copyWith(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'About',
          style: AppTheme.mono(
            color: appColors.tertiaryText,
            fontSize: 9,
          ).copyWith(letterSpacing: 0.1),
        ),
        const SizedBox(height: 7),
        Text(
          fund.about,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: appColors.subtleText,
            fontSize: 12.5,
            height: 1.55,
          ),
        ),
      ],
    );
  }

  _Fundamentals _fundamentals(
    String rawSymbol,
    double last,
    AppColorTheme appColors,
  ) {
    final t = appColors;
    if (rawSymbol == 'AAPL') {
      return _Fundamentals(
        about:
            'Apple designs and sells consumer electronics, software and services worldwide. Mega-cap equity, NASDAQ listed.',
        tags: [
          _Tag(label: 'Analyst', value: 'Buy', valueColor: t.bullish),
          _Tag(label: 'Target', value: '\$258', valueColor: t.foreground),
        ],
        stats: const [
          _Stat(label: 'Market cap', value: '\$3.42T'),
          _Stat(label: 'P/E (TTM)', value: '34.8'),
          _Stat(label: 'EPS', value: '\$6.43'),
          _Stat(label: 'Div yield', value: '0.44%'),
          _Stat(label: '52w range', value: '164 – 237'),
          _Stat(label: 'Beta', value: '1.18'),
          _Stat(label: 'Avg vol', value: '54.2M'),
          _Stat(label: 'Next earnings', value: 'Apr 30'),
        ],
      );
    }
    if (rawSymbol == 'GC=F') {
      return _Fundamentals(
        about:
            'COMEX gold futures (Dec). Safe-haven commodity, USD-denominated, 100 troy oz per contract.',
        tags: [
          _Tag(label: 'Trend', value: 'Bullish', valueColor: t.bullish),
          _Tag(label: 'COT net', value: 'Long', valueColor: t.bullish),
        ],
        stats: const [
          _Stat(label: 'Contract', value: '100 oz'),
          _Stat(label: 'Open interest', value: '418k'),
          _Stat(label: 'Settlement', value: 'Physical'),
          _Stat(label: 'Margin', value: '\$11,150'),
          _Stat(label: '52w range', value: '2,290 – 2,790'),
          _Stat(label: 'Roll date', value: 'Nov 26'),
          _Stat(label: 'Basis', value: '+4.20'),
          _Stat(label: 'Real yield', value: '1.92%'),
        ],
      );
    }
    final isBtc = rawSymbol == 'BTCUSDT';
    return _Fundamentals(
      about:
          '${isBtc
              ? 'Bitcoin'
              : rawSymbol == 'ETHUSDT'
              ? 'Ethereum'
              : 'Solana'} perpetual swap. Funding settles every 8h; no expiry. Index across Binance, Bybit, OKX, Coinbase.',
      tags: [
        _Tag(label: 'Sentiment', value: 'Greed 72', valueColor: t.bullish),
        _Tag(label: 'Volatility', value: 'Med', valueColor: t.foreground),
      ],
      stats: [
        _Stat(
          label: 'Market cap',
          value: isBtc
              ? '\$1.14T'
              : rawSymbol == 'ETHUSDT'
              ? '\$356B'
              : '\$78B',
        ),
        _Stat(
          label: '24h volume',
          value: isBtc
              ? '\$38.2B'
              : rawSymbol == 'ETHUSDT'
              ? '\$14.6B'
              : '\$5.1B',
        ),
        const _Stat(label: 'Funding 8h', value: '+0.0102%'),
        _Stat(
          label: 'Open interest',
          value: isBtc
              ? '\$18.4B'
              : rawSymbol == 'ETHUSDT'
              ? '\$6.1B'
              : '\$1.4B',
        ),
        _Stat(
          label: 'Circ. supply',
          value: isBtc
              ? '19.8M'
              : rawSymbol == 'ETHUSDT'
              ? '120.4M'
              : '486.6M',
        ),
        _Stat(label: 'Dominance', value: isBtc ? '54.2%' : '17.1%'),
        const _Stat(label: 'Long/Short', value: '1.34'),
        const _Stat(label: 'Liq. 24h', value: '\$142M'),
      ],
    );
  }
}

class _Fundamentals {
  const _Fundamentals({
    required this.about,
    required this.tags,
    required this.stats,
  });

  final String about;
  final List<_Tag> tags;
  final List<_Stat> stats;
}

class _Tag {
  const _Tag({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;
}

class _Stat {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;
}

class _TagCard extends StatelessWidget {
  const _TagCard({required this.tag});

  final _Tag tag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>()!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: appColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tag.label,
            style: AppTheme.mono(
              color: appColors.tertiaryText,
              fontSize: 9,
            ).copyWith(letterSpacing: 0.07),
          ),
          const SizedBox(height: 4),
          Text(
            tag.value,
            style: AppTheme.mono(
              color: tag.valueColor ?? appColors.foreground,
              fontSize: 15,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
