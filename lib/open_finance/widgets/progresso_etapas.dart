import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../nucleo/cores_app.dart';

/// Lista vertical de etapas: as anteriores a [etapaAtual] aparecem concluídas,
/// a atual com indicador de carregamento e as seguintes em cinza.
/// Quando [concluido] é true, todas aparecem concluídas.
class ProgressoEtapas extends StatelessWidget {
  final List<String> etapas;
  final int etapaAtual;
  final bool concluido;

  const ProgressoEtapas({
    super.key,
    required this.etapas,
    required this.etapaAtual,
    this.concluido = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < etapas.length; i++)
          _LinhaEtapa(
            texto: etapas[i],
            estado: concluido || i < etapaAtual
                ? _EstadoEtapa.feita
                : i == etapaAtual
                ? _EstadoEtapa.atual
                : _EstadoEtapa.pendente,
            ultima: i == etapas.length - 1,
          ),
      ],
    );
  }
}

enum _EstadoEtapa { feita, atual, pendente }

class _LinhaEtapa extends StatelessWidget {
  final String texto;
  final _EstadoEtapa estado;
  final bool ultima;

  const _LinhaEtapa({
    required this.texto,
    required this.estado,
    required this.ultima,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _indicador(),
              ),
              if (!ultima)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: estado == _EstadoEtapa.feita
                        ? CoresApp.primary
                        : CoresApp.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 2, bottom: ultima ? 0 : 18),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: estado == _EstadoEtapa.atual
                      ? FontWeight.w600
                      : FontWeight.w500,
                  color: estado == _EstadoEtapa.pendente
                      ? CoresApp.textSecondary
                      : CoresApp.textPrimary,
                ),
                child: Text(texto),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _indicador() {
    switch (estado) {
      case _EstadoEtapa.feita:
        return Container(
          key: const ValueKey('feita'),
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: CoresApp.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 16,
            color: CoresApp.dark,
          ),
        );
      case _EstadoEtapa.atual:
        return const SizedBox(
          key: ValueKey('atual'),
          width: 24,
          height: 24,
          child: Padding(
            padding: EdgeInsets.all(2),
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: CoresApp.darkGreen,
            ),
          ),
        );
      case _EstadoEtapa.pendente:
        return Container(
          key: const ValueKey('pendente'),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: CoresApp.border, width: 2),
          ),
        );
    }
  }
}

/// Mostra as etapas uma a uma, com um intervalo mínimo entre elas, e só
/// conclui depois que [tarefa] terminar. O intervalo existe para a pessoa
/// conseguir acompanhar o que está acontecendo mesmo quando a API responde rápido.
Future<T> executarComEtapas<T>({
  required Future<T> tarefa,
  required int totalEtapas,
  required void Function(int etapa) aoAvancar,
  Duration intervalo = const Duration(milliseconds: 900),
}) async {
  for (var i = 0; i < totalEtapas - 1; i++) {
    aoAvancar(i);
    await Future<void>.delayed(intervalo);
  }
  aoAvancar(totalEtapas - 1);
  final resultado = await tarefa;
  await Future<void>.delayed(const Duration(milliseconds: 500));
  return resultado;
}
