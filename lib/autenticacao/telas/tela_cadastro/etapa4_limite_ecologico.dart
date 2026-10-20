import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../nucleo/cores_app.dart';
import '../../../compartilhado/widgets/botao_primario.dart';

class Etapa4LimiteEcologico extends StatelessWidget {
  final double limiteCo2;
  final void Function(double) aoAlterarLimite;
  final VoidCallback aoContinuar;
  final bool carregando;
  final String? erro;

  const Etapa4LimiteEcologico({
    super.key,
    required this.limiteCo2,
    required this.aoAlterarLimite,
    required this.aoContinuar,
    this.carregando = false,
    this.erro,
  });

  String get _rotulo {
    if (limiteCo2 < 150) return 'Abaixo da média';
    if (limiteCo2 <= 250) return 'Na média brasileira';
    return 'Acima da média';
  }

  Color get _corRotulo {
    if (limiteCo2 < 150) return CoresApp.mintGreen;
    if (limiteCo2 <= 250) return CoresApp.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titulo(),
          const SizedBox(height: 12),
          Text(
            'Defina quanto CO2 você quer emitir por mês com suas compras. O app vai te avisar quando estiver chegando no limite.',
            style: GoogleFonts.outfit(
                fontSize: 14,
                color: CoresApp.textSecondary,
                height: 1.5),
          ),
          const SizedBox(height: 36),
          Center(
            child: Column(
              children: [
                Text('${limiteCo2.toInt()} kg',
                    style: GoogleFonts.outfit(
                        fontSize: 52,
                        fontWeight: FontWeight.bold,
                        color: CoresApp.dark)),
                Text('CO2 por mês',
                    style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: CoresApp.textSecondary)),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                      color: _corRotulo.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(_rotulo,
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _corRotulo)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: CoresApp.dark,
              inactiveTrackColor: CoresApp.border,
              thumbColor: CoresApp.dark,
              overlayColor: CoresApp.dark.withValues(alpha: 0.1),
              trackHeight: 4,
            ),
            child: Slider(
                value: limiteCo2,
                min: 50,
                max: 500,
                divisions: 90,
                onChanged: aoAlterarLimite),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('50 kg',
                  style: GoogleFonts.outfit(
                      fontSize: 12, color: CoresApp.textSecondary)),
              Text('500 kg',
                  style: GoogleFonts.outfit(
                      fontSize: 12, color: CoresApp.textSecondary)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: CoresApp.border.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12)),
            child: Text(
              'A média brasileira de emissão por consumo é de aproximadamente 200 kg CO2 por mês.',
              style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: CoresApp.textSecondary,
                  height: 1.5),
            ),
          ),
          const SizedBox(height: 32),
          if (erro != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(erro!,
                  style:
                      GoogleFonts.outfit(fontSize: 13, color: Colors.red),
                  textAlign: TextAlign.center),
            ),
          carregando
              ? const Center(
                  child: CircularProgressIndicator(
                      color: CoresApp.primary))
              : BotaoPrimario(
                  rotulo: 'Finalizar', aoTocar: aoContinuar),
        ],
      ),
    );
  }

  Widget _titulo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Limite ecológico',
            style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: CoresApp.textPrimary)),
        const SizedBox(height: 4),
        Text('Etapa 5 de 5',
            style: GoogleFonts.outfit(
                fontSize: 13, color: CoresApp.textSecondary)),
      ],
    );
  }
}
