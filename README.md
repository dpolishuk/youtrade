# YouTrade

A multi-venue trading terminal built with Flutter. YouTrade aggregates public market data from major crypto exchanges into a single, cross-platform interface for screener, portfolio, options, and trading workflows.

## Supported venues

Public REST and WebSocket market data is supported for:

- Binance
- Bybit
- OKX
- Coinbase

All exchange integrations use public endpoints only; no API keys or trading secrets are required to run the app.

## Architecture

The project follows a layered, SOLID architecture:

- **Domain**: entities, source contracts, repository interfaces, registry, and use cases.
- **Data**: repository implementations, remote REST/WebSocket clients, local Drift cache, and mock fallback store.
- **Presentation**: Riverpod providers, auth guards, routing, and theme settings.
- **UI**: screens and widgets driven by presentation state.

## Development

### Prerequisites

- Flutter SDK
- Xcode and a booted iOS Simulator for iOS development
- `gh` CLI for GitHub operations (optional)

### Run tests

```bash
flutter test
flutter analyze
dart format --set-exit-if-changed lib test integration_test
```

### Run on iOS Simulator

```bash
xcrun simctl boot <UDID>
flutter run -d <UDID>
```

### Run integration tests on iOS Simulator

```bash
flutter test integration_test -d <UDID>
```

## Notes

- `flutter_secure_storage` does not yet support Swift Package Manager; this will become a hard error in a future Flutter release.
- `local_auth` uses deprecated application lifecycle events on iOS and will require a plugin update.

## Resources

- [Flutter documentation](https://docs.flutter.dev/)
- [Effective Dart](https://dart.dev/effective-dart)
