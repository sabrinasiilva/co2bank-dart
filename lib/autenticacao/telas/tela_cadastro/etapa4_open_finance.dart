import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../nucleo/cores_app.dart';
import '../../../compartilhado/widgets/botao_primario.dart';
import '../../../open_finance/bancos_open_finance.dart';
import '../../../nucleo/tipografia.dart';

class Etapa4OpenFinance extends StatelessWidget {
  final Set<String> bancosConectados;
  final void Function(String) aoAlternarBanco;
  final VoidCallback aoContinuar;

  const Etapa4OpenFinance({
    super.key,
    required this.bancosConectados,
    required this.aoAlternarBanco,
    required this.aoContinuar,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titulo(),
          const SizedBox(height: 12),
          _caixaInfo(),
          const SizedBox(height: 20),
          Text('Selecione seus bancos',
              style: GoogleFonts.outfit(
                  fontSize: Tipografia.corpo,
                  fontWeight: FontWeight.w500,
                  color: CoresApp.textPrimary)),
          const SizedBox(height: 12),
          ...bancosOpenFinance.map(_cartaoBanco),
          const SizedBox(height: 8),
          BotaoPrimario(
            rotulo:
                bancosConectados.isEmpty ? 'Conectar depois' : 'Continuar',
            aoTocar: aoContinuar,
          ),
        ],
      ),
    );
  }

  Widget _titulo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Open Finance',
            style: GoogleFonts.outfit(
                fontSize: Tipografia.tituloSecao,
                fontWeight: FontWeight.bold,
                color: CoresApp.textPrimary)),
        const SizedBox(height: 4),
        Text('Etapa 4 de 5',
            style: GoogleFonts.outfit(
                fontSize: Tipografia.corpo, color: CoresApp.textSecondary)),
      ],
    );
  }

  Widget _caixaInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CoresApp.primaryMuted.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: CoresApp.primaryMuted.withValues(alpha: 0.5)),
      ),
      child: Text(
        'O Open Finance permite que o CO2Bank leia seus dados de compras diretamente do seu banco, sem precisar digitar nada. O acesso é só de leitura: nunca movemos o seu dinheiro.',
        style: GoogleFonts.outfit(
            fontSize: Tipografia.corpo, color: CoresApp.dark, height: 1.5),
      ),
    );
  }

  Widget _cartaoBanco(BancoOpenFinance banco) {
    final selecionado = bancosConectados.contains(banco.id);
    return GestureDetector(
      onTap: () => aoAlternarBanco(banco.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selecionado ? CoresApp.dark : CoresApp.border,
              width: selecionado ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: banco.cor.withValues(alpha: 0.1),
                  shape: BoxShape.circle),
              child: Icon(banco.icone, size: 18, color: banco.cor),
            ),
            const SizedBox(width: 12),
            Text(banco.nome,
                style: GoogleFonts.outfit(
                    fontSize: Tipografia.destaque,
                    fontWeight: FontWeight.w500,
                    color: CoresApp.textPrimary)),
            const Spacer(),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: selecionado
                    ? CoresApp.dark
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                    color: selecionado
                        ? CoresApp.dark
                        : CoresApp.border),
              ),
              child: selecionado
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
