import 'package:flutter/material.dart';
import '../compartilhado/widgets/botao_primario.dart';
import '../compartilhado/widgets/campo_autenticacao.dart';
import '../nucleo/formatadores_entrada.dart';
import 'servico/servico_usuario.dart';

class TelaEditarPerfil extends StatefulWidget {
  final PerfilUsuario perfilInicial;

  const TelaEditarPerfil({super.key, required this.perfilInicial});

  @override
  State<TelaEditarPerfil> createState() => _TelaEditarPerfilState();
}

class _TelaEditarPerfilState extends State<TelaEditarPerfil> {
  late final TextEditingController _controladorNome;
  late final TextEditingController _controladorTelefone;
  late double _limiteCo2;

  bool _carregando = false;
  String? _mensagemErro;

  @override
  void initState() {
    super.initState();
    _controladorNome = TextEditingController(text: widget.perfilInicial.nome);
    _controladorTelefone = TextEditingController(
      text: widget.perfilInicial.telefone,
    );
    _limiteCo2 = widget.perfilInicial.limiteCo2Kg;

    _controladorNome.addListener(_atualizarEstado);
    _controladorTelefone.addListener(_atualizarEstado);
  }

  void _atualizarEstado() {
    setState(() {});
  }

  bool get _houveAlteracoes {
    final telefoneLimpo = _controladorTelefone.text.replaceAll(RegExp(r'\D'), '');
    return _controladorNome.text != widget.perfilInicial.nome ||
        telefoneLimpo != widget.perfilInicial.telefone ||
        _limiteCo2 != widget.perfilInicial.limiteCo2Kg;
  }

  Future<void> _salvar() async {
    final telefoneLimpo = _controladorTelefone.text.replaceAll(RegExp(r'\D'), '');
    if (telefoneLimpo.isNotEmpty && (telefoneLimpo.length < 10 || telefoneLimpo.length > 11)) {
      setState(() {
        _mensagemErro = 'Telefone inválido (deve ter 10 ou 11 dígitos)';
      });
      return;
    }

    setState(() {
      _carregando = true;
      _mensagemErro = null;
    });

    final servico = await ServicoUsuario.autenticado();
    
    final resultado = await servico.atualizarPerfil(
      nome: _controladorNome.text != widget.perfilInicial.nome ? _controladorNome.text : null,
      telefone: telefoneLimpo != widget.perfilInicial.telefone ? telefoneLimpo : null,
      limite: _limiteCo2 != widget.perfilInicial.limiteCo2Kg ? _limiteCo2.toInt() : null,
    );

    if (!mounted) return;

    setState(() {
      _carregando = false;
    });

    switch (resultado) {
      case PerfilAtualizado():
        Navigator.pop(context, true);
        break;
      case ErroMensagemPerfil(mensagem: final msg):
        setState(() {
          _mensagemErro = msg;
        });
        break;
      case ErroRedePerfil():
        setState(() {
          _mensagemErro = 'Sem conexão com a internet. Tente novamente.';
        });
        break;
    }
  }

  @override
  void dispose() {
    _controladorNome.dispose();
    _controladorTelefone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CampoAutenticacao(
              rotulo: 'Nome',
              dica: 'Digite seu nome',
              icone: Icons.person_outline,
              controlador: _controladorNome,
            ),
            const SizedBox(height: 16),
            CampoAutenticacao(
              rotulo: 'Telefone',
              dica: 'Digite seu telefone',
              icone: Icons.phone_outlined,
              controlador: _controladorTelefone,
              formatadores: [FormatadorTelefone()],
              tipoTeclado: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            Text(
              'Limite mensal de CO2: ${_limiteCo2.toInt()} kg/mês',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Slider(
              value: _limiteCo2,
              min: 50,
              max: 500,
              divisions: 45,
              label: '${_limiteCo2.toInt()} kg',
              onChanged: (novoValor) {
                setState(() {
                  _limiteCo2 = novoValor;
                });
              },
            ),
            if (_mensagemErro != null) ...[
              const SizedBox(height: 16),
              Text(
                _mensagemErro!,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
            const SizedBox(height: 32),
            BotaoPrimario(
              rotulo: 'Salvar',
              carregando: _carregando,
              aoTocar: _houveAlteracoes ? _salvar : null,
            ),
          ],
        ),
      ),
    );
  }
}