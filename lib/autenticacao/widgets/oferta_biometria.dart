import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../compartilhado/widgets/botao_primario.dart';
import '../../nucleo/cores_app.dart';
import '../servico/acesso_biometrico.dart';
import '../../nucleo/tipografia.dart';

/// Depois de entrar com a senha (ou de criar a conta), pergunta uma vez se a
/// pessoa quer usar a biometria do celular nas próximas vezes.
/// Não pergunta de novo se ela já respondeu, se o celular não tem biometria
/// ou se ela já está ativa.
Future<void> oferecerBiometria(
  BuildContext context, {
  required String email,
  required String senha,
}) async {
  if (await AcessoBiometrico.jaPerguntou()) return;
  if (await AcessoBiometrico.ativa()) return;
  if (!await AcessoBiometrico.disponivel()) return;
  if (!context.mounted) return;

  final quer = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: CoresApp.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (contexto) => const _ConteudoOferta(),
  );
  await AcessoBiometrico.marcarPerguntado();
  if (quer == true) {
    await AcessoBiometrico.ativar(email: email, senha: senha);
  }
}

class _ConteudoOferta extends StatelessWidget {
  const _ConteudoOferta();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: CoresApp.primary.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.fingerprint_rounded,
                size: 36,
                color: CoresApp.brandText,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Entrar com biometria?',
              style: GoogleFonts.outfit(
                fontSize: Tipografia.tituloSecao,
                fontWeight: FontWeight.bold,
                color: CoresApp.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Na próxima vez, é só usar a digital, o rosto ou o PIN do seu '
              'celular. Sua senha fica guardada com segurança no próprio aparelho.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: Tipografia.corpo,
                color: CoresApp.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            BotaoPrimario(
              rotulo: 'Ativar biometria',
              aoTocar: () => Navigator.pop(context, true),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Agora não',
                style: GoogleFonts.outfit(
                  fontSize: Tipografia.corpo,
                  color: CoresApp.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
