import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../nucleo/cores_app.dart';
import '../../servico/servico_autenticacao.dart';
import '../../../compartilhado/widgets/campo_autenticacao.dart';
import '../../../compartilhado/widgets/botao_primario.dart';

enum _Etapa { email, codigo, novaSenha }

class TelaEsqueciSenha extends StatefulWidget {
  const TelaEsqueciSenha({super.key});

  @override
  State<TelaEsqueciSenha> createState() => _TelaEsqueciSenhaState();
}

class _TelaEsqueciSenhaState extends State<TelaEsqueciSenha> {
  final _servico = ServicoAutenticacao();

  _Etapa _etapa = _Etapa.email;
  bool _carregando = false;
  String? _erro;

  final _controladorEmail = TextEditingController();
  final _controladorCodigo = TextEditingController();
  final _controladorSenha = TextEditingController();
  final _controladorConfirmacao = TextEditingController();
  bool _ocultarSenha = true;
  bool _ocultarConfirmacao = true;

  @override
  void dispose() {
    _controladorEmail.dispose();
    _controladorCodigo.dispose();
    _controladorSenha.dispose();
    _controladorConfirmacao.dispose();
    super.dispose();
  }

  Future<void> _enviarCodigo() async {
    final email = _controladorEmail.text.trim();
    if (email.isEmpty) {
      setState(() => _erro = 'Informe seu e-mail');
      return;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      setState(() => _erro = 'E-mail inválido');
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
    });

    final resultado =
        await _servico.solicitarCodigoRecuperacao(email: email);

    setState(() => _carregando = false);

