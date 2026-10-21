import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../nucleo/cores_app.dart';
import 'oferta.dart';

/// Cores, fontes e decorações usadas nas telas de recompensas.
/// As cores vêm da paleta da marca (CoresApp), a mesma do resto do app.
class EstiloRecompensas {
  static const Color verde = CoresApp.brandText; // textos em destaque
  static const Color verdeClaro = CoresApp.primary; // preenchimentos (barra, selo)
  static const Color acao = CoresApp.dark; // botões e barra do topo
  static const Color dourado = CoresApp.accent;
  static const Color alerta = CoresApp.accentWarm;
  static const Color sombra = Color(0x0D000000);

  static const LinearGradient gradienteSaldo = CoresApp.brandGradient;

  /// Fonte Outfit, a mesma do resto do app.
  static TextStyle fonte({
    double tamanho = 14,
    FontWeight peso = FontWeight.normal,
    Color cor = CoresApp.textPrimary,
  }) =>
      GoogleFonts.outfit(
        fontSize: tamanho,
        fontWeight: peso,
        color: cor,
      );

  static final TextStyle tituloSecao =
      fonte(tamanho: 18, peso: FontWeight.bold);
  static final TextStyle nomeLoja =
      fonte(tamanho: 16, peso: FontWeight.bold);
  static final TextStyle legenda =
      fonte(tamanho: 13, cor: CoresApp.textSecondary);

  static final BoxDecoration decoracaoCartao = BoxDecoration(
    color: CoresApp.surface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: CoresApp.border),
    boxShadow: const [
      BoxShadow(color: sombra, blurRadius: 10, offset: Offset(0, 4)),
    ],
  );
}

/// Logotipo da loja, carregado da internet. Sem logo ou sem rede, mostra o
/// ícone da categoria.
class LogoLoja extends StatelessWidget {
  final Oferta oferta;

  const LogoLoja({super.key, required this.oferta});

  @override
  Widget build(BuildContext context) {
    final icone = Icon(oferta.iconeReserva, color: oferta.cor, size: 28);
    final urlLogo = oferta.urlLogo;
    return Container(
      width: 56,
      height: 56,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: oferta.cor.withAlpha(30),
        borderRadius: BorderRadius.circular(14),
      ),
      child: urlLogo == null
          ? icone
          : Image.network(
              urlLogo,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => icone,
            ),
    );
  }
}

/// Nome da loja, categoria e descrição da oferta.
class InfoOferta extends StatelessWidget {
  final Oferta oferta;

  const InfoOferta({super.key, required this.oferta});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Text(oferta.loja, style: EstiloRecompensas.nomeLoja)),
          SeloDesconto(percentual: oferta.percentualDesconto),
        ]),
        Row(children: [
          Text(
            oferta.categoria,
            style: EstiloRecompensas.fonte(tamanho: 12, cor: oferta.cor),
          ),
          if (oferta.temSite) ...[
            const SizedBox(width: 6),
            const Icon(Icons.open_in_new, size: 14, color: CoresApp.gray),
          ],
        ]),
        const SizedBox(height: 4),
        Text(oferta.descricao, style: EstiloRecompensas.legenda),
      ],
    );
  }
}

/// Linha "Você tem X · custa Y" e quanto falta para resgatar.
class SituacaoOferta extends StatelessWidget {
  final Oferta oferta;
  final int saldo;

  const SituacaoOferta({super.key, required this.oferta, required this.saldo});

  @override
  Widget build(BuildContext context) {
    final formatar = LogicaRecompensas.formatar;
    final podeResgatar = saldo >= oferta.custo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Você tem ${formatar(saldo)} · custa ${formatar(oferta.custo)}',
          style: EstiloRecompensas.legenda,
        ),
        Text(
          podeResgatar
              ? 'Pronto para resgatar'
              : 'Faltam ${formatar(oferta.custo - saldo)} CO₂Coins',
          style: EstiloRecompensas.fonte(
            peso: FontWeight.bold,
            tamanho: 13,
            cor: podeResgatar
                ? EstiloRecompensas.verde
                : EstiloRecompensas.alerta,
          ),
        ),
      ],
    );
  }
}

/// Selo "X% OFF" no canto do card da oferta e do cupom.
class SeloDesconto extends StatelessWidget {
  final int percentual;

  const SeloDesconto({super.key, required this.percentual});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: EstiloRecompensas.verdeClaro.withAlpha(60),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$percentual% OFF',
        style: EstiloRecompensas.fonte(
          tamanho: 13,
          peso: FontWeight.bold,
          cor: EstiloRecompensas.verde,
        ),
      ),
    );
  }
}
