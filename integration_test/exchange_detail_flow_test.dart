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

        expect(find.text('Aggregated net worth · 4 venues'), findsOneWidget);

        await tester.tap(find.text(r'$312,480'));
        await tester.pumpAndSettle(const Duration(seconds: 5));

        expect(find.text('All portfolios'), findsOneWidget);
        expect(find.text('Binance'), findsWidgets);
        expect(find.text('Spot · Perp · Options'), findsOneWidget);
        expect(find.text(r'$312,480'), findsOneWidget);
        expect(find.text(r'+$6,620'), findsOneWidget);
        await binding.takeScreenshot('exchange_detail_binance');

        await tester.tap(find.text('OKX'));
        await tester.pumpAndSettle(const Duration(seconds: 3));

        expect(find.text('OKX'), findsWidgets);
        expect(find.text(r'$146,900'), findsOneWidget);
        expect(find.text(r'+$2,080'), findsOneWidget);
        await binding.takeScreenshot('exchange_detail_okx');

        await tester.tap(find.text('All portfolios'));
        await tester.pumpAndSettle(const Duration(seconds: 3));

        expect(find.text('Aggregated net worth · 4 venues'), findsOneWidget);
      },
    );
  });
}
