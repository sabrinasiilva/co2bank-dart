import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:co2bank_app/main.dart';

void main() {
  testWidgets('o app abre no splash com o nome CO2Bank', (WidgetTester tester) async {
    await tester.pumpWidget(const AplicativoCo2Bank());

    expect(find.text('CO2Bank'), findsOneWidget);

    // Fecha o app antes do splash ir para o login, para o teste não depender
    // da tela de login nem de internet.
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
