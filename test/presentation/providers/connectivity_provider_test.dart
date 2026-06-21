import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/presentation/providers/connectivity_provider.dart';

void main() {
  group('isDemoModeProvider', () {
    test('is false when connectivity is online', () {
      final container = ProviderContainer(
        overrides: [
          connectivityProvider.overrideWith((ref) => Stream.value(true)),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(isDemoModeProvider), isFalse);
    });

    test('is true when connectivity is offline', () async {
      final container = ProviderContainer(
        overrides: [
          connectivityProvider.overrideWith((ref) => Stream.value(false)),
        ],
      );
      addTearDown(container.dispose);

      await container.read(connectivityProvider.future);

      expect(container.read(isDemoModeProvider), isTrue);
    });
  });
}
