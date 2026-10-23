import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:co2bank_app/compartilhado/widgets/logo_animada.dart';
import 'package:co2bank_app/main.dart';

void main() {
  testWidgets('o app abre na tela de abertura com a logo animada', (WidgetTester tester) async {
    await tester.pumpWidget(const AplicativoCo2Bank());
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.byType(LogoAnimada), findsOneWidget);

    // Fecha o app antes da abertura ir para o login, para o teste não depender
    // da tela de login nem de internet.
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
