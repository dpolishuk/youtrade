import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Exchange Detail flow', () {
    testWidgets(
      'navigates from Portfolio, shows Binance detail, switches venue',
      timeout: const Timeout(Duration(minutes: 5)),
      (tester) async {
        await pumpAuthenticatedApp(tester);

        expect(find.text('AGGREGATED NET WORTH · 2 VENUES'), findsOneWidget);

        await tester.tap(find.text(r'$48,000'));
        await tester.pumpAndSettle(const Duration(seconds: 5));

        expect(find.text('All portfolios'), findsOneWidget);
        expect(find.text('Bybit'), findsWidgets);
        expect(find.text('Perp · Spot'), findsOneWidget);
        expect(find.text(r'$198,320'), findsOneWidget);
        expect(find.text(r'-$1,710'), findsOneWidget);
        await binding.takeScreenshot('exchange_detail_bybit');

        await tester.tap(find.text('Binance'));
        await tester.pumpAndSettle(const Duration(seconds: 3));

        expect(find.text('Binance'), findsWidgets);
        expect(find.text('Spot · Perp · Options'), findsOneWidget);
        expect(find.text(r'$312,480'), findsOneWidget);
        expect(find.text(r'+$6,620'), findsOneWidget);
        await binding.takeScreenshot('exchange_detail_binance');

        await tester.tap(find.text('All portfolios'));
        await tester.pumpAndSettle(const Duration(seconds: 3));

        expect(find.text('AGGREGATED NET WORTH · 2 VENUES'), findsOneWidget);
      },
    );
  });
}
