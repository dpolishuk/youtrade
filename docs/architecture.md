# YouTrade Architecture

This document describes the high-level and detailed software architecture of the YouTrade Flutter application. It complements [`docs/screens.md`](./screens.md) and the project [`AGENTS.md`](../AGENTS.md).

## Goals

- Build a multi-venue trading terminal that can graduate from mock-first prototype to production.
- Keep UI/UX faithful to the `/mockups/` interactive prototype.
- Use public REST and WebSocket market data from Binance, Bybit, OKX, and Coinbase.
- Support SOLID principles, layered/clean architecture, and Riverpod state management.
- First build is public-data only; no exchange API secrets are stored or transmitted.

## Architecture Layers

```
lib/
├── main.dart                   # Entry point + MaterialApp.router + provider container
├── core/                       # Result, failures, extensions, theme tokens
├── domain/                     # Entities, source contracts, repository interfaces, registry
├── data/                       # REST/WebSocket clients, cache, mock store, repositories
├── presentation/               # Riverpod providers and notifiers
└── ui/                         # Screens, widgets, charts, routing
```

### Layer Rules

- **Domain** knows nothing about Flutter, HTTP, WebSocket, or JSON.
- **Data** knows about external APIs and maps them to domain entities.
- **Presentation** exposes state via Riverpod providers and notifiers.
- **UI** only renders state and forwards user events.

## SOLID Mapping

| Principle | How we apply it |
|---|---|
| Single Responsibility | One file/class per responsibility: entity, source, client, repository, provider, screen, widget. |
| Open/Closed | New exchanges are added by implementing existing interfaces, not editing core logic. |
| Liskov Substitution | `BinanceRestClient` and `BybitRestClient` are interchangeable behind `TickerSource`. |
| Interface Segregation | Small contracts: `TickerSource`, `CandleSource`, `OrderBookSource`, `TradeSource`, `MarketStreamSource`. |
| Dependency Inversion | Use cases and providers depend on repository/source interfaces, not concrete implementations. |

## Domain Layer

### Entities

| Entity | Description |
|---|---|
| `TradingSymbol` | Normalized trading pair: base, quote, raw exchange symbol, venue. |
  | `Venue` | Exchange identifier: binance, bybit, okx, coinbase, unknown. |
| `Timeframe` | Candle granularity: m1, m5, m15, m30, h1, h4, d1. |
| `Ticker` | Last price, bid, ask, 24h change, volume, timestamp. |
| `Candle` | OHLCV + timestamp. |
| `OrderBook` | Bid/ask levels, timestamp. |
| `Trade` | Price, amount, side, timestamp, trade id. |
| `Order` | Synthetic open order for prototype. |
| `Position` | Synthetic open position for prototype. |

### Source Contracts

```dart
abstract interface class TickerSource {
  Future<Result<Ticker>> fetchTicker(TradingSymbol symbol);
}

abstract interface class CandleSource {
  Future<Result<List<Candle>>> fetchCandles(
    TradingSymbol symbol,
    Timeframe timeframe, {
    int? limit,
  });
}

abstract interface class OrderBookSource {
  Future<Result<OrderBook>> fetchOrderBook(
    TradingSymbol symbol, {
    int? depth,
  });
}

abstract interface class TradeSource {
  Future<Result<List<Trade>>> fetchTrades(
    TradingSymbol symbol, {
    int? limit,
  });
}

abstract interface class MarketStreamSource {
  Stream<Result<Ticker>> watchTicker(TradingSymbol symbol);
  Stream<Result<OrderBook>> watchOrderBook(TradingSymbol symbol);
  Stream<Result<List<Trade>>> watchTrades(TradingSymbol symbol);
}
```

### Repository Interfaces

- `MarketDataRepository`: aggregates sources, cache, and mock fallback.

### Registry

`ExchangeCapabilityRegistry` maps `Venue` to `MarketDataFeature` capabilities. New venues are registered by adding an `ExchangeCapability` without changing use cases or UI.

## Data Layer

### Per-Exchange Implementations

Each venue provides:
- `*RestClient`: implements `TickerSource`, `CandleSource`, `OrderBookSource`, `TradeSource`.
- `*WebSocketClient`: implements `MarketStreamSource`.
- Inline parsing from exchange JSON to domain entities.

