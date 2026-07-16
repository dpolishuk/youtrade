import 'package:flutter/material.dart';

import '../../../domain/entities/exchange_balance.dart';
import '../../../presentation/theme/theme_extensions.dart';

class AssetBalanceTile extends StatelessWidget {
  const AssetBalanceTile({required this.asset, super.key});

  final ExchangeBalance asset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>();
    final fg = theme.colorScheme.onSurface;
    final fg3 = appColors?.tertiaryText ?? theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color:
                  appColors?.chip ?? theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: appColors?.borderSubtle ?? theme.dividerColor,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              asset.glyph,
              style: theme.textTheme.titleSmall?.copyWith(
                fontFamily: 'Space Grotesk',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: fg,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      asset.symbol,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: fg,
                      ),
                    ),
                    Text(
                      asset.valueFormatted,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontFamily: 'JetBrains Mono',
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: fg,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color:
                              appColors?.chip ??
                              theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: asset.sharePercent / 100,
                          child: Container(
                            decoration: BoxDecoration(
                              color: asset.shareColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 28,
                      child: Text(
                        '${asset.sharePercent}%',
                        textAlign: TextAlign.right,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontFamily: 'JetBrains Mono',
                          color: fg3,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
