import 'package:flutter/material.dart';
import '../../nucleo/cores_app.dart';
import 'rewards_data.dart';
import 'rewards_style.dart';

// OFERTAS E RESGATE: card de cada loja, confirmação e aviso.

// ======== Card da oferta ========

/// ESTRUTURA: card de uma oferta.
/// Tocar no card abre o site da loja (quando ela tem site); o botão resgata o desconto.
class OfferCard extends StatelessWidget {
  final Offer offer;
  final int balance;
  final VoidCallback onOpen;
  final VoidCallback onRedeem;

  const OfferCard({
    super.key,
    required this.offer,
    required this.balance,
    required this.onOpen,
    required this.onRedeem,
  });

  bool get _canRedeem => balance >= offer.cost;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: RewardsStyle.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: offer.hasWebsite ? onOpen : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StoreLogo(offer: offer),
                    const SizedBox(width: 14),
                    Expanded(child: OfferInfo(offer: offer)),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: RewardsLogic.progress(balance, offer.cost),
                    minHeight: 8,
                    backgroundColor: CoresApp.border,
                    color: _canRedeem
                        ? RewardsStyle.greenLight
                        : RewardsStyle.gold,
                  ),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: OfferStatus(offer: offer, balance: balance)),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RewardsStyle.action,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      textStyle: RewardsStyle.font(fontWeight: FontWeight.w600),
                    ),
                    onPressed: _canRedeem ? onRedeem : null,
                    child: const Text('Resgatar'),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ======== Confirmação do resgate ========

/// ESTRUTURA: diálogo de confirmação do resgate.
/// Devolve true se o usuário confirmou, false caso contrário.
Future<bool> confirmRedeem(BuildContext context, Offer offer) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(
        'Resgatar desconto?',
        style: RewardsStyle.font(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      content: Text(
        'Você vai usar ${RewardsLogic.format(offer.cost)} CO₂Coins para '
        'garantir "${offer.description}" na ${offer.store}.',
        style: RewardsStyle.font(color: CoresApp.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            'Cancelar',
            style: RewardsStyle.font(color: CoresApp.textSecondary),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: RewardsStyle.action,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            'Resgatar',
            style: RewardsStyle.font(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}

// ======== Aviso na parte de baixo da tela ========

/// ESTRUTURA: aviso curto na parte de baixo da tela.
/// Esconde o aviso anterior para não empilhar mensagens.
void showRewardsSnack(
  BuildContext context,
  String message, {
  SnackBarAction? action,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message, style: RewardsStyle.font(color: Colors.white)),
      action: action,
      behavior: SnackBarBehavior.floating,
    ));
}