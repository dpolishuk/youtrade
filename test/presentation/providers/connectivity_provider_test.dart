import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/presentation/providers/connectivity_provider.dart';

void main() {
  group('isOnline', () {
    test('returns false for an empty connectivity result list', () {
      expect(isOnline([]), isFalse);
    });

    test('returns true when wifi is present', () {
      expect(isOnline([ConnectivityResult.wifi]), isTrue);
    });

    test('returns false when the list contains wifi and none', () {
      expect(
        isOnline([ConnectivityResult.wifi, ConnectivityResult.none]),
        isFalse,
      );
    });

    test('returns true for mobile connectivity', () {
      expect(isOnline([ConnectivityResult.mobile]), isTrue);
    });

    test('returns false for none connectivity', () {
      expect(isOnline([ConnectivityResult.none]), isFalse);
    });
  });

  group('connectivityProvider', () {
    test('emits offline then online transitions', () async {
      final controller = StreamController<bool>.broadcast();
      final container = ProviderContainer(
        overrides: [
          connectivityProvider.overrideWith((ref) => controller.stream),
        ],
      );
      addTearDown(() {
        controller.close();
        container.dispose();
      });

      final states = <bool>[];
      container.listen(connectivityProvider, (_, state) {
        if (state case AsyncData(:final value)) {
          states.add(value);
        }
      });

      controller.add(false);
      controller.add(true);
      await controller.close();
      await container.read(connectivityProvider.future);

      expect(states, [false, true]);
    });
  });

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
