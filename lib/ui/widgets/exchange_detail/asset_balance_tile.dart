import 'package:flutter/material.dart';

import '../../../presentation/theme/theme_extensions.dart';

class AssetBalance {
  const AssetBalance({
    required this.symbol,
    required this.glyph,
    required this.value,
    required this.share,
    required this.shareColor,
  });

  final String symbol;
  final String glyph;
  final String value;
  final double share;
  final Color shareColor;
}

class AssetBalanceTile extends StatelessWidget {
  const AssetBalanceTile({required this.asset, super.key});

  final AssetBalance asset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorTheme>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor),
            ),
            alignment: Alignment.center,
            child: Text(
              asset.glyph,
              style: theme.textTheme.titleSmall?.copyWith(
                fontFamily: 'Space Grotesk',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: theme.colorScheme.onSurface,
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
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      asset.value,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontFamily: 'Geist Mono',
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
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
                          color: appColors?.surfaceGlass,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: asset.share.clamp(0, 1),
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
                        '${asset.share.toStringAsFixed(0)}%',
                        textAlign: TextAlign.right,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontFamily: 'Geist Mono',
                          color: theme.colorScheme.onSurfaceVariant,
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
