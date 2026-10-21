import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../nucleo/cores_app.dart';

/// Estado de erro das telas que carregam dados da API: explica o que houve e
/// oferece tentar de novo, em vez de mostrar a tela vazia como se não houvesse
/// nada para exibir.
class AvisoErroCarregamento extends StatelessWidget {
  final VoidCallback aoTentarNovamente;
  final String titulo;

  const AvisoErroCarregamento({
    super.key,
    required this.aoTentarNovamente,
    this.titulo = 'Não foi possível carregar',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 44, color: CoresApp.gray),
          const SizedBox(height: 12),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: CoresApp.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Confira sua conexão com a internet e tente de novo.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: CoresApp.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: aoTentarNovamente,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(
              'Tentar novamente',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: CoresApp.dark,
              side: const BorderSide(color: CoresApp.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
