# YouTrade

A multi-venue trading terminal built with Flutter. YouTrade aggregates public market data from major crypto exchanges into a single, cross-platform interface for screener, portfolio, options, and trading workflows.

## Supported venues

Public REST and WebSocket market data is supported for:

- Binance
- Bybit
- OKX
- Coinbase

All exchange integrations use public endpoints only; no API keys or trading secrets are required to run the app.

## Supported platforms

- iOS
- Android
- macOS
- Linux
- Windows
- Web

## Architecture

The project follows a layered, SOLID architecture:

- **Domain**: entities, source contracts, repository interfaces, registry, and use cases.
- **Data**: repository implementations, remote REST/WebSocket clients, local Drift cache, and mock fallback store.
- **Presentation**: Riverpod providers, auth guards, routing, and theme settings.
- **UI**: screens and widgets driven by presentation state.

## Development

### Prerequisites

- Flutter SDK
- Android SDK and JDK for Android development
- Xcode and a booted iOS Simulator for iOS development
- `gh` CLI for GitHub operations (optional)
- `pre-commit` for running pre-commit hooks (optional; install with `pip install pre-commit`)

### Run tests

```bash
flutter test
flutter analyze
dart format --set-exit-if-changed lib test integration_test tool
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

### Live smoke tests

```bash
dart run tool/smoke_test_venues.dart
```

This hits real OKX and Coinbase public endpoints and should be run manually only (it is not part of CI).

### Pre-commit hooks

This repository includes `.pre-commit-config.yaml`. Install the hooks with:

```bash
pre-commit install
```

The hooks run `dart format`, `flutter analyze`, and `flutter test` on Dart files before each commit.

## Notes

- `flutter_secure_storage` does not yet support Swift Package Manager; this will become a hard error in a future Flutter release.
- `local_auth` uses deprecated application lifecycle events on iOS and will require a plugin update.

## Resources

### Project documentation

- [Architecture overview](./docs/architecture.md)
- [Design tokens](./docs/design_tokens.md)
- [Screen flows](./docs/screens.md)
- [Mockup audit](./docs/mockup_audit.md)
- [Interactive mockups](./mockups/)

### External resources

- [Flutter documentation](https://docs.flutter.dev/)
- [Effective Dart](https://dart.dev/effective-dart)
