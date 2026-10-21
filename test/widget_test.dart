import 'package:flutter_test/flutter_test.dart';
import 'package:jadiguna/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const JadiGunaApp());
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(JadiGunaApp), findsOneWidget);
  });
}
