# YouTrade Architecture

This document describes the high-level and detailed software architecture of the YouTrade Flutter application. It complements [`docs/screens.md`](./screens.md) and the project [`AGENTS.md`](../AGENTS.md).

## Goals

- Build a multi-venue trading terminal that can graduate from mock-first prototype to production.
- Keep UI/UX faithful to the `/mockups/` interactive prototype.
- Use public REST and WebSocket market data from Binance, Bybit, OKX, and Coinbase.
- Store optional read-only API keys securely for private balance/positions data.
- Support SOLID principles, layered/clean architecture, and Riverpod state management.

## Architecture Layers

```
lib/
├── app.dart                    # MaterialApp, router, theme
├── main.dart                   # Entry point + provider container
├── injection.dart              # Riverpod provider wiring
├── core/                       # Result, failures, extensions, theme tokens
├── domain/                     # Entities, source contracts, repository interfaces, use cases
├── data/                       # REST/WebSocket clients, adapters, cache, secure storage
├── presentation/               # Riverpod providers and notifiers
└── ui/                         # Screens, widgets, charts
```

### Layer Rules

- **Domain** knows nothing about Flutter, HTTP, WebSocket, or JSON.
- **Data** knows about external APIs and maps them to domain entities.
- **Presentation** exposes state via Riverpod providers and notifiers.
- **UI** only renders state and forwards user events.

## SOLID Mapping

| Principle | How we apply it |
|---|---|
| Single Responsibility | One file/class per responsibility: entity, source, adapter, repository, provider, screen, widget. |
| Open/Closed | New exchanges are added by implementing existing interfaces, not editing core logic. |
| Liskov Substitution | `BinanceRestClient` and `MockRestClient` are interchangeable behind `TickerSource`. |
| Interface Segregation | Small contracts: `TickerSource`, `CandleSource`, `OrderBookSource`, `TradeSource`, `MarketStreamSource`. |
| Dependency Inversion | Use cases and providers depend on repository/source interfaces, not concrete implementations. |

## Domain Layer

### Entities

| Entity | Description |
|---|---|
| `Symbol` | Normalized trading pair: base, quote, raw exchange symbol, asset class. |
| `Venue` | Exchange identifier: binance, bybit, okx, coinbase. |
| `Ticker` | Last price, bid, ask, 24h change, volume, timestamp. |
| `Candle` | OHLCV + timestamp. |
| `OrderBook` | Bid/ask levels, spread. |
| `Trade` | Price, amount, side, timestamp. |
| `ExchangeCredentials` | Venue, API key, secret, password, enabled flag, timestamps. |
| `Position` | Synthetic open position for prototype. |

### Source Contracts

```dart
abstract interface class TickerSource {
  Future<Result<Ticker>> fetchTicker(Symbol symbol);
}

abstract interface class CandleSource {
  Future<Result<List<Candle>>> fetchCandles(Symbol symbol, Timeframe tf, {int? limit});
}

abstract interface class OrderBookSource {
  Future<Result<OrderBook>> fetchOrderBook(Symbol symbol, {int? depth});
}

abstract interface class TradeSource {
  Future<Result<List<Trade>>> fetchTrades(Symbol symbol, {int? limit});
}

abstract interface class MarketStreamSource {
  Stream<Result<TickerUpdate>> watchTicker(Symbol symbol);
  Stream<Result<OrderBookUpdate>> watchOrderBook(Symbol symbol);
  Stream<Result<Trade>> watchTrades(Symbol symbol);
}
```

### Repository Interfaces

- `MarketDataRepository`: aggregates sources, cache, and mock fallback.
- `CredentialsRepository`: secure storage of exchange API keys.

## Data Layer

### Per-Exchange Implementations

Each venue provides:
- `RestMarketClient`: implements `TickerSource`, `CandleSource`, `OrderBookSource`, `TradeSource`.
- `WsMarketClient`: implements `MarketStreamSource`.
- `Adapter`: maps exchange DTOs to domain entities.

