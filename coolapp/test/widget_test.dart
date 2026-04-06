// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:campuslink/main.dart';

void main() {
  testWidgets('CampusLink app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CampusLinkApp());
    expect(find.byType(CampusLinkApp), findsOneWidget);
  });
}
