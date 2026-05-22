import 'package:flutter_test/flutter_test.dart';
import 'package:arkadaslik_uygulamasi/main.dart';

void main() {
  testWidgets('App starts with splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Arkadaşlık'), findsOneWidget);
    expect(find.text('Uygulaması'), findsOneWidget);
  });
}
