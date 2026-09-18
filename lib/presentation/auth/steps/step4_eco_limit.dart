import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/app_colors.dart';
import '../../widgets/primary_button.dart';

class Step4EcoLimit extends StatelessWidget {
  final double co2Limit;
  final void Function(double) onLimitChanged;
  final VoidCallback onContinue;
  final bool loading;
  final String? error;

  const Step4EcoLimit({
    super.key,
    required this.co2Limit,
    required this.onLimitChanged,
    required this.onContinue,
    this.loading = false,
    this.error,
  });

  String get _label {
    if (co2Limit < 150) return 'Abaixo da média';
    if (co2Limit <= 250) return 'Na média brasileira';
    return 'Acima da média';
  }

  Color get _labelColor {
    if (co2Limit < 150) return AppColors.mintGreen;
    if (co2Limit <= 250) return AppColors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title(),
          const SizedBox(height: 12),
          Text(
            'Defina quanto CO2 você quer emitir por mês com suas compras. O app vai te avisar quando estiver chegando no limite.',
            style: GoogleFonts.outfit(
                fontSize: 14, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 36),
          Center(
            child: Column(
              children: [
                Text('${co2Limit.toInt()} kg',
                    style: GoogleFonts.outfit(
                        fontSize: 52,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGreen)),
                Text('CO2 por mês',
                    style: GoogleFonts.outfit(
                        fontSize: 14, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                      color: _labelColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(_label,
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _labelColor)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.darkGreen,
              inactiveTrackColor: AppColors.border,
              thumbColor: AppColors.darkGreen,
              overlayColor: AppColors.darkGreen.withOpacity(0.1),
              trackHeight: 4,
            ),
            child: Slider(
                value: co2Limit,
                min: 50,
                max: 500,
                divisions: 90,
                onChanged: onLimitChanged),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('50 kg',
                  style: GoogleFonts.outfit(
                      fontSize: 12, color: AppColors.textSecondary)),
              Text('500 kg',
                  style: GoogleFonts.outfit(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: AppColors.border.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12)),
            child: Text(
              'A média brasileira de emissão por consumo é de aproximadamente 200 kg CO2 por mês.',
              style: GoogleFonts.outfit(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
          ),
          const SizedBox(height: 32),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(error!,
                  style: GoogleFonts.outfit(fontSize: 13, color: Colors.red),
                  textAlign: TextAlign.center),
            ),
          loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.darkGreen))
              : PrimaryButton(label: 'Finalizar', onPressed: onContinue),
        ],
      ),
    );
  }

  Widget _title() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Limite ecológico',
            style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text('Etapa 5 de 5',
            style: GoogleFonts.outfit(
                fontSize: 13, color: AppColors.textSecondary)),
      ],
    );
  }
}
