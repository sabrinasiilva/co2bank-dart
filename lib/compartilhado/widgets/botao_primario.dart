import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../nucleo/cores_app.dart';

class BotaoPrimario extends StatelessWidget {
  final String rotulo;
  final VoidCallback? aoTocar;
  final bool carregando;

  const BotaoPrimario({
    super.key,
    required this.rotulo,
    required this.aoTocar,
    this.carregando = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: carregando ? null : aoTocar,
        style: ElevatedButton.styleFrom(
          backgroundColor: CoresApp.darkGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: CoresApp.border,
          disabledForegroundColor: CoresApp.textSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: carregando
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: CoresApp.textSecondary,
                ),
              )
            : Text(
                rotulo,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
