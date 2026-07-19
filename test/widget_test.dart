import 'package:flutter_test/flutter_test.dart';
import 'package:esep/main.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(const EsepApp());
    expect(find.text('ESEP'), findsOneWidget);
  });
}