| Venue | REST Client | WebSocket Client | Adapter |
|---|---|---|---|
| Binance | `BinanceRestClient` | `BinanceWsClient` | `BinanceAdapter` |
| Bybit | `BybitRestClient` | `BybitWsClient` | `BybitAdapter` |
| OKX | `OkxRestClient` | `OkxWsClient` | `OkxAdapter` |
| Coinbase | `CoinbaseRestClient` | `CoinbaseWsClient` | `CoinbaseAdapter` |
| Mock | `MockRestClient` | `MockWsClient` | `MockAdapter` |

### Registry

`ExchangeRegistry` maps `Venue` to capabilities and client instances. New venues are registered here without changing use cases or UI.

### Cache

- `MarketCache` (Drift): stores recent candles, tickers, order books, and trades.
- `SecureCredentialsStore` (`flutter_secure_storage`): stores API keys and secrets.

### Connectivity Mode

`ConnectivityMode` decides which data source to use:
- `offlineMock`: always return synthetic mock data.
- `onlineReal`: bootstrap from cache, then WebSocket streams.

## Presentation Layer

### Notifiers

| Notifier | Responsibility |
|---|---|
| `ThemeNotifier` | Flux/Carbon direction, dark/light mode. |
| `AuthGuardNotifier` | Biometric/PIN gate state. |
| `ExchangeCredentialsNotifier` | Add/edit/delete/test credentials. |

### Providers

| Provider | Emits |
|---|---|
| `tickerProvider(symbol, venue)` | `AsyncValue<Ticker>` |
| `candlesProvider(symbol, venue, timeframe)` | `AsyncValue<List<Candle>>` |
| `orderBookProvider(symbol, venue)` | `AsyncValue<OrderBook>` |
| `tradesProvider(symbol, venue)` | `AsyncValue<List<Trade>>` |
| `portfolioProvider` | `AsyncValue<Portfolio>` |
| `marketsProvider(filter)` | `AsyncValue<List<MarketRow>>` |
| `exchangeDetailProvider(venue)` | `AsyncValue<ExchangeDetail>` |
| `compareProvider(symbols)` | `AsyncValue<CompareData>` |
| `signalsProvider(symbol)` | `AsyncValue<TechnicalSignals>` |
| `optionsProvider(expiration)` | `AsyncValue<OptionsChain>` |
| `ordersProvider(tab)` | `AsyncValue<List<Order>>` |

## UI Layer

### Screens

See [`docs/screens.md`](./screens.md) for detailed screen specifications.

| Screen | File |
|---|---|
| Home / Portfolio | `ui/screens/portfolio_screen.dart` |
| Trading Terminal | `ui/screens/terminal_screen.dart` |
| Markets / Screener | `ui/screens/markets_screen.dart` |
| Exchange Detail | `ui/screens/exchange_detail_screen.dart` |
| Options Chain | `ui/screens/options_screen.dart` |
| Compare | `ui/screens/compare_screen.dart` |
| Orders & History | `ui/screens/orders_screen.dart` |
| Account / Settings | `ui/screens/settings_screen.dart` |
| Exchange Management | `ui/screens/exchange_management_screen.dart` |

### Shared Widgets

- `YtAppHeader`: logo + theme/direction toggles.
- `YtBottomNav`: Portfolio / Markets / Trade / Options / More.
- `YtCard`: bordered card with consistent styling.
- `YtChip`: selectable filter/action chip.
- `YtListRow`: reusable list row with optional chevron.
- `YtPriceChange`: formatted delta with color.
- `YtSparkline`: mini line chart.
- `YtCandleChart`: candlestick chart wrapper.
- `YtOrderBook`: asks/bids with depth bars.

## Theme System

Theme is implemented via `ThemeExtension<YouTradeTheme>` with:
- Flux (dir:b) tokens: accent `#00e6d2` (dark), up `#2ee6a6`, down `#ff5d77`.
- Carbon (dir:a) tokens: accent `#3f73ff` (dark), up `#16d196`, down `#ff4d63`.
- Dark/light backgrounds, card, chip, line, foreground variants.
- Fonts: Geist (body), Space Grotesk (display), JetBrains Mono (numbers).

