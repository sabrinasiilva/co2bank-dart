import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../nucleo/cores_app.dart';
import '../../../compartilhado/widgets/botao_primario.dart';

class Etapa3OpenFinance extends StatelessWidget {
  final Set<String> bancosConectados;
  final void Function(String) aoAlternarBanco;
  final VoidCallback aoContinuar;

  const Etapa3OpenFinance({
    super.key,
    required this.bancosConectados,
    required this.aoAlternarBanco,
    required this.aoContinuar,
  });

  static const _bancos = [
    ('Nubank', Icons.credit_card, Color(0xFF8A05BE)),
    ('Itaú', Icons.account_balance, Color(0xFFEC7000)),
    ('Bradesco', Icons.account_balance, Color(0xFFCC092F)),
    ('C6 Bank', Icons.credit_card, Color(0xFF242424)),
    ('Inter', Icons.account_balance, Color(0xFFFF6600)),
    ('Santander', Icons.account_balance, Color(0xFFEC0000)),
  ];

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
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: CoresApp.textPrimary)),
          const SizedBox(height: 12),
          ..._bancos.map((banco) => _cartaoBanco(banco)),
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
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: CoresApp.textPrimary)),
        const SizedBox(height: 4),
        Text('Etapa 4 de 5',
            style: GoogleFonts.outfit(
                fontSize: 13, color: CoresApp.textSecondary)),
      ],
    );
  }

  Widget _caixaInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CoresApp.primaryMuted.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: CoresApp.primaryMuted.withOpacity(0.5)),
      ),
      child: Text(
        'O Open Finance permite que o CO2Bank leia seus dados de compras diretamente do seu banco, sem precisar digitar nada. O acesso é só leitura — nunca movemos seu dinheiro.',
        style: GoogleFonts.outfit(
            fontSize: 13, color: CoresApp.darkGreen, height: 1.5),
      ),
    );
  }

  Widget _cartaoBanco((String, IconData, Color) banco) {
    final selecionado = bancosConectados.contains(banco.$1);
    return GestureDetector(
      onTap: () => aoAlternarBanco(banco.$1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selecionado ? CoresApp.darkGreen : CoresApp.border,
              width: selecionado ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: banco.$3.withOpacity(0.1),
                  shape: BoxShape.circle),
              child: Icon(banco.$2, size: 18, color: banco.$3),
            ),
            const SizedBox(width: 12),
            Text(banco.$1,
                style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: CoresApp.textPrimary)),
            const Spacer(),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: selecionado
                    ? CoresApp.darkGreen
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                    color: selecionado
                        ? CoresApp.darkGreen
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