| Venue | REST Client | WebSocket Client |
|---|---|---|
| Binance | `BinanceRestClient` | `BinanceWebSocketClient` |
| Bybit | `BybitRestClient` | `BybitWebSocketClient` |
| OKX | `OKXRestClient` | `OKXWebSocketClient` |
| Coinbase | `CoinbaseRestClient` | `CoinbaseWebSocketClient` |
| Mock | `DeterministicMarketDataStore` | `DeterministicMarketDataStore` |

### Cache

- `MarketCache` (interface) in `domain/sources/market_cache.dart`.
- `MarketCacheDataSource` (Drift) in `data/datasources/local/market_cache_data_source.dart`.

### Connectivity

Online/offline is handled by `connectivityProvider` in `presentation/providers/connectivity_provider.dart`. `marketDataRepositoryProvider` watches connectivity and rebuilds with an empty `venueSources` map when offline; the repository then falls back to the injected `MarketDataStore`. WebSocket client providers are watched unconditionally so clients stay alive across connectivity changes.

## Presentation Layer

### Notifiers

| Notifier | Responsibility |
|---|---|
| `AuthNotifier` | Biometric/PIN gate state, PIN rate limiting. |
| `ThemeNotifier` | Dark/light mode and Flux/Carbon direction. |
| `TradingTerminalNotifier` | Selected symbol, order side/type, size, leverage, timeframe. |

### Providers

| Provider | Emits |
|---|---|
| `tickerStreamProvider(symbol)` | `AsyncValue<Ticker>` |
| `candlesProvider(symbol, timeframe)` | `AsyncValue<List<Candle>>` |
| `orderBookStreamProvider(symbol)` | `AsyncValue<OrderBook>` |
| `tradesStreamProvider(symbol)` | `AsyncValue<List<Trade>>` |
| `marketScreenerItemsProvider` | `List<MarketScreenerItem>` |
| `filteredMarketScreenerItemsProvider` | `List<MarketScreenerItem>` |
| `selectedSymbolProvider` | `TradingSymbol` |
| `tradingTerminalProvider` | `TradingTerminalState` |
| `themeSettingsProvider` | `ThemeSettings` |
| `authNotifierProvider` | `AuthState` |
| `exchangeCapabilityRegistryProvider` | `ExchangeCapabilityRegistry` |

## UI Layer

### Screens

See [`docs/screens.md`](./screens.md) for detailed screen specifications.

| Screen | File |
|---|---|
| Auth Gate | `ui/auth/auth_gate_screen.dart` |
| Home / Portfolio | `ui/screens/portfolio_screen.dart` |
| Trading Terminal | `ui/screens/trading_terminal_screen.dart` |
| Markets / Screener | `ui/screens/markets_screen.dart` |
| Exchange Detail | `ui/screens/exchange_detail_screen.dart` |
| Options Chain | `ui/screens/options_chain_screen.dart` |
| Compare | `ui/screens/compare_screen.dart` |
| Orders & History | `ui/screens/orders_history_screen.dart` |
| Account / Settings | `ui/screens/settings_screen.dart` |

### Shared Widgets

- `ScaffoldWithNavBar`: shell with bottom navigation.
- `DemoModeBanner`: banner shown when mock/offline data is active.
- `SignalGauge`: synthetic technical-signal gauge.
- `OrderBookPanel`: asks/bids with depth bars.
- `CandlestickChart`: candlestick chart wrapper.

### Bottom Navigation

Portfolio / Markets / Trade / Options / More

## Theme System

Theme is implemented via `AppColorTheme` (`ThemeExtension`) and `AppTheme` factories with:
- Flux (dir:b) tokens: accent `#00e6d2` (dark), up `#2ee6a6`, down `#ff5d77`.
- Carbon (dir:a) tokens: accent `#3f73ff` (dark), up `#16d196`, down `#ff4d63`.
- Dark/light backgrounds, card, chip, line, foreground variants.
- Fonts: Geist (body), Space Grotesk (display), JetBrains Mono (numbers), Instrument Serif (accents).

## State Management

- Use `flutter_riverpod` for dependency injection and state.
- Keep widgets dumb; business logic lives in notifiers/use cases.
- Emit new state; never mutate existing state objects.
- Dispose streams, controllers, and notifiers correctly.

## Networking

- REST bootstrap with `http` package.
- WebSocket streaming with `web_socket_channel`.
- Per-venue clients filter messages by instrument id to ignore data for other symbols.
- No exchange secrets bundled or stored in the app.

## Security

