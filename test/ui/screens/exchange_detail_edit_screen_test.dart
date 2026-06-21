import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:youtrade/core/failures.dart';
import 'package:youtrade/core/result.dart';
import 'package:youtrade/domain/auth/exchange_credentials.dart';
import 'package:youtrade/domain/entities/venue.dart';
import 'package:youtrade/domain/repositories/exchange_credentials_repository.dart';
import 'package:youtrade/presentation/exchange/exchange_credentials_provider.dart';
import 'package:youtrade/presentation/theme/app_theme.dart';
import 'package:youtrade/presentation/theme/theme_mode.dart';
import 'package:youtrade/ui/screens/exchange_detail_edit_screen.dart';

class MockExchangeCredentialsRepository extends Mock
    implements ExchangeCredentialsRepository {}

void main() {
  late MockExchangeCredentialsRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(
      const ExchangeCredentials(venue: Venue.binance, apiKey: '', secret: ''),
    );
  });

  setUp(() {
    mockRepository = MockExchangeCredentialsRepository();
  });

  Widget buildScreen() {
    return ProviderScope(
      overrides: [
        exchangeCredentialsRepositoryProvider.overrideWithValue(mockRepository),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(AppVisualDirection.flux),
        home: ExchangeDetailEditScreen(venue: Venue.binance),
      ),
    );
  }

  group('ExchangeDetailEditScreen', () {
    testWidgets('pops on successful save', (tester) async {
      when(
        () => mockRepository.load(Venue.binance),
      ).thenAnswer((_) async => const Success<ExchangeCredentials?>(null));
      when(
        () => mockRepository.save(any()),
      ).thenAnswer((_) async => const Success<void>(null));
      when(
        () => mockRepository.list(),
      ).thenAnswer((_) async => const Success<List<ExchangeCredentials>>([]));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'API Key'), 'key');
      await tester.enterText(
        find.widgetWithText(TextField, 'API Secret'),
        'secret',
      );
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.byType(ExchangeDetailEditScreen), findsNothing);
      verify(() => mockRepository.save(any())).called(1);
    });

    testWidgets('stays open and shows SnackBar on save failure', (
      tester,
    ) async {
      when(
        () => mockRepository.load(Venue.binance),
      ).thenAnswer((_) async => const Success<ExchangeCredentials?>(null));
      when(
        () => mockRepository.save(any()),
      ).thenAnswer((_) async => const Err<void>(UnknownFailure('save failed')));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'API Key'), 'key');
      await tester.enterText(
        find.widgetWithText(TextField, 'API Secret'),
        'secret',
      );
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.byType(ExchangeDetailEditScreen), findsOneWidget);
      expect(find.text('Save failed: save failed'), findsOneWidget);
    });

    testWidgets('pops on successful delete', (tester) async {
      when(
        () => mockRepository.load(Venue.binance),
      ).thenAnswer((_) async => const Success<ExchangeCredentials?>(null));
      when(
        () => mockRepository.delete(Venue.binance),
      ).thenAnswer((_) async => const Success<void>(null));
      when(
        () => mockRepository.list(),
      ).thenAnswer((_) async => const Success<List<ExchangeCredentials>>([]));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete credentials'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.byType(ExchangeDetailEditScreen), findsNothing);
      verify(() => mockRepository.delete(Venue.binance)).called(1);
    });

    testWidgets('stays open and shows SnackBar on delete failure', (
      tester,
    ) async {
      when(
        () => mockRepository.load(Venue.binance),
      ).thenAnswer((_) async => const Success<ExchangeCredentials?>(null));
      when(() => mockRepository.delete(Venue.binance)).thenAnswer(
        (_) async => const Err<void>(UnknownFailure('delete failed')),
      );

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete credentials'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.byType(ExchangeDetailEditScreen), findsOneWidget);
      expect(find.text('Delete failed: delete failed'), findsOneWidget);
    });
  });
}
