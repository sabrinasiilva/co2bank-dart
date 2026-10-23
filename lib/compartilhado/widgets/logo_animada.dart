import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A logo do CO2Bank desenhada em código, peça por peça, para a abertura do
/// app: o "C" laranja se desenha, a semente cai no centro e as duas folhas
/// brotam. As medidas e as cores são as mesmas do arquivo da marca (Canva).
class LogoAnimada extends StatelessWidget {
  /// Andamento da montagem, de 0 (nada na tela) a 1 (logo completa).
  final Animation<double> progresso;
  final double largura;

  const LogoAnimada({super.key, required this.progresso, this.largura = 180});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: largura,
      height: largura * _Logo.altura / _Logo.largura,
      child: CustomPaint(painter: _PintorLogo(progresso)),
    );
  }
}

/// Medidas da logo no arquivo original (pontos do PDF exportado do Canva).
abstract final class _Logo {
  static const x0 = 404.6;
  static const y0 = 248.88;
  static const largura = 335.25;
  static const altura = 295.46;

  static const centro = Offset(515.4, 396.6);
  static const raioExterno = 110.8;
  static const raioInterno = 70.75;
  // A fenda do "C": vai do centro do anel até a borda da direita.
  static const fenda = Rect.fromLTRB(515.4, 377.8, 626.2, 418.4);
  static const raioSemente = 36.05;

  // Ponto onde as duas folhas se encontram, de onde elas "brotam".
  static const caule = Offset(592.12, 396.61);
  static const retanguloFolhaCima = Rect.fromLTRB(592.12, 248.88, 739.85, 396.61);
  static const retanguloFolhaBaixo = Rect.fromLTRB(592.12, 396.61, 739.85, 544.34);

  static const gradienteAnel = [Color(0xFFFFDE59), Color(0xFFFF924E)];
  static const gradienteSemente = [Color(0xFF010101), Color(0xFF727272)];
  static const gradienteFolha = [Color(0xFF8AD957), Color(0xFFC8E265)];

  static Path folhaCima() => Path()
    ..moveTo(739.85, 293.2)
    ..cubicTo(739.85, 350.18, 693.42, 396.61, 636.44, 396.61)
    ..lineTo(592.12, 396.61)
    ..lineTo(592.12, 352.29)
    ..cubicTo(592.12, 295.31, 638.55, 248.88, 695.53, 248.88)
    ..lineTo(739.85, 248.88)
    ..close();

  static Path folhaBaixo() => Path()
    ..moveTo(636.44, 396.61)
    ..cubicTo(693.42, 396.61, 739.85, 443.04, 739.85, 500.02)
    ..lineTo(739.85, 544.34)
    ..lineTo(695.53, 544.34)
    ..cubicTo(638.55, 544.34, 592.12, 497.91, 592.12, 440.93)
    ..lineTo(592.12, 396.61)
    ..close();
}

class _PintorLogo extends CustomPainter {
  final Animation<double> progresso;

  // Cada peça entra num trecho do tempo total.
  static const _anel = Interval(0, 0.45, curve: Curves.easeInOutCubic);
  static const _semente = Interval(0.32, 0.68, curve: Curves.bounceOut);
  static const _folhaCima = Interval(0.5, 0.88, curve: Curves.easeOutBack);
  static const _folhaBaixo = Interval(0.6, 1, curve: Curves.easeOutBack);

  _PintorLogo(this.progresso) : super(repaint: progresso);

  @override
  void paint(Canvas canvas, Size size) {
    final t = progresso.value;
    canvas.save();
    // A partir daqui dá para usar as coordenadas do arquivo original.
    canvas.scale(size.width / _Logo.largura);
    canvas.translate(-_Logo.x0, -_Logo.y0);

    // Mesma ordem do arquivo original: folhas, anel por cima delas, a fenda
    // do "C" recortando os dois e, por último, a semente inteira.
    canvas.save();
    canvas.clipPath(Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(const Rect.fromLTWH(_Logo.x0 - 20, _Logo.y0 - 20,
          _Logo.largura + 40, _Logo.altura + 40))
      ..addRect(_Logo.fenda));
    _desenharFolha(canvas, _Logo.folhaCima(), _Logo.retanguloFolhaCima,
        _folhaCima.transform(t), giro: 0.5, visivel: t >= _folhaCima.begin,
        // No original o verde mais forte fica na ponta de cima da folha.
        escuro: Alignment.topRight, claro: Alignment.bottomLeft);
    _desenharFolha(canvas, _Logo.folhaBaixo(), _Logo.retanguloFolhaBaixo,
        _folhaBaixo.transform(t), giro: -0.5, visivel: t >= _folhaBaixo.begin,
        escuro: Alignment.topLeft, claro: Alignment.bottomRight);
    _desenharAnel(canvas, _anel.transform(t));
    canvas.restore();

    _desenharSemente(canvas, _semente.transform(t), t >= _semente.begin);

    canvas.restore();
  }

  /// O "C" é um anel que vai se fechando a partir da fenda, como um traço.
  void _desenharAnel(Canvas canvas, double andamento) {
    if (andamento <= 0) return;
    final externo = Rect.fromCircle(center: _Logo.centro, radius: _Logo.raioExterno);
    final interno = Rect.fromCircle(center: _Logo.centro, radius: _Logo.raioInterno);
    const inicio = 0.18; // logo abaixo da fenda
    final volta = (2 * math.pi - 0.001) * andamento;

    final anel = Path()
      ..arcTo(externo, inicio, volta, true)
      ..arcTo(interno, inicio + volta, -volta, false)
      ..close();

    final tinta = Paint()
      ..shader = const LinearGradient(colors: _Logo.gradienteAnel).createShader(externo);
    canvas.drawPath(anel, tinta);
  }

  /// A semente cai de cima e quica até parar no centro do "C".
  void _desenharSemente(Canvas canvas, double andamento, bool visivel) {
    if (!visivel) return;
    final queda = (1 - andamento) * -150;
    final centro = _Logo.centro.translate(0, queda);
    final circulo = Rect.fromCircle(center: centro, radius: _Logo.raioSemente);
    final tinta = Paint()
      ..shader = const LinearGradient(colors: _Logo.gradienteSemente).createShader(circulo);
    canvas.drawCircle(centro, _Logo.raioSemente, tinta);
  }

  /// A folha cresce a partir do caule, girando um pouco até a posição final.
  void _desenharFolha(Canvas canvas, Path folha, Rect retangulo, double andamento,
      {required double giro,
      required bool visivel,
      required Alignment escuro,
      required Alignment claro}) {
    if (!visivel || andamento <= 0) return;
    final tinta = Paint()
      ..shader = LinearGradient(begin: escuro, end: claro, colors: _Logo.gradienteFolha)
          .createShader(retangulo);
    canvas.save();
    canvas.translate(_Logo.caule.dx, _Logo.caule.dy);
    canvas.rotate(giro * (1 - andamento));
    canvas.scale(andamento);
    canvas.translate(-_Logo.caule.dx, -_Logo.caule.dy);
    canvas.drawPath(folha, tinta);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PintorLogo antigo) => antigo.progresso != progresso;
}
