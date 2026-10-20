import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:co2bank_app/perfil/sugestao_limite.dart';
import 'package:co2bank_app/transacoes/servico/servico_transacao.dart';

ResumoMensal _resumo({
  required double totalCo2Kg,
  int quantidadeTransacoes = 3,
  int mes = 1,
}) =>
    ResumoMensal(
      mes: mes,
      ano: 2026,
      totalCo2Kg: totalCo2Kg,
      limiteKg: 200,
      percentualUsado: totalCo2Kg / 2,
      totalGastoReais: 500,
      quantidadeTransacoes: quantidadeTransacoes,
      principaisCategorias: const [],
    );

ResumoDoMes _mes(double? totalCo2Kg, {int quantidade = 3, int mes = 1}) =>
    ResumoDoMes(
      mes: mes,
      ano: 2026,
      resumo: totalCo2Kg == null
          ? null
          : _resumo(
              totalCo2Kg: totalCo2Kg,
              quantidadeTransacoes: quantidade,
              mes: mes,
            ),
    );

void main() {
  group('sugerirLimitePeloHistorico', () {
    test('sem nenhum mês devolve nulo', () {
      expect(sugerirLimitePeloHistorico(const []), isNull);
    });

    test('meses que não carregaram não contam e, sozinhos, devolvem nulo', () {
      expect(sugerirLimitePeloHistorico([_mes(null), _mes(null)]), isNull);
    });

    test('meses sem compras não contam e, sozinhos, devolvem nulo', () {
      expect(
        sugerirLimitePeloHistorico([
          _mes(0, quantidade: 0),
          _mes(0, quantidade: 0),
          _mes(0, quantidade: 0),
        ]),
        isNull,
      );
    });

    test('sugere 10% abaixo da média dos 3 meses', () {
      final sugestao = sugerirLimitePeloHistorico([
        _mes(100, mes: 1),
        _mes(200, mes: 2),
        _mes(300, mes: 3),
      ])!;

      expect(sugestao.mediaKg, 200);
      expect(sugestao.sugeridoKg, 180);
      expect(sugestao.mesesConsiderados, 3);
    });

    test('ignora meses zerados e não carregados no cálculo da média', () {
      final sugestao = sugerirLimitePeloHistorico([
        _mes(null),
        _mes(0, quantidade: 0),
        _mes(150),
      ])!;

      expect(sugestao.mediaKg, 150);
      expect(sugestao.sugeridoKg, 140); // 135 arredondado para dezenas
      expect(sugestao.mesesConsiderados, 1);
    });

    test('mês com compras mas 0 kg entra na média', () {
      final sugestao = sugerirLimitePeloHistorico([
        _mes(0, quantidade: 2),
        _mes(200),
      ])!;

      expect(sugestao.mediaKg, 100);
      expect(sugestao.sugeridoKg, 90);
      expect(sugestao.mesesConsiderados, 2);
    });

    test('arredonda para a dezena mais próxima', () {
      // 105 * 0,9 = 94,5 -> 90
      expect(sugerirLimitePeloHistorico([_mes(105)])!.sugeridoKg, 90);
      // 106 * 0,9 = 95,4 -> 100
      expect(sugerirLimitePeloHistorico([_mes(106)])!.sugeridoKg, 100);
      // 230 * 0,9 = 207 -> 210
      expect(sugerirLimitePeloHistorico([_mes(230)])!.sugeridoKg, 210);
    });

    test('não sugere menos que o limite mínimo (50 kg)', () {
      final sugestao = sugerirLimitePeloHistorico([_mes(30)])!;

      expect(sugestao.sugeridoKg, limiteMinimoKg);
      // A média continua sendo a real, sem o limite aplicado.
      expect(sugestao.mediaKg, 30);
    });

    test('não sugere mais que o limite máximo (500 kg)', () {
      final sugestao = sugerirLimitePeloHistorico([_mes(1000), _mes(800)])!;

      expect(sugestao.sugeridoKg, limiteMaximoKg);
      expect(sugestao.mediaKg, 900);
    });

    test('valores logo nas bordas da faixa', () {
      // 55,5 * 0,9 = 49,95 -> 50
      expect(sugerirLimitePeloHistorico([_mes(55.5)])!.sugeridoKg, 50);
      // 555 * 0,9 = 499,5 -> 500
      expect(sugerirLimitePeloHistorico([_mes(555)])!.sugeridoKg, 500);
    });
  });

  group('CartaoSugestaoLimite', () {
    Future<void> montar(
      WidgetTester tester,
      SugestaoLimite sugestao, {
      required double limiteAtualKg,
      ValueChanged<double>? aoAplicar,
    }) =>
        tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: CartaoSugestaoLimite(
              sugestao: sugestao,
              limiteAtualKg: limiteAtualKg,
              aoAplicar: aoAplicar,
            ),
          ),
        ));

    const sugestao = SugestaoLimite(
      mediaKg: 200,
      sugeridoKg: 180,
      mesesConsiderados: 3,
    );

    testWidgets('mostra a sugestão quando o limite atual está acima',
        (tester) async {
      double? aplicado;
      await montar(tester, sugestao,
          limiteAtualKg: 250, aoAplicar: (v) => aplicado = v);

      expect(find.text('Sugestão: 180 kg/mês'), findsOneWidget);
      expect(
        find.text('10% abaixo da sua média dos últimos 3 meses, que foi de 200 kg.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Usar 180 kg'));
      expect(aplicado, 180);
    });

    testWidgets('sem aoAplicar não mostra o botão', (tester) async {
      await montar(tester, sugestao, limiteAtualKg: 250);
      expect(find.text('Usar 180 kg'), findsNothing);
    });

    testWidgets('elogia quando o limite atual já está abaixo da sugestão',
        (tester) async {
      await montar(
        tester,
        const SugestaoLimite(mediaKg: 100, sugeridoKg: 90, mesesConsiderados: 1),
        limiteAtualKg: 80,
        aoAplicar: (_) {},
      );

      expect(find.text('Seu limite já é um bom desafio'), findsOneWidget);
      expect(
        find.text('Ele está abaixo da sua média do último mês (100 kg). Continue assim!'),
        findsOneWidget,
      );
      expect(find.textContaining('Usar'), findsNothing);
    });

    testWidgets(
      'não diz "10% abaixo da média" quando a sugestão foi elevada ao mínimo',
      (tester) async {
        // Média de 30 kg: a sugestão vira 50 kg (o mínimo), que fica ACIMA da
        // média, então o texto não pode dizer "10% abaixo da sua média".
        final elevada = sugerirLimitePeloHistorico([_mes(30)])!;
        await montar(tester, elevada, limiteAtualKg: 100);

        expect(find.textContaining('10% abaixo'), findsNothing);
      },
    );
  });
}
