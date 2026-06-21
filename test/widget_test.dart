import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:youtrade/domain/auth/local_auth_service.dart';
import 'package:youtrade/main.dart';
import 'package:youtrade/presentation/auth/auth_guard_provider.dart';

class MockLocalAuthService extends Mock implements LocalAuthService {}

void main() {
  testWidgets('App launches and shows auth gate', (tester) async {
    final mockService = MockLocalAuthService();
    when(() => mockService.canCheckBiometrics()).thenAnswer((_) async => false);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localAuthServiceProvider.overrideWithValue(mockService)],
        child: const YouTradeApp(),
      ),
    );
    await tester.pump();

    expect(find.text('YouTrade is locked'), findsOneWidget);
  });
}
