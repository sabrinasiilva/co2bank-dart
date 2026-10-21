import 'package:co2bank_app/compartilhado/widgets/aviso_erro_carregamento.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('mostra o título e chama o tentar de novo', (tester) async {
    var tentativas = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AvisoErroCarregamento(
          titulo: 'Não foi possível carregar o extrato',
          aoTentarNovamente: () => tentativas++,
        ),
      ),
    ));

    expect(find.text('Não foi possível carregar o extrato'), findsOneWidget);
    expect(find.textContaining('Confira sua conexão'), findsOneWidget);

    await tester.tap(find.text('Tentar novamente'));
    expect(tentativas, 1);
  });

  testWidgets('usa um título padrão', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: AvisoErroCarregamento(aoTentarNovamente: () {})),
    ));

    expect(find.text('Não foi possível carregar'), findsOneWidget);
  });
}
