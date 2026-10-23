import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../nucleo/cores_app.dart';
import '../servico/acesso_biometrico.dart';
import '../servico/servico_autenticacao.dart';
import '../widgets/oferta_biometria.dart';
import '../../navegacao.dart';
import '../../compartilhado/widgets/campo_autenticacao.dart';
import '../../compartilhado/widgets/botao_primario.dart';
import '../../compartilhado/widgets/logo_co2bank.dart';
import 'tela_cadastro/tela_cadastro.dart';
import 'tela_esqueci_senha.dart';
import '../../nucleo/tipografia.dart';

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
  bool _emailLembrado = false;
  bool _biometriaAtiva = false;

  @override
  void initState() {
    super.initState();
    _prepararAcessoRapido();
  }

  @override
  void dispose() {
    _controladorEmail.dispose();
    _controladorSenha.dispose();
    super.dispose();
  }

  /// Preenche o e-mail da última vez e, com a biometria ativa, já pede a
  /// digital ao abrir, como nos apps de banco.
  Future<void> _prepararAcessoRapido() async {
    final email = await AcessoBiometrico.emailSalvo();
    final biometria =
        await AcessoBiometrico.ativa() && await AcessoBiometrico.disponivel();
    if (!mounted) return;
    setState(() {
      if (email != null) {
        _controladorEmail.text = email;
        _emailLembrado = true;
      }
      _biometriaAtiva = biometria;
    });
    if (biometria) await _entrarComBiometria();
  }

  Future<void> _entrar() async {
    final email = _controladorEmail.text.trim();
    final senha = _controladorSenha.text;
    final entrou = await _fazerLogin(email: email, senha: senha);
    if (!entrou || !mounted) return;
    await AcessoBiometrico.salvarEmail(email);
    if (!mounted) return;
    await oferecerBiometria(context, email: email, senha: senha);
    _irParaInicio();
  }

  Future<void> _entrarComBiometria() async {
    final credenciais = await AcessoBiometrico.credenciais();
    if (credenciais == null || !mounted) return;
    final entrou =
        await _fazerLogin(email: credenciais.email, senha: credenciais.senha);
    if (entrou) {
      _irParaInicio();
    } else if (_erro == 'E-mail ou senha incorretos') {
      // A senha mudou desde que a biometria foi ativada.
      await AcessoBiometrico.desativar();
      if (!mounted) return;
      setState(() {
        _biometriaAtiva = false;
        _erro = 'Sua senha mudou. Entre com a senha nova para ativar a biometria de novo.';
      });
    }
  }

  Future<bool> _fazerLogin({required String email, required String senha}) async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    final resultado = await _servico.entrar(email: email, senha: senha);
    if (!mounted) return false;
    setState(() => _carregando = false);

    switch (resultado) {
      case LoginSucesso():
        return true;
      case LoginErroCredenciais():
        setState(() => _erro = 'E-mail ou senha incorretos');
      case LoginErroRede():
        setState(() => _erro = 'Não foi possível conectar ao servidor');
    }
    return false;
  }

  void _irParaInicio() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const Navegacao()));
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
                      fontSize: Tipografia.titulo,
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
                    Text(_emailLembrado ? 'Que bom te ver de novo' : 'Boas-vindas',
                        style: GoogleFonts.outfit(
                            fontSize: Tipografia.titulo,
                            fontWeight: FontWeight.bold,
                            color: CoresApp.textPrimary)),
                    const SizedBox(height: 4),
                    Text('Entre na sua conta para continuar',
                        style: GoogleFonts.outfit(
                            fontSize: Tipografia.corpo,
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
                                fontSize: Tipografia.corpo,
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
                                fontSize: Tipografia.corpo, color: Colors.red),
                            textAlign: TextAlign.center),
                      ),
                    _carregando
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: CoresApp.primary))
                        : BotaoPrimario(
                            rotulo: 'Entrar', aoTocar: _entrar),
                    if (_biometriaAtiva && !_carregando) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: _entrarComBiometria,
                          icon: const Icon(Icons.fingerprint_rounded, size: 24),
                          label: Text(
                            'Entrar com biometria',
                            style: GoogleFonts.outfit(
                                fontSize: Tipografia.destaque, fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: CoresApp.dark,
                            side: const BorderSide(color: CoresApp.border),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
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
                                  fontSize: Tipografia.corpo)),
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
                                fontSize: Tipografia.corpo,
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
