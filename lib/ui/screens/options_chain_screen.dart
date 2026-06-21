import 'package:flutter/material.dart';

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
  static const _expiries = <String>['26 JUN', '25 JUL', '29 AUG', '26 SEP'];

  int _selectedExpiryIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>()!;
    final spot = 68432.0;
    final atmStrike = _atmStrike(spot);
    final rows = _buildRows(spot, atmStrike, appColors);

    return Scaffold(
      appBar: AppBar(title: const Text('Options')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OptionsHeader(spot: spot),
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
                  child: rows.isEmpty
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
                              for (var i = 0; i < rows.length; i++)
                                StrikeRow(
                                  row: rows[i],
                                  isLast: i == rows.length - 1,
                                ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 10),
                Text(
                  'ATM strike ${_formatPrice(atmStrike)} · highlighted',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: appColors.subtleText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _atmStrike(double spot) {
    return (spot / 2000).round() * 2000;
  }

  List<OptionStrikeRow> _buildRows(
    double spot,
    double atmStrike,
    AppColorTheme appColors,
  ) {
    final strikes = <double>[];
    for (var i = -4; i <= 4; i++) {
      strikes.add(atmStrike + i * 2000);
    }

    return strikes.map((strike) {
      final itmCall = spot > strike;
      final distance = (spot - strike) / spot;
      final callDelta = (0.5 + distance * 4).clamp(0.02, 0.98);
      final putDelta = callDelta - 1;
      final iv = 48 + (strike % 7) * 3;
      final callMark =
          ((spot - strike).clamp(0.0, double.infinity) / spot +
                  0.02 +
                  (strike % 13) * 0.001)
              .clamp(0.001, double.infinity);
      final putMark =
          ((strike - spot).clamp(0.0, double.infinity) / spot +
                  0.02 +
                  (strike % 11) * 0.001)
              .clamp(0.001, double.infinity);
      final isAtm = (strike - atmStrike).abs() < 1;

      return OptionStrikeRow(
        strike: strike,
        isAtm: isAtm,
        callIv: iv.toDouble(),
        callDelta: callDelta,
        callMark: callMark,
        callColor: itmCall ? appColors.bullish : appColors.subtleText,
        putIv: iv + 4,
        putDelta: putDelta,
        putMark: putMark,
        putColor: itmCall ? appColors.subtleText : appColors.bearish,
      );
    }).toList();
  }
}

String _formatPrice(double price) {
  final formatted = price.toStringAsFixed(0);
  return formatted.replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
}
