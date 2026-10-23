import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../nucleo/cores_app.dart';
import '../../../compartilhado/widgets/botao_primario.dart';
import '../../../nucleo/tipografia.dart';

class Etapa6Concluido extends StatelessWidget {
  final VoidCallback aoIniciar;

  const Etapa6Concluido({super.key, required this.aoIniciar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                  color: CoresApp.dark, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded,
                  size: 52, color: Colors.white),
            ),
            const SizedBox(height: 28),
            Text('Tudo pronto!',
                style: GoogleFonts.outfit(
                    fontSize: Tipografia.titulo,
                    fontWeight: FontWeight.bold,
                    color: CoresApp.textPrimary)),
            const SizedBox(height: 8),
            Text(
              'Sua conta está criada. Vamos começar a cuidar do seu bolso e do planeta.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                  fontSize: Tipografia.destaque,
                  color: CoresApp.textSecondary,
                  height: 1.5),
            ),
            const SizedBox(height: 40),
            BotaoPrimario(rotulo: 'Começar', aoTocar: aoIniciar),
          ],
        ),
      ),
    );
  }
}
