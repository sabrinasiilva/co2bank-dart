import 'package:flutter/material.dart';
import 'rewards_data.dart';
import 'rewards_style.dart';

// TOPO DA TELA: cartão de saldo/progresso e campo de busca.

// ======== Cartão de saldo e progresso ========

/// ESTRUTURA: cartão do topo com saldo atual e progresso acumulado.
class BalanceCard extends StatelessWidget {
  final int balance; // moedas disponíveis para gastar
  final int earned; // total acumulado desde o início (nunca diminui)
  final int goal; // meta de moedas acumuladas

  const BalanceCard({
    super.key,
    required this.balance,
    required this.earned,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = RewardsLogic.format;
    final progress = RewardsLogic.progress(earned, goal);
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
          const Row(children: [
            Icon(Icons.eco, color: Colors.white70, size: 18),
            SizedBox(width: 6),
            Text('Seu Saldo Verde', style: _light),
          ]),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              '${fmt(balance)} CO₂Coins',
              key: ValueKey(balance),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Acumulado até agora', style: _light),
              Text('${fmt(earned)} / ${fmt(goal)}', style: _light),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(milliseconds: 700),
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                minHeight: 10,
                backgroundColor: Colors.white24,
                color: RewardsStyle.gold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            progress >= 1
                ? 'Meta atingida!'
                : 'Faltam ${fmt(goal - earned)} para a próxima meta',
            style: _light,
          ),
        ],
      ),
    );
  }
}

const _light = TextStyle(color: Colors.white70, fontSize: 14);

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
      builder: (_, value, __) => TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Pesquisar lojas ou descontos...',
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
          fillColor: Colors.grey.shade100,
        ),
      ),
    );
  }
}
