import 'dart:async';

import 'package:flutter/material.dart';

import '../../../nucleo/cores_app.dart';
import '../../../nucleo/validadores.dart';
import '../../servico/servico_autenticacao.dart';
import '../tela_boas_vindas.dart';
import '../../../open_finance/servico/servico_open_finance.dart';
import '../../../compartilhado/widgets/indicador_etapa.dart';
import 'etapa1_dados_pessoais.dart';
import 'etapa2_acesso.dart';
import 'etapa3_verificacao_facial.dart';
import 'etapa3_open_finance.dart';
import 'etapa4_limite_ecologico.dart';
import 'etapa5_concluido.dart';

class TelaCadastro extends StatefulWidget {
  const TelaCadastro({super.key});

  @override
  State<TelaCadastro> createState() => _TelaCadastroState();
}

class _TelaCadastroState extends State<TelaCadastro> {
  final _controladorPagina = PageController();
  int _etapaAtual = 0;
  static const int _totalEtapas = 6;

  final Map<String, String?> _erros = {};

  final _controladorNome = TextEditingController();
  final _controladorCpf = TextEditingController();
  final _controladorTelefone = TextEditingController();
  DateTime? _dataNascimento;

  final _controladorEmail = TextEditingController();
  final _controladorSenha = TextEditingController();
  final _controladorConfirmacao = TextEditingController();
  bool _ocultarSenha = true;
  bool _ocultarConfirmacao = true;

  String? _fotoBase64;

  final Set<String> _bancosConectados = {};
  double _limiteCo2 = 200;
  bool _carregando = false;
  String? _erroCadastro;

  final _servico = ServicoAutenticacao();

  double get _forcaSenha =>
      Validadores.forcaDaSenha(_controladorSenha.text);

  Color get _corForca {
    if (_forcaSenha < 0.34) return Colors.red;
    if (_forcaSenha < 0.67) return Colors.orange;
    return const Color(0xFF52B788);
  }

  String get _rotuloForca {
    if (_forcaSenha < 0.34) return 'Fraca';
    if (_forcaSenha < 0.67) return 'Média';
    return 'Forte';
  }

  bool _validarEtapa1() {
    final errs = <String, String?>{};
    final nome = _controladorNome.text.trim();
    if (nome.isEmpty) {
      errs['name'] = 'Informe o nome completo';
    } else if (nome.split(' ').length < 2) {
      errs['name'] = 'Informe o nome e o sobrenome';
    } else if (!RegExp(r'^[a-zA-ZÀ-ÿ\s]+$').hasMatch(nome)) {
      errs['name'] = 'Nome deve conter apenas letras';
    }
    if (!Validadores.cpfValido(_controladorCpf.text)) {
      errs['cpf'] = 'CPF inválido';
    }
    if (!Validadores.telefoneValido(_controladorTelefone.text)) {
      errs['phone'] = 'Celular inválido';
    }
    if (_dataNascimento == null) {
      errs['birthDate'] = 'Informe a data de nascimento';
    }
    setState(() {
      _erros
        ..remove('name')
        ..remove('cpf')
        ..remove('phone')
        ..remove('birthDate')
        ..addAll(errs);
    });
    return errs.isEmpty;
  }

  bool _validarEtapa2() {
    final errs = <String, String?>{};
    final email = _controladorEmail.text.trim();
    if (email.isEmpty) {
      errs['email'] = 'Informe o e-mail';
    } else if (!Validadores.emailValido(email)) {
      errs['email'] = 'E-mail inválido';
    }
    final senha = _controladorSenha.text;
    if (senha.isEmpty) {
      errs['password'] = 'Informe a senha';
    } else if (senha.length < 8) {
      errs['password'] = 'A senha deve ter pelo menos 8 caracteres';
    } else if (!senha.contains(RegExp(r'[A-Z]'))) {
      errs['password'] = 'A senha deve ter pelo menos uma letra maiúscula';
    } else if (!senha.contains(RegExp(r'[0-9!@#$%^&*]'))) {
      errs['password'] = 'Use pelo menos um número ou caractere especial';
    }
    if (_controladorConfirmacao.text.isEmpty) {
      errs['confirm'] = 'Confirme a senha';
    } else if (_controladorConfirmacao.text != senha) {
      errs['confirm'] = 'As senhas não coincidem';
    }
    setState(() {
      _erros
        ..remove('email')
        ..remove('password')
        ..remove('confirm')
        ..addAll(errs);
    });
    return errs.isEmpty;
  }

