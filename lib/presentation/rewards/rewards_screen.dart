import 'package:flutter/material.dart';
import 'rewards_data.dart';
import 'rewards_header.dart';
import 'rewards_offers.dart';
import 'rewards_style.dart';

/// ESTRUTURA E ESTADO: (saldo e busca).
class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  static const int _goal = 3000; // meta de moedas acumuladas
  final _search = TextEditingController();
  final int _earned = 1850; // total acumulado (não diminui)
  int _balance = 1250; // moedas disponíveis (diminui ao resgatar)
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _open(Offer offer) async {
    final ok = await RewardsLogic.openStore(offer);
    if (!ok && mounted) {
      showRewardsSnack(context, 'Não foi possível abrir ${offer.store}.');
    }
  }

  Future<void> _redeem(Offer offer) async {
    final confirmed = await confirmRedeem(context, offer);
    if (!confirmed || !mounted) return;
    setState(() => _balance -= offer.cost);
    showRewardsSnack(
      context,
      'Cupom da ${offer.store} resgatado!',
      action: SnackBarAction(
        label: 'Abrir loja',
        onPressed: () => _open(offer),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final offers = RewardsLogic.filter(kOffers, _query);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Verde'),
        backgroundColor: RewardsStyle.greenLight,
        foregroundColor: Colors.white,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            BalanceCard(balance: _balance, earned: _earned, goal: _goal),
            const SizedBox(height: 20),
            SearchBox(
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 24),
            const Text('Descontos e Cashback em Lojas', style: RewardsStyle.sectionTitle),
            const SizedBox(height: 12),
            if (offers.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: Text('Nenhuma loja encontrada')),
              ),
            for (final o in offers)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OfferCard(
                  offer: o,
                  balance: _balance,
                  onOpen: () => _open(o),
                  onRedeem: () => _redeem(o),
                ),
              ),
          ],
        ),
      ),
    );
  }
}