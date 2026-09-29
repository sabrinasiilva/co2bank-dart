import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../nucleo/cores_app.dart';
import '../../../compartilhado/widgets/campo_autenticacao.dart';
import '../../../compartilhado/widgets/botao_primario.dart';

class Etapa2Acesso extends StatelessWidget {
  final TextEditingController controladorEmail;
  final TextEditingController controladorSenha;
  final TextEditingController controladorConfirmacao;
  final bool ocultarSenha;
  final bool ocultarConfirmacao;
  final double forcaSenha;
  final Color corForca;
  final String rotuloForca;
  final Map<String, String?> erros;
  final VoidCallback aoContinuar;
  final VoidCallback aoAlternarSenha;
  final VoidCallback aoAlternarConfirmacao;
  final void Function(String) aoAlterarSenha;
  final void Function(String) aoAlterarConfirmacao;

  const Etapa2Acesso({
    super.key,
    required this.controladorEmail,
    required this.controladorSenha,
    required this.controladorConfirmacao,
    required this.ocultarSenha,
    required this.ocultarConfirmacao,
    required this.forcaSenha,
    required this.corForca,
    required this.rotuloForca,
    required this.erros,
    required this.aoContinuar,
    required this.aoAlternarSenha,
    required this.aoAlternarConfirmacao,
    required this.aoAlterarSenha,
    required this.aoAlterarConfirmacao,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titulo(),
          const SizedBox(height: 28),
          CampoAutenticacao(
            controlador: controladorEmail,
            rotulo: 'E-mail',
            dica: 'seu@email.com',
            icone: Icons.email_outlined,
            tipoTeclado: TextInputType.emailAddress,
            erro: erros['email'],
          ),
          const SizedBox(height: 16),
          CampoAutenticacao(
            controlador: controladorSenha,
            rotulo: 'Senha',
            dica: '••••••••',
            icone: Icons.lock_outline,
            oculto: ocultarSenha,
            erro: erros['password'],
            aoAlterar: aoAlterarSenha,
            sufixo: _botaoOlho(ocultarSenha, aoAlternarSenha),
          ),
          if (controladorSenha.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: forcaSenha,
                      backgroundColor: CoresApp.border,
                      valueColor: AlwaysStoppedAnimation(corForca),
                      minHeight: 4,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(rotuloForca,
                    style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: corForca,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ],
          const SizedBox(height: 16),
          CampoAutenticacao(
            controlador: controladorConfirmacao,
            rotulo: 'Confirmar senha',
            dica: '••••••••',
            icone: Icons.lock_outline,
            oculto: ocultarConfirmacao,
            erro: erros['confirm'],
            aoAlterar: aoAlterarConfirmacao,
            sufixo: _botaoOlho(ocultarConfirmacao, aoAlternarConfirmacao),
          ),
          const SizedBox(height: 32),
          BotaoPrimario(rotulo: 'Continuar', aoTocar: aoContinuar),
        ],
      ),
    );
  }

  Widget _titulo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Criar acesso',
            style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: CoresApp.textPrimary)),
        const SizedBox(height: 4),
        Text('Etapa 2 de 5',
            style: GoogleFonts.outfit(
                fontSize: 13, color: CoresApp.textSecondary)),
      ],
    );
  }

  Widget _botaoOlho(bool oculto, VoidCallback aoTocar) {
    return IconButton(
      icon: Icon(
          oculto
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: CoresApp.textSecondary,
          size: 20),
      onPressed: aoTocar,
    );
  }
}
