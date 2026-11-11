import 'package:co2bank_app/compartilhado/widgets/moldura_tela_larga.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<double> larguraVista(WidgetTester tester, Size tela) async {
    tester.view.physicalSize = tela;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    late double largura;
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, filho) => MolduraTelaLarga(child: filho!),
        home: Builder(
          builder: (context) {
            largura = MediaQuery.sizeOf(context).width;
            return const Scaffold(body: Text('conteúdo'));
          },
        ),
      ),
    );
    return largura;
  }

  testWidgets('no computador o app fica numa coluna com largura de celular',
      (tester) async {
    final largura = await larguraVista(tester, const Size(1920, 1080));

    expect(largura, MolduraTelaLarga.larguraMaxima);
    expect(find.text('conteúdo'), findsOneWidget);
  });

  testWidgets('no celular a tela continua com a largura inteira',
      (tester) async {
    final largura = await larguraVista(tester, const Size(400, 800));

    expect(largura, 400);
  });
}
