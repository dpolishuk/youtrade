import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/main.dart';

void main() {
  testWidgets('App launches and shows title', (tester) async {
    await tester.pumpWidget(const YouTradeApp());
    expect(find.text('YouTrade'), findsOneWidget);
  });
}
