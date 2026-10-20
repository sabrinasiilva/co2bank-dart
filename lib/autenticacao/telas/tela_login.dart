import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../nucleo/cores_app.dart';
import '../servico/servico_autenticacao.dart';
import '../../navegacao.dart';
import '../../compartilhado/widgets/campo_autenticacao.dart';
import '../../compartilhado/widgets/botao_primario.dart';
import '../../compartilhado/widgets/logo_co2bank.dart';
import 'tela_cadastro/tela_cadastro.dart';
import 'tela_esqueci_senha/tela_esqueci_senha.dart';

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final _controladorEmail = TextEditingController();
  final _controladorSenha = TextEditingController();
  bool _ocultarSenha = true;
  bool _carregando = false;
  String? _erro;

  final _servico = ServicoAutenticacao();

  @override
  void dispose() {
    _controladorEmail.dispose();
    _controladorSenha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    final resultado = await _servico.entrar(
      email: _controladorEmail.text.trim(),
      senha: _controladorSenha.text,
    );

    setState(() => _carregando = false);

    if (!mounted) return;

    switch (resultado) {
      case LoginSucesso():
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const Navegacao()));
      case LoginErroCredenciais():
        setState(() => _erro = 'E-mail ou senha incorretos');
      case LoginErroRede():
        setState(() => _erro = 'Não foi possível conectar ao servidor');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: CoresApp.primary,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: CoresApp.brandGradient),
          ),
          Positioned(
            top: size.height * 0.1,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const LogoCo2Bank(tamanho: 68, comSelo: true),
                const SizedBox(height: 12),
                Text(
                  'CO2Bank',
                  style: GoogleFonts.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: CoresApp.brandText),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: size.height * 0.68,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: CoresApp.background,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bem-vinda de volta',
                        style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: CoresApp.textPrimary)),
                    const SizedBox(height: 4),
                    Text('Entre na sua conta para continuar',
                        style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: CoresApp.textSecondary)),
                    const SizedBox(height: 32),
                    CampoAutenticacao(
                      controlador: _controladorEmail,
                      rotulo: 'E-mail',
                      dica: 'seu@email.com',
                      icone: Icons.email_outlined,
                      tipoTeclado: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    CampoAutenticacao(
                      controlador: _controladorSenha,
                      rotulo: 'Senha',
                      dica: '••••••••',
                      icone: Icons.lock_outline,
                      oculto: _ocultarSenha,
                      sufixo: IconButton(
                        icon: Icon(
                          _ocultarSenha
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: CoresApp.textSecondary,
                          size: 20,
                        ),
                        onPressed: () => setState(
                            () => _ocultarSenha = !_ocultarSenha),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const TelaEsqueciSenha()),
                        ),
                        child: Text('Esqueci minha senha',
                            style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: CoresApp.dark,
                                fontWeight: FontWeight.w500)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_erro != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(_erro!,
                            style: GoogleFonts.outfit(
                                fontSize: 13, color: Colors.red),
                            textAlign: TextAlign.center),
                      ),
                    _carregando
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: CoresApp.primary))
                        : BotaoPrimario(
                            rotulo: 'Entrar', aoTocar: _entrar),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('ou',
                              style: GoogleFonts.outfit(
                                  color: CoresApp.textSecondary,
                                  fontSize: 13)),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const TelaCadastro())),
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: CoresApp.textSecondary),
                            children: [
                              const TextSpan(
                                  text: 'Ainda não tem conta? '),
                              TextSpan(
                                text: 'Cadastre-se',
                                style: GoogleFonts.outfit(
                                    color: CoresApp.dark,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
