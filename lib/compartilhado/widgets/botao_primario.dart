import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../nucleo/cores_app.dart';

class BotaoPrimario extends StatelessWidget {
  final String rotulo;
  final VoidCallback aoTocar;

  const BotaoPrimario({super.key, required this.rotulo, required this.aoTocar});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: aoTocar,
        style: ElevatedButton.styleFrom(
          backgroundColor: CoresApp.darkGreen,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: Text(rotulo,
            style: GoogleFonts.outfit(
                fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