    switch (resultado) {
      case CodigoEnviado():
        setState(() => _etapa = _Etapa.codigo);
      case ErroSolicitacaoCodigo(:final mensagem):
        setState(() => _erro = mensagem);
      case ErroRedeSolicitacao():
        setState(() => _erro = 'Não foi possível conectar ao servidor');
    }
  }

  void _confirmarCodigo() {
    final codigo = _controladorCodigo.text.trim();
    if (codigo.isEmpty) {
      setState(() => _erro = 'Informe o código recebido por e-mail');
      return;
    }
    setState(() {
      _erro = null;
      _etapa = _Etapa.novaSenha;
    });
  }

  Future<void> _redefinirSenha() async {
    final senha = _controladorSenha.text;
    final confirmacao = _controladorConfirmacao.text;

    if (senha.length < 8) {
      setState(() => _erro = 'A senha deve ter pelo menos 8 caracteres');
      return;
    }
    if (senha != confirmacao) {
      setState(() => _erro = 'As senhas não coincidem');
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
    });

    final resultado = await _servico.redefinirSenha(
      tokenRedefinicao: _controladorCodigo.text.trim(),
      novaSenha: senha,
    );

    setState(() => _carregando = false);

    switch (resultado) {
      case SenhaRedefinida():
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Senha redefinida com sucesso!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      case CodigoInvalidoOuExpirado():
        setState(
            () => _erro = 'Código inválido ou expirado. Solicite um novo.');
      case ErroRedefinicao(:final mensagem):
        setState(() => _erro = mensagem);
      case ErroRedeRedefinicao():
        setState(() => _erro = 'Não foi possível conectar ao servidor');
    }
  }

  int get _indicePonto {
    switch (_etapa) {
      case _Etapa.email:
        return 0;
      case _Etapa.codigo:
        return 1;
      case _Etapa.novaSenha:
        return 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: CoresApp.dark,
      body: Stack(
        children: [
          Positioned(
            top: top + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            top: top + 56,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: CoresApp.primaryMuted.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: CoresApp.primaryMuted.withValues(alpha: 0.4),
                        width: 1.5),
                  ),
                  child: const Icon(Icons.lock_reset_rounded,
                      size: 34, color: CoresApp.primaryMuted),
                ),
                const SizedBox(height: 14),
                Text(
                  'Redefinir senha',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Verificação em 3 etapas',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 16),
                _PontosEtapa(indiceAtivo: _indicePonto),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: size.height * 0.60,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: CoresApp.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.05, 0),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: _construirConteudo(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirConteudo() {
    switch (_etapa) {
      case _Etapa.email:
        return _EtapaEmail(
          key: const ValueKey('email'),
          controlador: _controladorEmail,
          erro: _erro,
          carregando: _carregando,
          aoAvancar: _enviarCodigo,
        );
      case _Etapa.codigo:
        return _EtapaCodigo(
          key: const ValueKey('codigo'),
          controlador: _controladorCodigo,
          erro: _erro,
          aoAvancar: _confirmarCodigo,
        );
      case _Etapa.novaSenha:
        return _EtapaNovaSenha(
          key: const ValueKey('novaSenha'),
          controladorSenha: _controladorSenha,
          controladorConfirmacao: _controladorConfirmacao,
          ocultarSenha: _ocultarSenha,
          ocultarConfirmacao: _ocultarConfirmacao,
          aoAlternarSenha: () =>
              setState(() => _ocultarSenha = !_ocultarSenha),
          aoAlternarConfirmacao: () =>
              setState(() => _ocultarConfirmacao = !_ocultarConfirmacao),
          erro: _erro,
          carregando: _carregando,
          aoAvancar: _redefinirSenha,
        );
    }
  }
}

class _PontosEtapa extends StatelessWidget {
  final int indiceAtivo;

  const _PontosEtapa({required this.indiceAtivo});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final ativo = i <= indiceAtivo;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: i == indiceAtivo ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: ativo ? CoresApp.primaryMuted : Colors.white24,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _EtapaEmail extends StatelessWidget {
  final TextEditingController controlador;
  final String? erro;
  final bool carregando;
  final VoidCallback aoAvancar;

  const _EtapaEmail({
    super.key,
    required this.controlador,
    required this.erro,
    required this.carregando,
    required this.aoAvancar,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Informe seu e-mail',
              style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: CoresApp.textPrimary)),
          const SizedBox(height: 6),
          Text(
            'Enviaremos um código de verificação para o e-mail informado.',
            style: GoogleFonts.outfit(
                fontSize: 13, color: CoresApp.textSecondary),
          ),
          const SizedBox(height: 28),
          CampoAutenticacao(
            controlador: controlador,
            rotulo: 'E-mail cadastrado',
            dica: 'seu@email.com',
            icone: Icons.email_outlined,
            tipoTeclado: TextInputType.emailAddress,
          ),
          if (erro != null) ...[
            const SizedBox(height: 10),
            _TextoErro(erro!),
          ],
          const SizedBox(height: 28),
          carregando
              ? const Center(
                  child:
                      CircularProgressIndicator(color: CoresApp.primary))
              : BotaoPrimario(rotulo: 'Enviar código', aoTocar: aoAvancar),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Se esse e-mail estiver cadastrado, você receberá\num código em breve.',
              style: GoogleFonts.outfit(
                  fontSize: 12, color: CoresApp.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _EtapaCodigo extends StatelessWidget {
  final TextEditingController controlador;
  final String? erro;
  final VoidCallback aoAvancar;

  const _EtapaCodigo({
    super.key,
    required this.controlador,
    required this.erro,
    required this.aoAvancar,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Digite o código',
              style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: CoresApp.textPrimary)),
          const SizedBox(height: 6),
          Text(
            'Insira o código que você recebeu por e-mail.',
            style: GoogleFonts.outfit(
                fontSize: 13, color: CoresApp.textSecondary),
          ),
          const SizedBox(height: 28),
          CampoAutenticacao(
            controlador: controlador,
            rotulo: 'Código de verificação',
            dica: 'Cole o código aqui',
            icone: Icons.vpn_key_outlined,
            tipoTeclado: TextInputType.text,
          ),
          if (erro != null) ...[
            const SizedBox(height: 10),
            _TextoErro(erro!),
          ],
          const SizedBox(height: 28),
          BotaoPrimario(rotulo: 'Confirmar', aoTocar: aoAvancar),
        ],
      ),
    );
  }
}

class _EtapaNovaSenha extends StatelessWidget {
  final TextEditingController controladorSenha;
  final TextEditingController controladorConfirmacao;
  final bool ocultarSenha;
  final bool ocultarConfirmacao;
  final VoidCallback aoAlternarSenha;
  final VoidCallback aoAlternarConfirmacao;
  final String? erro;
  final bool carregando;
  final VoidCallback aoAvancar;

  const _EtapaNovaSenha({
    super.key,
    required this.controladorSenha,
    required this.controladorConfirmacao,
    required this.ocultarSenha,
    required this.ocultarConfirmacao,
    required this.aoAlternarSenha,
    required this.aoAlternarConfirmacao,
    required this.erro,
    required this.carregando,
    required this.aoAvancar,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Crie uma nova senha',
              style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: CoresApp.textPrimary)),
          const SizedBox(height: 6),
          Text('Escolha uma senha forte com pelo menos 8 caracteres.',
              style: GoogleFonts.outfit(
                  fontSize: 13, color: CoresApp.textSecondary)),
          const SizedBox(height: 28),
          CampoAutenticacao(
            controlador: controladorSenha,
            rotulo: 'Nova senha',
            dica: '••••••••',
            icone: Icons.lock_outline,
            oculto: ocultarSenha,
            sufixo: IconButton(
              icon: Icon(
                ocultarSenha
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: CoresApp.textSecondary,
                size: 20,
              ),
              onPressed: aoAlternarSenha,
            ),
          ),
          const SizedBox(height: 16),
          CampoAutenticacao(
            controlador: controladorConfirmacao,
            rotulo: 'Confirmar senha',
            dica: '••••••••',
            icone: Icons.lock_outline,
            oculto: ocultarConfirmacao,
            sufixo: IconButton(
              icon: Icon(
                ocultarConfirmacao
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: CoresApp.textSecondary,
                size: 20,
              ),
              onPressed: aoAlternarConfirmacao,
            ),
          ),
          if (erro != null) ...[
            const SizedBox(height: 12),
            _TextoErro(erro!),
          ],
          const SizedBox(height: 28),
          carregando
              ? const Center(
                  child:
                      CircularProgressIndicator(color: CoresApp.primary))
              : BotaoPrimario(
                  rotulo: 'Redefinir senha', aoTocar: aoAvancar),
        ],
      ),
    );
  }
}

class _TextoErro extends StatelessWidget {
  final String mensagem;
  const _TextoErro(this.mensagem);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.error_outline_rounded, size: 14, color: Colors.red),
        const SizedBox(width: 6),
        Expanded(
          child: Text(mensagem,
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.red)),
        ),
      ],
    );
  }
}
