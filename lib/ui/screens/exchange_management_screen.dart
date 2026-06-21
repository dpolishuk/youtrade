import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/auth/exchange_credentials.dart';
import '../../domain/entities/venue.dart';
import '../../presentation/exchange/exchange_credentials_notifier.dart';
import '../../presentation/exchange/exchange_credentials_provider.dart';
import '../../presentation/exchange/exchange_credentials_state.dart';
import '../../presentation/theme/theme_extensions.dart';
import 'exchange_detail_edit_screen.dart';

class ExchangeManagementScreen extends ConsumerStatefulWidget {
  const ExchangeManagementScreen({super.key});

  @override
  ConsumerState<ExchangeManagementScreen> createState() =>
      _ExchangeManagementScreenState();
}

class _ExchangeManagementScreenState
    extends ConsumerState<ExchangeManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(exchangeCredentialsNotifierProvider.notifier).loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorTheme>()!;
    final state = ref.watch(exchangeCredentialsNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Exchange Management')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Connected exchanges',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.subtleText,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: switch (state) {
                  ExchangeCredentialsLoading() => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  ExchangeCredentialsError() => _buildError(
                    state,
                    theme,
                    colors,
                  ),
                  ExchangeCredentialsLoaded() => _buildList(
                    state.credentials,
                    theme,
                    colors,
                  ),
                  ExchangeCredentialsTesting() ||
                  ExchangeCredentialsTestSuccess() ||
                  ExchangeCredentialsTestFailure() => _buildList(
                    ref
                        .read(exchangeCredentialsNotifierProvider.notifier)
                        .credentials,
                    theme,
                    colors,
                  ),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(
    ExchangeCredentialsError state,
    ThemeData theme,
    AppColorTheme colors,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: colors.bearish, size: 48),
          const SizedBox(height: 16),
          Text('Failed to load exchanges', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            state.failure.message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.subtleText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.read(exchangeCredentialsNotifierProvider.notifier).loadAll();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    List<ExchangeCredentials> credentials,
    ThemeData theme,
    AppColorTheme colors,
  ) {
    return ListView.separated(
      itemCount: Venue.values.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final venue = Venue.values[index];
        final credential = credentials
            .where((c) => c.venue == venue)
            .firstOrNull;
        final isConnected = credential != null && credential.isEnabled;

        return _VenueTile(
          venue: venue,
          isConnected: isConnected,
          credential: credential,
          onTap: () => _openDetail(venue),
        );
      },
    );
  }

  void _openDetail(Venue venue) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ExchangeDetailEditScreen(venue: venue),
      ),
    );
  }
}

class _VenueTile extends StatelessWidget {
  const _VenueTile({
    required this.venue,
    required this.isConnected,
    required this.credential,
    required this.onTap,
  });

  final Venue venue;
  final bool isConnected;
  final ExchangeCredentials? credential;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<AppColorTheme>()!;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              _VenueAvatar(venue: venue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venue.displayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isConnected ? 'Read-only API connected' : 'Not connected',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.subtleText,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isConnected ? colors.bullish : colors.subtleText,
                      boxShadow: isConnected
                          ? [
                              BoxShadow(
                                color: colors.bullish.withValues(alpha: 0.4),
                                blurRadius: 6,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isConnected ? 'Connected' : 'Disconnected',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isConnected ? colors.bullish : colors.subtleText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: colors.subtleText, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VenueAvatar extends StatelessWidget {
  const _VenueAvatar({required this.venue});

  final Venue venue;

  Color get _tint {
    return switch (venue) {
      Venue.binance => const Color(0xFFF0B90B).withValues(alpha: 0.14),
      Venue.bybit => const Color(0xFFF7A600).withValues(alpha: 0.14),
      Venue.okx => const Color(0xFF2F6BFF).withValues(alpha: 0.14),
      Venue.coinbase => const Color(0xFF0052FF).withValues(alpha: 0.14),
    };
  }

  Color get _color {
    return switch (venue) {
      Venue.binance => const Color(0xFFF0B90B),
      Venue.bybit => const Color(0xFFF7A600),
      Venue.okx => const Color(0xFF2F6BFF),
      Venue.coinbase => const Color(0xFF0052FF),
    };
  }

  String get _initial {
    return switch (venue) {
      Venue.binance => 'B',
      Venue.bybit => 'Y',
      Venue.okx => 'O',
      Venue.coinbase => 'C',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _tint,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        _initial,
        style: theme.textTheme.titleMedium?.copyWith(
          color: _color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
