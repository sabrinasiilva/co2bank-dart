import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../nucleo/cores_app.dart';
import '../bancos_open_finance.dart';
import '../../nucleo/tipografia.dart';

class SeloOpenFinance extends StatelessWidget {
  final String? idBanco;

  const SeloOpenFinance({super.key, required this.idBanco});

  @override
  Widget build(BuildContext context) {
    final banco = bancoPorId(idBanco);
    final cor = banco?.cor ?? CoresApp.gray;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sync_alt_rounded, size: 11, color: cor),
            const SizedBox(width: 4),
            Text(
              'via ${banco?.nome ?? 'Open Finance'}',
              style: GoogleFonts.outfit(
                fontSize: Tipografia.minimo,
                fontWeight: FontWeight.w600,
                color: cor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
