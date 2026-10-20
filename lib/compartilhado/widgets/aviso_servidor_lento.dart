import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../nucleo/cliente_api.dart';
import '../../nucleo/cores_app.dart';

/// Aviso leve no topo da tela enquanto alguma chamada à API está demorando.
/// Fica por cima do app inteiro (é usado no `builder` do MaterialApp), então
/// cobre o login, a primeira carga da Home e qualquer outra tela.
class AvisoServidorLento extends StatelessWidget {
  final Widget child;

  const AvisoServidorLento({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final topo = MediaQuery.paddingOf(context).top;

    return Stack(
      children: [
        child,
        Positioned(
          top: topo + 8,
          left: 16,
          right: 16,
          child: ValueListenableBuilder<bool>(
            valueListenable: ClienteApi.servidorDemorando,
            builder: (_, demorando, _) => IgnorePointer(
              ignoring: !demorando,
              child: AnimatedSlide(
                offset: demorando ? Offset.zero : const Offset(0, -0.4),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                child: AnimatedOpacity(
                  opacity: demorando ? 1 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: const _CartaoAviso(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CartaoAviso extends StatelessWidget {
  const _CartaoAviso();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CoresApp.surface,
      elevation: 4,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: CoresApp.dark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Conectando ao servidor… isso pode levar até um minuto na primeira vez',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: CoresApp.textPrimary,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
