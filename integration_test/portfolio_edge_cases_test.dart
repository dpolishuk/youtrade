import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Portfolio edge cases', () {
    testWidgets('empty wallet shows zero balance', (tester) async {
      await pumpAuthenticatedAppWithAccountClient(
        tester,
        accountClient: emptyWalletAccountClient(),
      );

      expect(find.textContaining('AGGREGATED NET WORTH'), findsOneWidget);
      expect(find.textContaining('0 VENUES'), findsOneWidget);
      expect(find.text('No open positions'), findsOneWidget);
      await binding.takeScreenshot('portfolio_empty_wallet');
    });

    testWidgets('API error shows retry', (tester) async {
      await pumpAuthenticatedAppWithAccountClient(
        tester,
        accountClient: errorAccountClient(),
      );

      expect(find.text('Failed to load portfolio'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      await binding.takeScreenshot('portfolio_api_error');
    });

    testWidgets('missing credentials shows connect message', (tester) async {
      await pumpAuthenticatedAppWithAccountClient(
        tester,
        accountClient: emptyWalletAccountClient(),
        hasCredentials: false,
      );

      expect(find.text('Connect API Key'), findsOneWidget);
      await binding.takeScreenshot('portfolio_missing_credentials');
    });

    testWidgets('multiple coins displayed', (tester) async {
      await pumpAuthenticatedAppWithAccountClient(
        tester,
        accountClient: multiCoinAccountClient(),
      );

      expect(find.textContaining('AGGREGATED NET WORTH'), findsOneWidget);
      expect(find.textContaining('3 VENUES'), findsOneWidget);
      expect(find.text('USDT'), findsOneWidget);
      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('ETH'), findsOneWidget);
      await binding.takeScreenshot('portfolio_multiple_coins');
    });
  });
}
