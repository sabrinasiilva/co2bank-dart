import 'package:flutter/material.dart';

import '../../nucleo/cores_app.dart';

enum TipoAviso { sucesso, erro, info }

/// Aviso curto na parte de baixo da tela, no mesmo visual em todo o app:
/// cartão escuro arredondado, ícone colorido conforme o tipo e a fonte Outfit.
/// Esconde o aviso anterior para as mensagens não se empilharem.
void mostrarAviso(
  BuildContext context,
  String mensagem, {
  TipoAviso tipo = TipoAviso.info,
  SnackBarAction? acao,
}) {
  final (icone, cor) = switch (tipo) {
    TipoAviso.sucesso => (Icons.check_rounded, CoresApp.primary),
    TipoAviso.erro => (Icons.priority_high_rounded, CoresApp.accentWarm),
    TipoAviso.info => (Icons.eco_rounded, CoresApp.primaryMuted),
  };

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: CoresApp.textPrimary,
        elevation: 6,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
              child: Icon(icone, size: 18, color: CoresApp.textPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensagem,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
        action: acao == null
            ? null
            : SnackBarAction(
                label: acao.label,
                onPressed: acao.onPressed,
                textColor: CoresApp.primary,
              ),
      ),
    );
}
