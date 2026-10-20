import 'package:flutter/material.dart';

import '../../nucleo/cores_app.dart';

class IndicadorEtapa extends StatelessWidget {
  final int etapaAtual;
  final int totalEtapas;

  const IndicadorEtapa(
      {super.key, required this.etapaAtual, required this.totalEtapas});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalEtapas, (index) {
        final concluido = index < etapaAtual;
        final atual = index == etapaAtual;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 4,
                  decoration: BoxDecoration(
                    color: concluido || atual
                        ? CoresApp.dark
                        : CoresApp.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (index < totalEtapas - 1) const SizedBox(width: 4),
            ],
          ),
        );
      }),
    );
  }
}
