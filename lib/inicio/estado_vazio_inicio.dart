import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../compartilhado/widgets/botao_primario.dart';
import '../nucleo/cores_app.dart';
import '../open_finance/tela_open_finance.dart';
import '../transacoes/telas/tela_nova_compra.dart';

/// Mostrado na aba Início quando o mês ainda não tem nenhuma compra:
/// convida a conectar o banco (ou lançar uma compra à mão).
class EstadoVazioInicio extends StatelessWidget {
  /// Chamado na volta do Open Finance ou de uma compra registrada,
  /// para a Home buscar os dados de novo.
  final VoidCallback aoAtualizar;

  const EstadoVazioInicio({super.key, required this.aoAtualizar});

  Future<void> _abrirOpenFinance(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TelaOpenFinance()),
    );
    if (context.mounted) aoAtualizar();
  }

  Future<void> _lancarCompra(BuildContext context) async {
    final registrou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const TelaNovaCompra()),
    );
    if (registrou == true && context.mounted) aoAtualizar();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
      decoration: BoxDecoration(
        color: CoresApp.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: CoresApp.primaryMuted.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_balance_rounded,
                size: 26, color: CoresApp.brandText),
          ),
          const SizedBox(height: 16),
          Text(
            'Conecte seu banco para começar',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: CoresApp.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Nenhuma compra este mês ainda. Pelo Open Finance elas chegam sozinhas, já com o CO2 calculado.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: CoresApp.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          BotaoPrimario(
            rotulo: 'Conectar meu banco',
            aoTocar: () => _abrirOpenFinance(context),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => _lancarCompra(context),
            style: TextButton.styleFrom(foregroundColor: CoresApp.textPrimary),
            child: Text(
              'Lançar uma compra manualmente',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
