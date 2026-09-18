import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/app_colors.dart';
import '../../widgets/primary_button.dart';

class Step3OpenFinance extends StatelessWidget {
  final Set<String> connectedBanks;
  final void Function(String) onBankToggled;
  final VoidCallback onContinue;

  const Step3OpenFinance({
    super.key,
    required this.connectedBanks,
    required this.onBankToggled,
    required this.onContinue,
  });

  static const _banks = [
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
          _title(),
          const SizedBox(height: 12),
          _infoBox(),
          const SizedBox(height: 20),
          Text('Selecione seus bancos',
              style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          ..._banks.map((bank) => _bankCard(bank)),
          const SizedBox(height: 8),
          PrimaryButton(
            label: connectedBanks.isEmpty ? 'Conectar depois' : 'Continuar',
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }

  Widget _title() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Open Finance',
            style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text('Etapa 4 de 5',
            style: GoogleFonts.outfit(
                fontSize: 13, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _infoBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryMuted.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryMuted.withOpacity(0.5)),
      ),
      child: Text(
        'O Open Finance permite que o CO2Bank leia seus dados de compras diretamente do seu banco, sem precisar digitar nada. O acesso é só leitura — nunca movemos seu dinheiro.',
        style: GoogleFonts.outfit(
            fontSize: 13, color: AppColors.darkGreen, height: 1.5),
      ),
    );
  }

  Widget _bankCard((String, IconData, Color) bank) {
    final selected = connectedBanks.contains(bank.$1);
    return GestureDetector(
      onTap: () => onBankToggled(bank.$1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? AppColors.darkGreen : AppColors.border,
              width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: bank.$3.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(bank.$2, size: 18, color: bank.$3),
            ),
            const SizedBox(width: 12),
            Text(bank.$1,
                style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary)),
            const Spacer(),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: selected ? AppColors.darkGreen : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                    color: selected
                        ? AppColors.darkGreen
                        : AppColors.border),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
