import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:co2bank_app/co2/cartao_impacto.dart';
import 'package:co2bank_app/transacoes/servico/servico_transacao.dart';

ResumoMensal _resumo({
  required double totalCo2Kg,
  double limiteKg = 100,
  int mes = 10,
  int quantidadeTransacoes = 5,
}) =>
    ResumoMensal(
      mes: mes,
      ano: 2026,
      totalCo2Kg: totalCo2Kg,
      limiteKg: limiteKg,
      percentualUsado: totalCo2Kg / limiteKg * 100,
      totalGastoReais: 800,
      quantidadeTransacoes: quantidadeTransacoes,
      principaisCategorias: const [],
    );

Future<void> _montar(
  WidgetTester tester,
  ResumoMensal resumo, {
  int? coinsDoMes,
}) =>
    tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: CartaoImpacto(resumo: resumo, coinsDoMes: coinsDoMes),
        ),
      ),
    ));

void main() {
  testWidgets('dentro do limite mostra quanto sobrou e as equivalências',
      (tester) async {
    // Sobram 22 kg: 22 / (22/12) = 12 árvores; 22 / 0,12 = 183 km.
    await _montar(tester, _resumo(totalCo2Kg: 78));

    expect(find.text('Seu impacto em outubro'), findsOneWidget);
    expect(find.text('Você emitiu 22,0 kg a menos que o seu limite'),
        findsOneWidget);
    expect(find.text('Cerca do que 12 árvores absorvem em um mês'),
        findsOneWidget);
    expect(find.text('O mesmo que deixar de rodar cerca de 183 km de carro'),
        findsOneWidget);
    expect(find.text('Ficou dentro do limite ecológico (78% usado)'),
        findsOneWidget);
  });

  testWidgets('árvore no singular', (tester) async {
    // Sobram 2 kg: 2 / (22/12) = 1,09 -> 1 árvore; 2 / 0,12 = 16,7 -> 17 km.
    await _montar(tester, _resumo(totalCo2Kg: 98));

    expect(find.text('Cerca do que 1 árvore absorve em um mês'), findsOneWidget);
    expect(find.text('O mesmo que deixar de rodar cerca de 17 km de carro'),
        findsOneWidget);
  });

  testWidgets('acima do limite mostra o excesso só em km de carro',
      (tester) async {
    await _montar(tester, _resumo(totalCo2Kg: 130));

    expect(find.text('Você passou 30,0 kg do seu limite'), findsOneWidget);
    expect(find.textContaining('árvore'), findsNothing);
    expect(find.text('O mesmo que rodar cerca de 250 km a mais de carro'),
        findsOneWidget);
    expect(
      find.text('Usou 130% do limite. No próximo mês dá para virar o jogo'),
      findsOneWidget,
    );
  });

  testWidgets('diferença menor que 0,5 kg não mostra equivalências',
      (tester) async {
    await _montar(tester, _resumo(totalCo2Kg: 99.8));

    expect(find.textContaining('árvore'), findsNothing);
    expect(find.textContaining('km de carro'), findsNothing);
  });

  testWidgets('textos de compras e de CO₂Coins', (tester) async {
    await _montar(tester, _resumo(totalCo2Kg: 50, quantidadeTransacoes: 1));
    expect(find.text('Você acompanhou o CO2 de 1 compra'), findsOneWidget);
    expect(
      find.text('O CO2 que você economiza vira desconto em lojas parceiras'),
      findsOneWidget,
    );

    await _montar(tester, _resumo(totalCo2Kg: 50), coinsDoMes: 0);
    expect(find.text('Você acompanhou o CO2 de 5 compras'), findsOneWidget);
    expect(
      find.text(
          'Fique abaixo do limite para ganhar CO₂Coins e trocar por desconto em parceiros'),
      findsOneWidget,
    );

    await _montar(tester, _resumo(totalCo2Kg: 50), coinsDoMes: 35);
    expect(find.text('Ganhou 35 CO₂Coins para trocar por desconto em parceiros'),
        findsOneWidget);
  });
}