  void _tentarAvancar() {
    bool valido = true;
    if (_etapaAtual == 0) valido = _validarEtapa1();
    if (_etapaAtual == 1) valido = _validarEtapa2();
    if (!valido) return;

    if (_etapaAtual == 4) {
      _realizarCadastro();
      return;
    }

    _controladorPagina.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut);
    setState(() => _etapaAtual++);
  }

  Future<void> _realizarCadastro() async {
    setState(() {
      _carregando = true;
      _erroCadastro = null;
    });

    final dataNasc = _dataNascimento!;
    final resultado = await _servico.cadastrar(
      nome: _controladorNome.text.trim(),
      email: _controladorEmail.text.trim(),
      cpf: _controladorCpf.text,
      telefone: _controladorTelefone.text,
      dataNascimento:
          '${dataNasc.year}-${dataNasc.month.toString().padLeft(2, '0')}-${dataNasc.day.toString().padLeft(2, '0')}',
      senha: _controladorSenha.text,
      limiteCo2Kg: _limiteCo2,
      fotoBase64: _fotoBase64,
    );

    setState(() => _carregando = false);

    switch (resultado) {
      case CadastroSucesso():
        unawaited(_conectarBancosEscolhidos());
        _controladorPagina.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut);
        setState(() => _etapaAtual++);
      case CadastroErro(:final mensagem):
        setState(() => _erroCadastro = mensagem);
      case CadastroErroRede():
        setState(
            () => _erroCadastro = 'Não foi possível conectar ao servidor');
    }
  }

  // Falhar aqui não deve travar o cadastro: o usuário pode conectar depois pela tela de Open Finance.
  // A sincronização já roda em seguida para a Home abrir com as compras do mês.
  Future<void> _conectarBancosEscolhidos() async {
    if (_bancosConectados.isEmpty) return;
    final servico = await ServicoOpenFinance.autenticado();
    final resultado = await servico.conectar(_bancosConectados);
    if (resultado is OperacaoConcluida) await servico.sincronizar();
  }

  void _etapaAnterior() {
    if (_etapaAtual > 0) {
      _controladorPagina.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut);
      setState(() => _etapaAtual--);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _controladorPagina.dispose();
    _controladorNome.dispose();
    _controladorCpf.dispose();
    _controladorTelefone.dispose();
    _controladorEmail.dispose();
    _controladorSenha.dispose();
    _controladorConfirmacao.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: CoresApp.dark,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [CoresApp.dark, Color(0xFF2D6A4F)],
              ),
            ),
          ),
          Positioned(
            top: topPadding + 12,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 20),
                    onPressed: _etapaAnterior,
                  ),
                  const Spacer(),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.eco_rounded,
                        size: 24, color: CoresApp.mintGreen),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: size.height * 0.78,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: CoresApp.background,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                    child: IndicadorEtapa(
                        etapaAtual: _etapaAtual,
                        totalEtapas: _totalEtapas),
                  ),
                  Expanded(
                    child: PageView(
                      controller: _controladorPagina,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        Etapa1DadosPessoais(
                          controladorNome: _controladorNome,
                          controladorCpf: _controladorCpf,
                          controladorTelefone: _controladorTelefone,
                          dataNascimento: _dataNascimento,
                          erros: _erros,
                          aoContinuar: _tentarAvancar,
                          aoSelecionarDataNascimento: (data) =>
                              setState(() {
                            _dataNascimento = data;
                            _erros.remove('birthDate');
                          }),
                        ),
                        Etapa2Acesso(
                          controladorEmail: _controladorEmail,
                          controladorSenha: _controladorSenha,
                          controladorConfirmacao: _controladorConfirmacao,
                          ocultarSenha: _ocultarSenha,
                          ocultarConfirmacao: _ocultarConfirmacao,
                          forcaSenha: _forcaSenha,
                          corForca: _corForca,
                          rotuloForca: _rotuloForca,
                          erros: _erros,
                          aoContinuar: _tentarAvancar,
                          aoAlternarSenha: () => setState(
                              () => _ocultarSenha = !_ocultarSenha),
                          aoAlternarConfirmacao: () => setState(
                              () => _ocultarConfirmacao =
                                  !_ocultarConfirmacao),
                          aoAlterarSenha: (_) => setState(() {}),
                          aoAlterarConfirmacao: (valor) {
                            if (_erros['confirm'] != null) {
                              setState(() {
                                if (valor == _controladorSenha.text) {
                                  _erros.remove('confirm');
                                } else {
                                  _erros['confirm'] =
                                      'As senhas não coincidem';
                                }
                              });
                            }
                          },
                        ),
                        Etapa3VerificacaoFacial(
                          fotoCapturadaBase64: _fotoBase64,
                          aoCapturarFoto: (b64) =>
                              setState(() => _fotoBase64 = b64),
                          aoContinuar: _tentarAvancar,
                        ),
                        Etapa3OpenFinance(
                          bancosConectados: _bancosConectados,
                          aoAlternarBanco: (banco) => setState(() {
                            _bancosConectados.contains(banco)
                                ? _bancosConectados.remove(banco)
                                : _bancosConectados.add(banco);
                          }),
                          aoContinuar: _tentarAvancar,
                        ),
                        Etapa4LimiteEcologico(
                          limiteCo2: _limiteCo2,
                          aoAlterarLimite: (v) =>
                              setState(() => _limiteCo2 = v),
                          aoContinuar: _tentarAvancar,
                          carregando: _carregando,
                          erro: _erroCadastro,
                        ),
                        // Antes da Home, a tela de boas-vindas explica o app
                        // e oferece conectar o banco.
                        Etapa5Concluido(
                          aoIniciar: () =>
                              Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (_) => TelaBoasVindas(
                                      primeiroNome: _controladorNome.text
                                          .trim()
                                          .split(' ')
                                          .first,
                                      bancoJaConectado:
                                          _bancosConectados.isNotEmpty,
                                    )),
                            (_) => false,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
