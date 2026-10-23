import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:co2bank_app/transacoes/telas/aba_extrato.dart';

Map<String, dynamic> _compra(String id, String loja, String categoria,
        double co2, DateTime quando) =>
    {
      'id': id,
      'merchant_name': loja,
      'category_label': categoria,
      'amount': 50,
      'co2_kg': co2,
      'occurred_at': quando.toIso8601String(),
    };

Future<void> _abrirExtrato(WidgetTester tester, List<Map<String, dynamic>> compras) async {
  await http.runWithClient(
    () => tester.pumpWidget(const MaterialApp(home: Scaffold(body: AbaExtrato()))),
    () => MockClient((_) async => http.Response(
          jsonEncode(compras),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        )),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('pt_BR');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({'auth_token': 'token-salvo'});
  });

  final agora = DateTime.now();
  final hoje = DateTime(agora.year, agora.month, agora.day, 12);
  final ontem = hoje.subtract(const Duration(days: 1));

  testWidgets('agrupa por dia com o CO2 de cada dia', (tester) async {
    await _abrirExtrato(tester, [
      _compra('1', 'Mercado Extra', 'Supermercado', 5.2, hoje),
      _compra('2', 'iFood', 'Restaurante', 3.0, hoje),
      _compra('3', 'Mercado Dia', 'Supermercado', 4.0, ontem),
    ]);

    expect(find.text('Hoje'), findsOneWidget);
    expect(find.text('Ontem'), findsOneWidget);
    expect(find.text('8,2 kg de CO2'), findsOneWidget);
    expect(find.text('4,0 kg de CO2'), findsOneWidget);
  });

  testWidgets('filtra pela categoria escolhida e volta para todas', (tester) async {
    await _abrirExtrato(tester, [
      _compra('1', 'Mercado Extra', 'Supermercado', 5.2, hoje),
      _compra('2', 'iFood', 'Restaurante', 3.0, hoje),
      _compra('3', 'Mercado Dia', 'Supermercado', 4.0, ontem),
    ]);

    // A categoria com mais compras vem primeiro nos filtros.
    final filtros = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip)).toList();
    expect((filtros[1].label as Text).data, 'Supermercado');

    await tester.tap(find.widgetWithText(ChoiceChip, 'Restaurante'));
    await tester.pumpAndSettle();
    expect(find.text('iFood'), findsOneWidget);
    expect(find.text('Mercado Extra'), findsNothing);
    expect(find.text('Ontem'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Todas'));
    await tester.pumpAndSettle();
    expect(find.text('Mercado Extra'), findsOneWidget);
  });

  testWidgets('sem filtros quando o mês só tem uma categoria', (tester) async {
    await _abrirExtrato(tester, [
      _compra('1', 'Mercado Extra', 'Supermercado', 5.2, hoje),
    ]);
    expect(find.byType(ChoiceChip), findsNothing);
  });
}