- PIN is hashed with PBKDF2-HMAC-SHA256 (100,000 iterations, 32-byte derived key) and a per-install salt, stored via `flutter_secure_storage` (iOS Keychain / Android Keystore).
- PIN entry is rate-limited: 5 failed attempts trigger a 15-minute lockout.
- No logging of secrets or PII.
- Biometric/PIN gate before sensitive screens.
- Validate all network input before use.

## Offline / Demo Mode

- Detect connectivity with `connectivity_plus`.
- Offline fallback to `DeterministicMarketDataStore`.
- Persistent "Demo data" banner when mock data is shown.
- Disabled actions: submit order, cancel order, refresh real data.

## Project Tracking (`br`)

Work is tracked in `br` (beads_rust). See [`AGENTS.md`](../AGENTS.md) for the full `br` workflow.

### Epic Hierarchy

- `youtrade-n97` — **YouTrade Flutter app: multi-venue trading terminal** (master epic)
  - `youtrade-0z9` — Phase 1: Scaffold project and implement domain entities + SOLID source contracts
  - `youtrade-fl6` — Phase 2: Implement data layer (mock store, cache, exchange clients)
  - `youtrade-qqg` — Phase 3: Presentation, theme, and auth guard
  - `youtrade-mv8` — Phase 4: Build UI screens from mockups
  - `youtrade-75g` — Phase 5: Integration, navigation, and verification
  - `youtrade-7k7` — Epic 7k7: screen-alignment pass
    - `youtrade-ann` — completed
    - `youtrade-3rt` — completed
    - `youtrade-v66` — completed
    - `youtrade-ejn` — completed
    - `youtrade-2qm` — completed
    - `youtrade-9zb` — completed
    - `youtrade-ys4` — completed
    - `youtrade-wze` — completed
    - `youtrade-kn5` — completed

### Dependency Order

```
youtrade-0z9 → youtrade-fl6 → youtrade-qqg → youtrade-mv8 → youtrade-75g
```

Implementation proceeds phase by phase. Tasks inside each phase are created iteratively as we learn.

## Testing Strategy

- Unit tests for entities, Result type, clients, repositories.
- Widget tests for screens and shared widgets with mocked providers.
- Integration tests for critical iOS Simulator flows using `integration_test`.
- Run `flutter test`, `flutter analyze`, `dart format --set-exit-if-changed lib test integration_test tool` before every commit.
- Run iOS integration tests on a booted iOS Simulator before claiming any screen-level feature is complete.

Integration tests live in `integration_test/`:

```
integration_test/
  app_test.dart              # smoke test: app launches and shows Portfolio
  auth_flow_test.dart        # local biometric/PIN gate flows
  markets_flow_test.dart     # screener flows
  offline_mode_test.dart     # offline/demo mode fallback
  compare_flow_test.dart     # compare screen flows
  exchange_detail_flow_test.dart # exchange detail flows
  options_flow_test.dart     # options chain flows
  orders_flow_test.dart      # orders & history flows
  settings_flow_test.dart    # account/settings flows
  helpers.dart               # shared integration-test utilities
```

## Package Stack

```yaml
dependencies:
  flutter_riverpod: ^2.6.1
  riverpod: ^2.6.1
  http: ^1.3.0
  web_socket_channel: ^3.0.2
  candlesticks: ^3.0.1
  fl_chart: ^0.70.2
  drift: ^2.26.0
  sqlite3_flutter_libs: ^0.5.34
  path: ^1.9.1
  path_provider: ^2.1.5
  crypto: ^3.0.6
  pointycastle: ^3.9.1
  local_auth: ^2.3.0
  local_auth_android: ^1.0.46
  local_auth_darwin: ^1.4.3
  flutter_secure_storage: ^9.2.4
  go_router: ^14.8.1
  cupertino_icons: ^1.0.8
  connectivity_plus: ^7.1.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  build_runner: ^2.4.15
  drift_dev: ^2.26.0
  mocktail: ^1.0.4
  flutter_lints: ^6.0.0
  stream_channel: ^2.1.4
  async: ^2.13.1
```

## Open Decisions

1. Portrait-only or support landscape on tablets.
2. Number of cached candles per symbol/timeframe.
3. Whether to add a settings bottom sheet or keep Account as a full screen.

## References

- [`docs/screens.md`](./screens.md): detailed screen flows, states, transitions.
- [`../AGENTS.md`](../AGENTS.md): project values, practices, conventions, and skill reference.
- [`/mockups/YouTrade.dc.html`](../mockups/YouTrade.dc.html): interactive UI prototype.
- [`/mockups/colors_and_type.css`](../mockups/colors_and_type.css): design tokens.
