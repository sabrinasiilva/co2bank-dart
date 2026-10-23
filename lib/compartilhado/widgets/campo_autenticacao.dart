import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../nucleo/cores_app.dart';
import '../../nucleo/tipografia.dart';

class CampoAutenticacao extends StatelessWidget {
  final TextEditingController controlador;
  final String rotulo;
  final String dica;
  final IconData icone;
  final String? erro;
  final bool oculto;
  final Widget? sufixo;
  final TextInputType? tipoTeclado;
  final List<TextInputFormatter>? formatadores;
  final void Function(String)? aoAlterar;

  const CampoAutenticacao({
    super.key,
    required this.controlador,
    required this.rotulo,
    required this.dica,
    required this.icone,
    this.erro,
    this.oculto = false,
    this.sufixo,
    this.tipoTeclado,
    this.formatadores,
    this.aoAlterar,
  });

  @override
  Widget build(BuildContext context) {
    final temErro = erro != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: GoogleFonts.outfit(
              fontSize: Tipografia.corpo,
              fontWeight: FontWeight.w500,
              color: CoresApp.textPrimary),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controlador,
          obscureText: oculto,
          onChanged: aoAlterar,
          keyboardType: tipoTeclado,
          inputFormatters: formatadores,
          style:
              GoogleFonts.outfit(fontSize: Tipografia.destaque, color: CoresApp.textPrimary),
          decoration: InputDecoration(
            hintText: dica,
            hintStyle: GoogleFonts.outfit(color: CoresApp.textSecondary),
            prefixIcon: Icon(icone,
                size: 20,
                color: temErro ? Colors.red : CoresApp.textSecondary),
            suffixIcon: sufixo,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: CoresApp.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: temErro ? Colors.red : CoresApp.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: temErro ? Colors.red : CoresApp.mintGreen,
                    width: 1.5)),
          ),
        ),
        if (temErro)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(erro!,
                style: GoogleFonts.outfit(fontSize: Tipografia.legenda, color: Colors.red)),
          ),
      ],
    );
  }
}
