import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youtrade/main.dart';

void main() {
  testWidgets('App launches and shows title', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: YouTradeApp()));
    expect(find.text('YouTrade'), findsOneWidget);
  });
}
