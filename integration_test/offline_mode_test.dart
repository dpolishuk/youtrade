import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Offline / demo mode', () {
    testWidgets(
      'shows demo banner and uses mock data when connectivity is offline',
      (tester) async {
        await pumpAuthenticatedApp(tester, online: false);

        expect(find.text('Demo / Offline mode'), findsOneWidget);
        expect(find.text('AGGREGATED NET WORTH · 2 VENUES'), findsOneWidget);
        expect(find.textContaining(r'$50,000'), findsOneWidget);
        await binding.takeScreenshot('offline_portfolio_tab');
      },
    );
  });
}