## State Management

- Use `flutter_riverpod` for dependency injection and state.
- Keep widgets dumb; business logic lives in notifiers/use cases.
- Emit new state; never mutate existing state objects.
- Dispose streams, controllers, and notifiers correctly.

## Networking

- REST bootstrap with `http` package.
- WebSocket streaming with `web_socket_channel`.
- Per-venue rate-limit tracking via client-level throttling.
- No exchange secrets bundled in app; optional user-provided keys stored securely.

## Security

- API keys in `flutter_secure_storage` (iOS Keychain / Android Keystore).
- No logging of keys, balances, or PII.
- Biometric/PIN gate before sensitive screens.
- Read-only keys only for first build.
- Validate all network input before use.

## Offline / Demo Mode

- Detect connectivity with `connectivity_plus`.
- Offline fallback to `MockDataStore`.
- Persistent "Demo data" banner when mock data is shown.
- Disabled actions: submit order, cancel order, test connection, refresh real data.

## Project Tracking (`br`)

Work is tracked in `br` (beads_rust). See [`AGENTS.md`](../AGENTS.md) for the full `br` workflow.

### Epic Hierarchy

- `youtrade-n97` — **YouTrade Flutter app: multi-venue trading terminal** (master epic)
  - `youtrade-0z9` — Phase 1: Scaffold project and implement domain entities + SOLID source contracts
  - `youtrade-fl6` — Phase 2: Implement data layer (mock store, cache, exchange clients)
  - `youtrade-qqg` — Phase 3: Presentation, theme, and auth guard
  - `youtrade-mv8` — Phase 4: Build UI screens from mockups
  - `youtrade-4hy` — Build Exchange Management screen for read-only API key input
  - `youtrade-75g` — Phase 5: Integration, navigation, and verification

### Dependency Order

```
youtrade-0z9 → youtrade-fl6 → youtrade-qqg → youtrade-mv8 → youtrade-75g
                                    ↘ youtrade-4hy ↗
```

Implementation proceeds phase by phase. Tasks inside each phase are created iteratively as we learn.

## Testing Strategy

- Unit tests for entities, Result type, use cases, adapters.
- Widget tests for screens and shared widgets with mocked providers.
- Integration tests for critical iOS Simulator flows using `integration_test`.
- Run `flutter test`, `flutter analyze`, `flutter format` before every commit.
- Run iOS integration tests on a booted iOS Simulator before claiming any screen-level feature is complete.

## Package Stack

```yaml
dependencies:
  flutter_riverpod: ^2.x
  riverpod: ^2.x
  http: ^1.x
  web_socket_channel: ^3.x
  candlesticks: ^3.x
  fl_chart: ^1.x
  drift: ^2.x
  sqlite3_flutter_libs: ^0.5.x
  local_auth: ^3.x
  flutter_secure_storage: ^10.x
  go_router: ^14.x
  connectivity_plus: ^6.x
  freezed_annotation: ^2.x
  json_annotation: ^4.x

dev_dependencies:
  build_runner: ^2.x
  freezed: ^2.x
  json_serializable: ^6.x
  drift_dev: ^2.x
  flutter_lints: ^5.x
  mocktail: ^1.x
```

## References

- [`docs/screens.md`](./screens.md): detailed screen flows, states, transitions.
- [`../AGENTS.md`](../AGENTS.md): project values, practices, conventions, and skill reference.
- [`/mockups/YouTrade.dc.html`](../mockups/YouTrade.dc.html): interactive UI prototype.
- [`/mockups/colors_and_type.css`](../mockups/colors_and_type.css): design tokens.

## Open Decisions

1. Exact supported candle timeframes (current proposal: 1m, 5m, 15m, 1H, 4H, 1D, 1W).
2. Portrait-only or support landscape on tablets.
3. Number of cached candles per symbol/timeframe.
4. Whether Exchange Management is a full screen or bottom sheet.
