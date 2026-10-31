import 'package:flutter_test/flutter_test.dart';
import 'package:pathway/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PathwayApp());
    expect(find.byType(PathwayApp), findsOneWidget);
  });
}
