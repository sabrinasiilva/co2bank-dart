import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../nucleo/cores_app.dart';
import '../transacoes/servico/servico_transacao.dart';

const _nomesMeses = [
  '',
  'Jan',
  'Fev',
  'Mar',
  'Abr',
  'Mai',
  'Jun',
  'Jul',
  'Ago',
  'Set',
  'Out',
  'Nov',
  'Dez',
];

const _nomesMesesCompletos = [
  '',
  'janeiro',
  'fevereiro',
  'março',
  'abril',
  'maio',
  'junho',
  'julho',
  'agosto',
  'setembro',
  'outubro',
  'novembro',
  'dezembro',
];

class CartaoEvolucaoMensal extends StatelessWidget {
  /// Nulo enquanto carrega.
  final List<ResumoDoMes>? meses;
  final int mesSelecionado;
  final int anoSelecionado;
  final void Function(int mes, int ano) aoSelecionarMes;

  const CartaoEvolucaoMensal({
    super.key,
    required this.meses,
    required this.mesSelecionado,
    required this.anoSelecionado,
    required this.aoSelecionarMes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: CoresApp.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CoresApp.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Evolução dos últimos 6 meses',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: CoresApp.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ..._conteudo(),
        ],
      ),
    );
  }

  List<Widget> _conteudo() {
    final meses = this.meses;
    if (meses == null) {
      return const [
        SizedBox(
          height: 170,
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: CoresApp.darkGreen,
              ),
            ),
          ),
        ),
      ];
    }

    if (meses.every((m) => m.resumo == null)) {
      return [
        SizedBox(
          height: 120,
          child: Center(
            child: Text(
              'Não foi possível carregar o histórico agora',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: CoresApp.textSecondary,
              ),
            ),
          ),
        ),
      ];
    }

    final indiceSelecionado = meses.indexWhere(
      (m) => m.mes == mesSelecionado && m.ano == anoSelecionado,
    );

    return [
      SizedBox(
        height: 170,
        child: _Barras(
          meses: meses,
          indiceSelecionado: indiceSelecionado,
          aoTocar: (i) => aoSelecionarMes(meses[i].mes, meses[i].ano),
        ),
      ),
      const SizedBox(height: 12),
      _Legenda(limite: _limiteAtual(meses)),
      if (indiceSelecionado > 0) ...[
        const SizedBox(height: 10),
        _Comparacao(
          atual: meses[indiceSelecionado],
          anterior: meses[indiceSelecionado - 1],
        ),
      ],
    ];
  }
}

/// O limite que vale hoje: o do mês mais recente que carregou.
double _limiteAtual(List<ResumoDoMes> meses) =>
    meses.reversed
        .map((m) => m.resumo?.limiteKg)
        .whereType<double>()
        .firstOrNull ??
    0;

class _Barras extends StatelessWidget {
  final List<ResumoDoMes> meses;
  final int indiceSelecionado;
  final ValueChanged<int> aoTocar;

