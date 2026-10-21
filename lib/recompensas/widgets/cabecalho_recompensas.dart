import 'package:flutter/material.dart';
import '../../nucleo/cores_app.dart';
import '../estilo_recompensas.dart';
import '../oferta.dart';

/// Cartão do topo com o saldo atual e quanto ainda resta do que foi ganho
/// no mês.
class CartaoSaldo extends StatelessWidget {
  final int saldo; // moedas disponíveis para gastar (diminui ao resgatar)
  final int ganhos; // ganhas no mês por ficar abaixo do limite
  final double kgEconomizados; // kg de CO₂ abaixo do limite no mês

  const CartaoSaldo({
    super.key,
    required this.saldo,
    required this.ganhos,
    required this.kgEconomizados,
  });

  @override
  Widget build(BuildContext context) {
    final formatar = LogicaRecompensas.formatar;
    final progresso =
        ganhos > 0 ? LogicaRecompensas.progresso(saldo, ganhos) : 0.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: EstiloRecompensas.gradienteSaldo,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.eco, color: EstiloRecompensas.verde, size: 18),
            const SizedBox(width: 6),
            Text('Seu Saldo Verde', style: _textoDoCartao),
          ]),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              '${formatar(saldo)} CO₂Coins',
              key: ValueKey(saldo),
              style: EstiloRecompensas.fonte(
                cor: EstiloRecompensas.verde,
                tamanho: 30,
                peso: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Disponível do que ganhou no mês', style: _textoDoCartao),
              Text(
                '${formatar(saldo)} / ${formatar(ganhos)}',
                style: _textoDoCartao,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progresso),
              duration: const Duration(milliseconds: 700),
              builder: (_, valor, _) => LinearProgressIndicator(
                value: valor,
                minHeight: 10,
                backgroundColor: EstiloRecompensas.verde.withAlpha(40),
                color: EstiloRecompensas.verde,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ganhos > 0
                ? '${kgEconomizados.toStringAsFixed(1)} kg de CO₂ abaixo do seu limite este mês'
                : 'Fique abaixo do limite este mês para ganhar CO₂Coins',
            style: _textoDoCartao,
          ),
        ],
      ),
    );
  }
}

final _textoDoCartao = EstiloRecompensas.fonte(cor: EstiloRecompensas.verde);

/// Campo de busca das lojas, com botão de limpar.
class CampoBusca extends StatelessWidget {
  final TextEditingController controlador;
  final ValueChanged<String> aoAlterar;

  const CampoBusca({
    super.key,
    required this.controlador,
    required this.aoAlterar,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controlador,
      builder: (_, valor, _) => TextField(
        controller: controlador,
        onChanged: aoAlterar,
        style: EstiloRecompensas.fonte(),
        decoration: InputDecoration(
          hintText: 'Pesquisar lojas ou descontos...',
          hintStyle: EstiloRecompensas.legenda,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: valor.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Limpar busca',
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    controlador.clear();
                    aoAlterar('');
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
