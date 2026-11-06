import 'package:flutter_test/flutter_test.dart';
import 'package:pathway/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PathwayApp());
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(PathwayApp), findsOneWidget);
  });
}
