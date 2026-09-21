import 'package:flutter/material.dart';
import 'rewards_data.dart';

// DESIGN: cores, estilos e pequenas peças visuais reutilizáveis.

// ======== Cores e estilos ========

/// DESIGN: cores, gradientes e estilos reutilizáveis.
/// Para mudar o visual do app, edite só este arquivo.
class RewardsStyle {
  static const Color green = Color(0xFF2E7D32);
  static const Color greenLight = Color(0xFF4CAF50);
  static const Color gold = Color(0xFFFFC107);
  static const Color shadow = Color(0x0D000000);

  static const LinearGradient balanceGradient = LinearGradient(
    colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const TextStyle sectionTitle =
      TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
  static const TextStyle storeName =
      TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
  static final TextStyle caption =
      TextStyle(color: Colors.grey.shade600, fontSize: 13);

  static final BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.grey.shade200),
    boxShadow: const [
      BoxShadow(color: shadow, blurRadius: 10, offset: Offset(0, 4)),
    ],
  );
}

// ======== Logotipo da loja ========

/// DESIGN: logotipo da loja, carregado da internet.
/// Se a imagem falhar (sem rede), mostra o ícone de reserva.
class StoreLogo extends StatelessWidget {
  final Offer offer;

  const StoreLogo({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: offer.color.withAlpha(30),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Image.network(
        offer.logoUrl,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            Icon(offer.fallbackIcon, color: offer.color, size: 28),
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
        Row(children: [
          Expanded(child: Text(offer.store, style: RewardsStyle.storeName)),
          Icon(Icons.open_in_new, size: 18, color: Colors.grey.shade500),
        ]),
        Text(offer.category, style: TextStyle(color: offer.color, fontSize: 12)),
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: canRedeem ? RewardsStyle.green : Colors.orange.shade800,
          ),
        ),
      ],
    );
  }
}