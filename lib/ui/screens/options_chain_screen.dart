import 'package:flutter/material.dart';

import '../../data/datasources/mock/deterministic_market_data_store.dart';
import '../../domain/entities/options_chain_strike.dart';
import '../../presentation/theme/theme_extensions.dart';
import '../widgets/options_chain/chain_column_headers.dart';
import '../widgets/options_chain/expiry_selector.dart';
import '../widgets/options_chain/options_header.dart';
import '../widgets/options_chain/strike_row.dart';

class OptionsChainScreen extends StatefulWidget {
  const OptionsChainScreen({this.symbol, super.key});

  final String? symbol;

  @override
  State<OptionsChainScreen> createState() => _OptionsChainScreenState();
}

class _OptionsChainScreenState extends State<OptionsChainScreen> {
  static final _expiries = DeterministicMarketDataStore.btcOptionExpiries;

  List<OptionChainStrike> get _rows =>
      DeterministicMarketDataStore.btcOptionsChain;

  int _selectedExpiryIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>()!;
    final symbol = _displaySymbol(widget.symbol);
    final spot = DeterministicMarketDataStore.btcLastPrice;
    final atmStrike = DeterministicMarketDataStore.btcOptionsAtmStrike;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OptionsHeader(symbol: symbol, spot: spot),
                const SizedBox(height: 12),
                ExpirySelector(
                  expiries: _expiries,
                  selectedIndex: _selectedExpiryIndex,
                  onSelected: (index) {
                    setState(() {
                      _selectedExpiryIndex = index;
                    });
                  },
                ),
                const SizedBox(height: 12),
                const ChainColumnHeaders(),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: appColors.borderSubtle),
                  ),
                  child: _rows.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              'No strikes available',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: appColors.subtleText,
                              ),
                            ),
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Column(
                            children: [
                              for (var i = 0; i < _rows.length; i++)
                                StrikeRow(
                                  row: _rows[i],
                                  isLast: i == _rows.length - 1,
                                ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 10),
                Text(
                  'ATM strike ${_formatPrice(atmStrike)} · highlighted',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 9,
                    color: appColors.tertiaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _displaySymbol(String? symbol) {
    final raw = (symbol ?? 'BTC').toUpperCase();
    return raw.replaceAll('USDT', '').replaceAll(RegExp(r'=F$'), '');
  }
}

String _formatPrice(double price) {
  final formatted = price.toStringAsFixed(0);
  return formatted.replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
}