  const _Barras({
    required this.meses,
    required this.indiceSelecionado,
    required this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    final limite = _limiteAtual(meses);
    final maiorTotal = meses
        .map((m) => m.resumo?.totalCo2Kg ?? 0)
        .fold<double>(0, math.max);
    final teto = math.max(maiorTotal, limite) * 1.15;

    return LayoutBuilder(
      builder: (context, restricoes) {
        const alturaRotulo = 22.0;
        const alturaValor = 18.0;
        final alturaUtil = restricoes.maxHeight - alturaRotulo - alturaValor;
        final yLimite = teto > 0 ? alturaUtil * (1 - limite / teto) : 0.0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < meses.length; i++)
                  Expanded(
                    child: _Barra(
                      dados: meses[i],
                      teto: teto,
                      alturaUtil: alturaUtil,
                      alturaValor: alturaValor,
                      alturaRotulo: alturaRotulo,
                      selecionada: i == indiceSelecionado,
                      aoTocar: () => aoTocar(i),
                    ),
                  ),
              ],
            ),
            if (limite > 0) ...[
              Positioned(
                left: 0,
                right: 0,
                top: alturaValor + yLimite,
                child: IgnorePointer(
                  child: CustomPaint(
                    size: const Size(double.infinity, 1.5),
                    painter: _PintorLinhaTracejada(),
                  ),
                ),
              ),
            ],
            if (indiceSelecionado >= 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < meses.length; i++)
                        Expanded(
                          child: i == indiceSelecionado
                              ? _ValorDaBarra(
                                  dados: meses[i],
                                  teto: teto,
                                  alturaUtil: alturaUtil,
                                  alturaRotulo: alturaRotulo,
                                )
                              : const SizedBox.shrink(),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Barra extends StatelessWidget {
  final ResumoDoMes dados;
  final double teto;
  final double alturaUtil;
  final double alturaValor;
  final double alturaRotulo;
  final bool selecionada;
  final VoidCallback aoTocar;

  const _Barra({
    required this.dados,
    required this.teto,
    required this.alturaUtil,
    required this.alturaValor,
    required this.alturaRotulo,
    required this.selecionada,
    required this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    final resumo = dados.resumo;
    final total = resumo?.totalCo2Kg ?? 0;
    final passou = resumo != null && total > resumo.limiteKg;
    final altura = teto > 0 ? alturaUtil * (total / teto) : 0.0;
    final cor = passou ? CoresApp.accentWarm : CoresApp.primary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: aoTocar,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(height: alturaValor),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: altura),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (_, valor, _) => Container(
              width: 26,
              // Mês sem compra vira só um tracinho, para a barra não sumir.
              height: math.max(valor, 3),
              decoration: BoxDecoration(
                color: total > 0
                    ? cor.withValues(alpha: selecionada ? 1 : 0.55)
                    : CoresApp.border,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
                border: selecionada && total > 0
                    ? Border.all(color: CoresApp.brandText, width: 1.5)
                    : null,
              ),
            ),
          ),
          SizedBox(
            height: alturaRotulo,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _nomesMeses[dados.mes],
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: selecionada ? FontWeight.w700 : FontWeight.w500,
                  color: selecionada
                      ? CoresApp.textPrimary
                      : CoresApp.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Valor em kg em cima da barra selecionada, com fundo para não se misturar
/// com a linha do limite quando a barra está perto dela.
class _ValorDaBarra extends StatelessWidget {
  final ResumoDoMes dados;
  final double teto;
  final double alturaUtil;
  final double alturaRotulo;

  const _ValorDaBarra({
    required this.dados,
    required this.teto,
    required this.alturaUtil,
    required this.alturaRotulo,
  });

  @override
  Widget build(BuildContext context) {
    final total = dados.resumo?.totalCo2Kg ?? 0;
    if (total <= 0) return const SizedBox.shrink();
    final altura = teto > 0 ? alturaUtil * (total / teto) : 0.0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: altura),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (_, valor, _) => Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _Etiqueta(
            texto: '${total.toStringAsFixed(0)} kg',
            cor: CoresApp.brandText,
          ),
          SizedBox(height: math.max(valor, 3) + alturaRotulo + 2),
        ],
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  final String texto;
  final Color cor;

  const _Etiqueta({required this.texto, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: CoresApp.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        texto,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: cor,
        ),
      ),
    );
  }
}

class _PintorLinhaTracejada extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pincel = Paint()
      ..color = CoresApp.accentWarm
      ..strokeWidth = 1.5;
    const traco = 5.0;
    const espaco = 4.0;
    for (var x = 0.0; x < size.width; x += traco + espaco) {
      canvas.drawLine(Offset(x, 0), Offset(x + traco, 0), pincel);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Legenda extends StatelessWidget {
  final double limite;

  const _Legenda({required this.limite});

  @override
  Widget build(BuildContext context) {
    Widget item(Color cor, String texto) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: cor,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          texto,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: CoresApp.textSecondary,
          ),
        ),
      ],
    );

    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        item(CoresApp.primary, 'Dentro do limite'),
        item(CoresApp.accentWarm, 'Passou do limite'),
        if (limite > 0)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomPaint(
                size: const Size(16, 1.5),
                painter: _PintorLinhaTracejada(),
              ),
              const SizedBox(width: 6),
              Text(
                'Limite (${limite.toStringAsFixed(0)} kg)',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: CoresApp.textSecondary,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _Comparacao extends StatelessWidget {
  final ResumoDoMes atual;
  final ResumoDoMes anterior;

  const _Comparacao({required this.atual, required this.anterior});

  @override
  Widget build(BuildContext context) {
    final totalAtual = atual.resumo?.totalCo2Kg;
    final totalAnterior = anterior.resumo?.totalCo2Kg;
    if (totalAtual == null || totalAnterior == null || totalAnterior == 0) {
      return const SizedBox.shrink();
    }

    final variacao = (totalAtual - totalAnterior) / totalAnterior * 100;
    final mesAnterior = _nomesMesesCompletos[anterior.mes];
    final caiu = variacao < 0;
    final vezes = totalAtual / totalAnterior;
    // Acima do dobro, "5x mais" é mais fácil de entender que "395% a mais".
    final texto = variacao.abs() < 1
        ? 'Praticamente igual a $mesAnterior'
        : vezes >= 2
            ? 'Cerca de ${vezes.round()}x mais que em $mesAnterior'
            : '${variacao.abs().toStringAsFixed(0)}% ${caiu ? 'a menos' : 'a mais'} que em $mesAnterior';

    return Row(
      children: [
        Icon(
          caiu ? Icons.trending_down_rounded : Icons.trending_up_rounded,
          size: 18,
          color: caiu ? CoresApp.brandText : CoresApp.accentWarm,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texto,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: caiu ? CoresApp.brandText : CoresApp.accentWarm,
            ),
          ),
        ),
      ],
    );
  }
}
