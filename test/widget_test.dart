import 'package:flutter_test/flutter_test.dart';

import 'package:co2bank_app/main.dart';

void main() {
  testWidgets('HomeScreen mostra o título CO2Bank', (WidgetTester tester) async {
    await tester.pumpWidget(const CO2BankApp());

    expect(find.text('CO2Bank'), findsOneWidget);
  });
}
