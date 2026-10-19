import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../nucleo/cores_app.dart';
import 'rewards_data.dart';

// DESIGN: cores, estilos e pequenas peças visuais reutilizáveis.

// ======== Cores e estilos ========

/// DESIGN: cores, gradientes e estilos reutilizáveis.
/// Para mudar o visual do app, edite só este arquivo.
/// As cores vêm da paleta da marca (CoresApp), a mesma do resto do app.
class RewardsStyle {
  static const Color green = CoresApp.brandText; // textos em destaque
  static const Color greenLight = CoresApp.primary; // preenchimentos (barra, selo)
  static const Color action = CoresApp.dark; // botões e barra do topo
  static const Color gold = CoresApp.accent;
  static const Color warning = CoresApp.accentWarm;
  static const Color shadow = Color(0x0D000000);

  static const LinearGradient balanceGradient = CoresApp.brandGradient;

  /// Fonte Outfit, a mesma do resto do app.
  static TextStyle font({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color color = CoresApp.textPrimary,
  }) =>
      GoogleFonts.outfit(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );

  static final TextStyle sectionTitle =
      font(fontSize: 18, fontWeight: FontWeight.bold);
  static final TextStyle storeName =
      font(fontSize: 16, fontWeight: FontWeight.bold);
  static final TextStyle caption =
      font(fontSize: 13, color: CoresApp.textSecondary);

  static final BoxDecoration cardDecoration = BoxDecoration(
    color: CoresApp.surface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: CoresApp.border),
    boxShadow: const [
      BoxShadow(color: shadow, blurRadius: 10, offset: Offset(0, 4)),
    ],
  );
}

// ======== Logotipo da loja ========

/// DESIGN: logotipo da loja, carregado da internet.
/// Se a loja não tiver logo ou a imagem falhar (sem rede), mostra o ícone de reserva.
class StoreLogo extends StatelessWidget {
  final Offer offer;

  const StoreLogo({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    final icon = Icon(offer.fallbackIcon, color: offer.color, size: 28);
    final logoUrl = offer.logoUrl;
    return Container(
      width: 56,
      height: 56,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: offer.color.withAlpha(30),
        borderRadius: BorderRadius.circular(14),
      ),
      child: logoUrl == null
          ? icon
          : Image.network(
              logoUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => icon,
            ),
    );
  }
}

// ======== Texto da oferta (loja, categoria, descrição) ========

/// DESIGN: bloco de texto da oferta (loja, categoria e descrição).
class OfferInfo extends StatelessWidget {
  final Offer offer;

  const OfferInfo({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Text(offer.store, style: RewardsStyle.storeName)),
          DiscountBadge(percent: offer.discountPercent),
        ]),
        Row(children: [
          Text(
            offer.category,
            style: RewardsStyle.font(fontSize: 12, color: offer.color),
          ),
          if (offer.hasWebsite) ...[
            const SizedBox(width: 6),
            const Icon(Icons.open_in_new, size: 14, color: CoresApp.gray),
          ],
        ]),
        const SizedBox(height: 4),
        Text(offer.description, style: RewardsStyle.caption),
      ],
    );
  }
}

// ======== Status do resgate (você tem / custa) ========

/// DESIGN: texto "Você tem X · custa Y" e situação do resgate.
class OfferStatus extends StatelessWidget {
  final Offer offer;
  final int balance;

  const OfferStatus({super.key, required this.offer, required this.balance});

  @override
  Widget build(BuildContext context) {
    final fmt = RewardsLogic.format;
    final canRedeem = balance >= offer.cost;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Você tem ${fmt(balance)} · custa ${fmt(offer.cost)}',
          style: RewardsStyle.caption,
        ),
        Text(
          canRedeem
              ? 'Pronto para resgatar'
              : 'Faltam ${fmt(offer.cost - balance)} CO₂Coins',
          style: RewardsStyle.font(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: canRedeem ? RewardsStyle.green : RewardsStyle.warning,
          ),
        ),
      ],
    );
  }
}

// ======== Selo de desconto ========

/// DESIGN: selo "X% OFF" no canto do card da oferta.
class DiscountBadge extends StatelessWidget {
  final int percent;

  const DiscountBadge({super.key, required this.percent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: RewardsStyle.greenLight.withAlpha(60),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$percent% OFF',
        style: RewardsStyle.font(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: RewardsStyle.green,
        ),
      ),
    );
  }
}
