import 'package:flutter/material.dart';

import '../../nucleo/cores_app.dart';

/// No computador (navegador ou Windows) o app abre numa coluna central com a
/// largura de um celular, em vez de esticar os campos na tela inteira.
/// Em telas estreitas (celular) não muda nada.
class MolduraTelaLarga extends StatelessWidget {
  const MolduraTelaLarga({super.key, required this.child});

  final Widget child;

  /// Largura máxima do app em telas largas.
  static const larguraMaxima = 480.0;

  /// A partir desta largura a tela é tratada como computador.
  static const larguraTelaLarga = 700.0;

  @override
  Widget build(BuildContext context) {
    final midia = MediaQuery.of(context);
    if (midia.size.width < larguraTelaLarga) return child;

    final altura = midia.size.height;
    final alturaApp = altura > 960 ? 920.0 : altura;
    final temMargem = alturaApp < altura;

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: CoresApp.brandGradient),
      child: Center(
        child: Container(
          width: larguraMaxima,
          height: alturaApp,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: CoresApp.background,
            borderRadius: BorderRadius.circular(temMargem ? 28 : 0),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 40,
                offset: Offset(0, 16),
              ),
            ],
          ),
          // As telas leem o tamanho pelo MediaQuery; aqui ele passa a ser o da
          // coluna, para o layout de celular continuar igual.
          child: MediaQuery(
            data: midia.copyWith(size: Size(larguraMaxima, alturaApp)),
            child: child,
          ),
        ),
      ),
    );
  }
}
