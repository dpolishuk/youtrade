import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/mock/deterministic_market_data_store.dart';
import '../../domain/entities/venue.dart';
import '../../domain/entities/exchange_detail_snapshot.dart';
import '../theme/theme_extensions.dart';
import '../theme/theme_provider.dart';

/// Deterministic snapshot of data for the Exchange Detail screen.
final exchangeDetailProvider = Provider.family<ExchangeDetailSnapshot, Venue>((
  ref,
  venue,
) {
  final accent = ref.watch(appThemeProvider).extension<AppColorTheme>()!.accent;
  return DeterministicMarketDataStore.exchangeDetailFor(venue, accent: accent);
});
