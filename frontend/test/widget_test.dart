// Basic Flutter widget smoke test for DARNA.
import 'package:flutter_test/flutter_test.dart';
import 'package:DARNA/main.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const DarnaApp());
    // Just verify the app renders something
    expect(find.byType(DarnaApp), findsOneWidget);
  });
}
