import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../nucleo/cores_app.dart';
import '../transacoes/servico/servico_transacao.dart';

// Estimativas comuns em materiais de divulgação sobre carbono, usadas só para
// deixar o número mais concreto. Na tela aparecem sempre como "cerca de".
const _kgAbsorvidosPorArvorePorMes = 22 / 12; // ~22 kg de CO2 por árvore ao ano
const _kgPorKmDeCarro = 0.12; // carro a gasolina, ~120 g de CO2 por km

const _nomesMeses = [
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

class CartaoImpacto extends StatelessWidget {
  final ResumoMensal resumo;

  /// CO₂Coins ganhos no mês. Só existe para o mês atual; nos outros fica nulo.
  final int? coinsDoMes;

  const CartaoImpacto({super.key, required this.resumo, this.coinsDoMes});

  @override
  Widget build(BuildContext context) {
    final diferenca = resumo.limiteKg - resumo.totalCo2Kg;
    final dentroDoLimite = diferenca >= 0;
    final mes = _nomesMeses[resumo.mes];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: CoresApp.brandGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.public_rounded,
                size: 18,
                color: CoresApp.brandText,
              ),
              const SizedBox(width: 6),
              Text(
                'Seu impacto em $mes',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: CoresApp.brandText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            dentroDoLimite
                ? 'Você emitiu ${diferenca.toStringAsFixed(1).replaceAll('.', ',')} kg a menos que o seu limite'
                : 'Você passou ${(-diferenca).toStringAsFixed(1).replaceAll('.', ',')} kg do seu limite',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: CoresApp.brandText,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          ..._equivalencias(diferenca.abs(), dentroDoLimite),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: CoresApp.surface.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Objetivos de Desenvolvimento Sustentável',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: CoresApp.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _LinhaOds(
                  numero: 12,
                  cor: _CoresOds.ods12,
                  titulo: 'Consumo e produção responsáveis',
                  texto: resumo.quantidadeTransacoes == 1
                      ? 'Você acompanhou o CO2 de 1 compra'
                      : 'Você acompanhou o CO2 de ${resumo.quantidadeTransacoes} compras',
                ),
                const SizedBox(height: 10),
                _LinhaOds(
                  numero: 13,
                  cor: _CoresOds.ods13,
                  titulo: 'Ação contra a mudança global do clima',
                  texto: dentroDoLimite
                      ? 'Ficou dentro do limite ecológico (${resumo.percentualUsado.toStringAsFixed(0)}% usado)'
                      : 'Usou ${resumo.percentualUsado.toStringAsFixed(0)}% do limite. No próximo mês dá para virar o jogo',
                ),
                const SizedBox(height: 10),
                _LinhaOds(
                  numero: 17,
                  cor: _CoresOds.ods17,
                  titulo: 'Parcerias e meios de implementação',
                  texto: switch (coinsDoMes) {
                    null =>
                      'O CO2 que você economiza vira desconto em lojas parceiras',
                    0 =>
                      'Fique abaixo do limite para ganhar CO₂Coins e trocar por desconto em parceiros',
                    final coins =>
                      'Ganhou $coins CO₂Coins para trocar por desconto em parceiros',
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _equivalencias(double kg, bool dentroDoLimite) {
    if (kg < 0.5) return const [];
    final arvores = (kg / _kgAbsorvidosPorArvorePorMes).round();
    final km = (kg / _kgPorKmDeCarro).round();
    return [
      if (dentroDoLimite && arvores > 0)
        _Equivalencia(
          icone: Icons.park_rounded,
          texto: arvores == 1
              ? 'Cerca do que 1 árvore absorve em um mês'
              : 'Cerca do que $arvores árvores absorvem em um mês',
        ),
      _Equivalencia(
        icone: Icons.directions_car_rounded,
        texto: dentroDoLimite
            ? 'O mesmo que deixar de rodar cerca de $km km de carro'
            : 'O mesmo que rodar cerca de $km km a mais de carro',
      ),
    ];
  }
}

// Cores oficiais de cada ODS, definidas pela ONU. Por serem a identidade das
// ODS, não entram na paleta do app.
abstract final class _CoresOds {
  static const ods12 = Color(0xFFBF8B2E);
  static const ods13 = Color(0xFF3F7E44);
  static const ods17 = Color(0xFF19486A);
}

class _Equivalencia extends StatelessWidget {
  final IconData icone;
  final String texto;

  const _Equivalencia({required this.icone, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icone, size: 18, color: CoresApp.brandText),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: CoresApp.brandText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinhaOds extends StatelessWidget {
  final int numero;
  final Color cor;
  final String titulo;
  final String texto;

  const _LinhaOds({
    required this.numero,
    required this.cor,
    required this.titulo,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: cor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$numero',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ODS $numero · $titulo',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: CoresApp.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                texto,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: CoresApp.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
