import 'package:flutter/material.dart';

import '../../nucleo/cores_app.dart';

enum VarianteLogo {
  colorida('assets/logo.png'),
  branca('assets/logo_branca.png'),
  preta('assets/logo_preta.png');

  final String caminho;
  const VarianteLogo(this.caminho);
}

class LogoCo2Bank extends StatelessWidget {
  final double tamanho;
  final VarianteLogo variante;

  /// Coloca a logo num quadrado branco arredondado, como no ícone do app.
  /// Serve para usar a versão colorida em fundo escuro: sem o selo, a semente
  /// do guaraná (preta) some. Em fundo escuro sem selo, use a variante branca.
  final bool comSelo;

  const LogoCo2Bank({
    super.key,
    required this.tamanho,
    this.variante = VarianteLogo.colorida,
    this.comSelo = false,
  });

  @override
  Widget build(BuildContext context) {
    final imagem = Image.asset(
      variante.caminho,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'CO2Bank',
      // Aparece com um fade curto em vez de "pipocar" quando termina de carregar.
      frameBuilder: (_, filho, quadro, carregadaNaHora) => carregadaNaHora
          ? filho
          : AnimatedOpacity(
              opacity: quadro == null ? 0 : 1,
              duration: const Duration(milliseconds: 250),
              child: filho,
            ),
    );

    if (!comSelo) {
      return SizedBox(width: tamanho, height: tamanho, child: imagem);
    }

    return Container(
      width: tamanho,
      height: tamanho,
      padding: EdgeInsets.all(tamanho * 0.16),
      decoration: BoxDecoration(
        color: CoresApp.surface,
        borderRadius: BorderRadius.circular(tamanho * 0.26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: tamanho * 0.2,
            offset: Offset(0, tamanho * 0.06),
          ),
        ],
      ),
      child: imagem,
    );
  }
}
