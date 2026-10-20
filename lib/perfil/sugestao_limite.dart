import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../nucleo/cores_app.dart';
import '../transacoes/servico/servico_transacao.dart';

// Mesma faixa do controle deslizante do limite no cadastro.
const limiteMinimoKg = 50.0;
const limiteMaximoKg = 500.0;

class SugestaoLimite {
  final double mediaKg;
  final double sugeridoKg;
  final int mesesConsiderados;

  const SugestaoLimite({
    required this.mediaKg,
    required this.sugeridoKg,
    required this.mesesConsiderados,
  });
}

/// Sugere um limite 10% abaixo da média dos últimos 3 meses completos (o mês
/// atual fica de fora porque ainda está pela metade). Devolve nulo quando não
/// há histórico suficiente.
Future<SugestaoLimite?> calcularSugestaoLimite() async {
  final agora = DateTime.now();
  final mesPassado = DateTime(agora.year, agora.month - 1);
  final servico = await ServicoTransacao.autenticado();
  final meses = await servico.resumosDosUltimosMeses(
    mes: mesPassado.month,
    ano: mesPassado.year,
    quantidade: 3,
  );
  return sugerirLimitePeloHistorico(meses);
}

/// Regra da sugestão, separada da API para dar para testar. Meses sem nenhuma
/// compra (ou que não carregaram) não entram na média.
SugestaoLimite? sugerirLimitePeloHistorico(Iterable<ResumoDoMes> meses) {
  final totais = meses
      .map((m) => m.resumo)
      .whereType<ResumoMensal>()
      .where((r) => r.quantidadeTransacoes > 0)
      .map((r) => r.totalCo2Kg)
      .toList();
  if (totais.isEmpty) return null;

  final media = totais.reduce((a, b) => a + b) / totais.length;
  // Arredonda para dezenas, igual aos passos do controle deslizante.
  final sugerido = ((media * 0.9) / 10).round() * 10.0;
  return SugestaoLimite(
    mediaKg: media,
    sugeridoKg: sugerido.clamp(limiteMinimoKg, limiteMaximoKg),
    mesesConsiderados: totais.length,
  );
}

/// Card com a sugestão de limite. Na tela de edição de perfil, passe
/// [aoAplicar] para mostrar o botão que usa o valor sugerido.
class CartaoSugestaoLimite extends StatelessWidget {
  final SugestaoLimite sugestao;
  final double limiteAtualKg;
  final ValueChanged<double>? aoAplicar;

  const CartaoSugestaoLimite({
    super.key,
    required this.sugestao,
    required this.limiteAtualKg,
    this.aoAplicar,
  });

  @override
  Widget build(BuildContext context) {
    final sugerido = sugestao.sugeridoKg.toStringAsFixed(0);
    final media = sugestao.mediaKg.toStringAsFixed(0);
    final periodo = sugestao.mesesConsiderados == 1
        ? 'do último mês'
        : 'dos últimos ${sugestao.mesesConsiderados} meses';
    final jaEstaAbaixo = limiteAtualKg <= sugestao.sugeridoKg;
    // A sugestão pode ter sido levada ao mínimo ou ao máximo do app; aí ela
    // já não é "10% abaixo da média" e o texto precisa dizer isso.
    final bruto = ((sugestao.mediaKg * 0.9) / 10).round() * 10.0;
    final String explicacao;
    if (jaEstaAbaixo) {
      explicacao = limiteAtualKg < sugestao.mediaKg
          ? 'Ele está abaixo da sua média $periodo ($media kg). Continue assim!'
          : 'Sua média $periodo foi de $media kg, dentro do seu limite. Continue assim!';
    } else if (bruto < limiteMinimoKg) {
      explicacao = 'Sua média $periodo foi de $media kg. $sugerido kg é o menor limite do app.';
    } else if (bruto > limiteMaximoKg) {
      explicacao = 'Sua média $periodo foi de $media kg. $sugerido kg é o maior limite do app.';
    } else {
      explicacao = '10% abaixo da sua média $periodo, que foi de $media kg.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CoresApp.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CoresApp.primary.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            size: 22,
            color: CoresApp.brandText,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  jaEstaAbaixo
                      ? 'Seu limite já é um bom desafio'
                      : 'Sugestão: $sugerido kg/mês',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: CoresApp.brandText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  explicacao,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: CoresApp.brandText,
                    height: 1.35,
                  ),
                ),
                if (aoAplicar != null && !jaEstaAbaixo) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                      foregroundColor: CoresApp.brandText,
                    ),
                    onPressed: () => aoAplicar!(sugestao.sugeridoKg),
                    child: Text(
                      'Usar $sugerido kg',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
