import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:youtrade/core/result.dart';
import 'package:youtrade/domain/auth/exchange_credentials.dart';
import 'package:youtrade/domain/entities/venue.dart';
import 'package:youtrade/domain/repositories/exchange_credentials_repository.dart';
import 'package:youtrade/presentation/exchange/exchange_credentials_provider.dart';
import 'package:youtrade/ui/screens/exchange_detail_edit_screen.dart';
import 'package:youtrade/ui/screens/exchange_management_screen.dart';

class MockExchangeCredentialsRepository extends Mock
    implements ExchangeCredentialsRepository {}

void main() {
  late MockExchangeCredentialsRepository mockRepository;

  setUp(() {
    mockRepository = MockExchangeCredentialsRepository();
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        exchangeCredentialsRepositoryProvider.overrideWithValue(mockRepository),
      ],
      child: const MaterialApp(home: ExchangeManagementScreen()),
    );
  }

  group('ExchangeManagementScreen', () {
    testWidgets('shows loading then renders all venues', (tester) async {
      when(
        () => mockRepository.list(),
      ).thenAnswer((_) async => const Success<List<ExchangeCredentials>>([]));

      await tester.pumpWidget(buildApp());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.text('Exchange Management'), findsOneWidget);
      expect(find.text('Connected exchanges'), findsOneWidget);
      for (final venue in Venue.values) {
        expect(find.text(venue.displayName), findsWidgets);
      }
    });

    testWidgets('shows connected status for stored credentials', (
      tester,
    ) async {
      final credentials = [
        ExchangeCredentials(
          venue: Venue.binance,
          apiKey: 'key',
          secret: 'secret',
          isEnabled: true,
        ),
      ];
      when(
        () => mockRepository.list(),
      ).thenAnswer((_) async => Success(credentials));

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Connected'), findsOneWidget);
      expect(find.text('Disconnected'), findsNWidgets(Venue.values.length - 1));
    });

    testWidgets('navigates to detail screen on tap', (tester) async {
      when(
        () => mockRepository.list(),
      ).thenAnswer((_) async => const Success<List<ExchangeCredentials>>([]));
      when(
        () => mockRepository.load(Venue.binance),
      ).thenAnswer((_) async => const Success<ExchangeCredentials?>(null));

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Binance'));
      await tester.pumpAndSettle();

      expect(find.byType(ExchangeDetailEditScreen), findsOneWidget);
      expect(find.text('Binance API'), findsOneWidget);
      expect(find.text('Read-only access only'), findsOneWidget);
    });

    testWidgets('detail screen allows toggling secret visibility', (
      tester,
    ) async {
      when(
        () => mockRepository.list(),
      ).thenAnswer((_) async => const Success<List<ExchangeCredentials>>([]));
      when(
        () => mockRepository.load(Venue.bybit),
      ).thenAnswer((_) async => const Success<ExchangeCredentials?>(null));

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bybit'));
      await tester.pumpAndSettle();

      final secretField = find.widgetWithText(TextField, 'API Secret');
      expect(secretField, findsOneWidget);

      final textField = tester.widget<TextField>(secretField);
      expect(textField.obscureText, isTrue);

      final revealButton = find.descendant(
        of: secretField,
        matching: find.byType(IconButton),
      );
      await tester.tap(revealButton);
      await tester.pumpAndSettle();

      final updatedField = tester.widget<TextField>(secretField);
      expect(updatedField.obscureText, isFalse);
    });
  });
}
