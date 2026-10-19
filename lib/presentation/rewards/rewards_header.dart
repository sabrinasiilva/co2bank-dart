import 'package:flutter/material.dart';
import '../../nucleo/cores_app.dart';
import 'rewards_data.dart';
import 'rewards_style.dart';

// TOPO DA TELA: cartão de saldo/progresso e campo de busca.

// ======== Cartão de saldo e progresso ========

/// ESTRUTURA: cartão do topo com saldo atual e quanto ainda resta do que foi ganho no mês.
class BalanceCard extends StatelessWidget {
  final int balance; // moedas disponíveis para gastar (diminui ao resgatar)
  final int earned; // ganhas no mês por ficar abaixo do limite
  final double kgSaved; // kg de CO₂ abaixo do limite no mês

  const BalanceCard({
    super.key,
    required this.balance,
    required this.earned,
    required this.kgSaved,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = RewardsLogic.format;
    final progress = earned > 0 ? RewardsLogic.progress(balance, earned) : 0.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: RewardsStyle.balanceGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.eco, color: RewardsStyle.green, size: 18),
            const SizedBox(width: 6),
            Text('Seu Saldo Verde', style: _light),
          ]),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              '${fmt(balance)} CO₂Coins',
              key: ValueKey(balance),
              style: RewardsStyle.font(
                color: RewardsStyle.green,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Disponível do que ganhou no mês', style: _light),
              Text('${fmt(balance)} / ${fmt(earned)}', style: _light),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(milliseconds: 700),
              builder: (_, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 10,
                backgroundColor: RewardsStyle.green.withAlpha(40),
                color: RewardsStyle.green,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            earned > 0
                ? '${kgSaved.toStringAsFixed(1)} kg de CO₂ abaixo do seu limite este mês'
                : 'Fique abaixo do limite este mês para ganhar CO₂Coins',
            style: _light,
          ),
        ],
      ),
    );
  }
}

final _light = RewardsStyle.font(color: RewardsStyle.green);

// ======== Campo de busca ========

/// ESTRUTURA: campo de busca com botão de limpar.
class SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const SearchBox({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (_, value, _) => TextField(
        controller: controller,
        onChanged: onChanged,
        style: RewardsStyle.font(),
        decoration: InputDecoration(
          hintText: 'Pesquisar lojas ou descontos...',
          hintStyle: RewardsStyle.caption,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Limpar busca',
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: CoresApp.background,
        ),
      ),
    );
  }
}
