import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../nucleo/aviso_dados_alterados.dart';
import '../nucleo/cores_app.dart';
import '../nucleo/armazenamento_token.dart';
import '../perfil/servico/servico_usuario.dart';
import '../nucleo/notificacoes.dart';
import '../nucleo/push_firebase.dart';
import '../transacoes/servico/servico_transacao.dart';
import 'sugestao_limite.dart';
import 'tela_editar_perfil.dart';
import '../autenticacao/servico/acesso_biometrico.dart';
import '../autenticacao/servico/servico_autenticacao.dart';
import '../autenticacao/telas/tela_login.dart';
import '../nucleo/tipografia.dart';

class AbaPerfil extends StatefulWidget {
  const AbaPerfil({super.key});

  @override
  State<AbaPerfil> createState() => _AbaPerfilState();
}

class _AbaPerfilState extends State<AbaPerfil> {
  late Future<ResultadoPerfil> _dados;
  SugestaoLimite? _sugestao;
  bool _notificacoesAtivas = false;
  bool _alterandoNotificacoes = false;
  bool _biometriaDisponivel = false;
  bool _biometriaAtiva = false;
  bool _alterandoBiometria = false;

  @override
  void initState() {
    super.initState();
    _dados = _carregar();
    _carregarSugestao();
    _carregarNotificacoes();
    _carregarBiometria();
    AvisoDadosAlterados.instancia.addListener(_carregarSugestao);
  }

  @override
  void dispose() {
    AvisoDadosAlterados.instancia.removeListener(_carregarSugestao);
    super.dispose();
  }

  Future<void> _carregarNotificacoes() async {
    final ativas = await Notificacoes.estaoAtivas();
    if (mounted) setState(() => _notificacoesAtivas = ativas);
  }

  Future<void> _alternarNotificacoes(bool ligar) async {
    setState(() => _alterandoNotificacoes = true);
    var ativas = false;
    if (ligar) {
      ativas = await Notificacoes.ativar();
      if (ativas) {
        unawaited(PushFirebase.ativar());
        final servico = await ServicoTransacao.autenticado();
        await servico.avisarSeLimiteAlto();
      }
    } else {
      await Notificacoes.desativar();
      await PushFirebase.desativar();
    }
    if (!mounted) return;
    setState(() {
      _notificacoesAtivas = ativas;
      _alterandoNotificacoes = false;
    });
    if (ligar && !ativas) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          Notificacoes.suportado
              ? 'Permissão negada. Libere as notificações do CO2Bank nas configurações.'
              : 'Notificações não estão disponíveis neste dispositivo.',
          style: GoogleFonts.outfit(),
        ),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _carregarBiometria() async {
    final disponivel = await AcessoBiometrico.disponivel();
    final ativa = disponivel && await AcessoBiometrico.ativa();
    if (!mounted) return;
    setState(() {
      _biometriaDisponivel = disponivel;
      _biometriaAtiva = ativa;
    });
  }

  /// Para ligar, confirma a senha (é ela que fica guardada no cofre do
  /// celular) e depois a digital ou o rosto.
  Future<void> _alternarBiometria(bool ligar, String email) async {
    if (!ligar) {
      await AcessoBiometrico.desativar();
      if (mounted) setState(() => _biometriaAtiva = false);
      return;
    }
    final senha = await _pedirSenha();
    if (senha == null || !mounted) return;
    setState(() => _alterandoBiometria = true);
    final login = await ServicoAutenticacao().entrar(email: email, senha: senha);
    var ativou = false;
    if (login is LoginSucesso) {
      ativou = await AcessoBiometrico.ativar(email: email, senha: senha);
    }
    if (!mounted) return;
    setState(() {
      _biometriaAtiva = ativou;
      _alterandoBiometria = false;
    });
    if (!ativou) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          login is LoginErroCredenciais
              ? 'Senha incorreta. Tente de novo.'
              : 'Não foi possível ativar a biometria agora.',
          style: GoogleFonts.outfit(),
        ),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<String?> _pedirSenha() {
    final controlador = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: Text(
          'Confirme sua senha',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controlador,
          obscureText: true,
          autofocus: true,
          style: GoogleFonts.outfit(),
          decoration: const InputDecoration(hintText: 'Senha'),
          onSubmitted: (valor) => Navigator.pop(contexto, valor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexto),
            child: Text('Cancelar',
                style: GoogleFonts.outfit(color: CoresApp.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(contexto, controlador.text),
            child: Text('Continuar',
                style: GoogleFonts.outfit(
                    color: CoresApp.dark, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    ).whenComplete(controlador.dispose);
  }

  Future<void> _carregarSugestao() async {
    final sugestao = await calcularSugestaoLimite();
    if (mounted) setState(() => _sugestao = sugestao);
  }

  Future<ResultadoPerfil> _carregar() async {
    final servico = await ServicoUsuario.autenticado();
    return servico.obterPerfil();
  }

  Future<void> _recarregarPerfil() async {
    setState(() {
      _dados = _carregar();
    });
  }

  Future<void> _sair() async {
    await PushFirebase.desativar();
    await ArmazenamentoToken.limpar();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const TelaLogin()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<ResultadoPerfil>(
        future: _dados,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: CoresApp.primary),
            );
          }

          final PerfilUsuario? perfil = switch (snapshot.data) {
            PerfilCarregado(:final perfil) => perfil,
            _ => null,
          };

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Perfil',
                    style: GoogleFonts.outfit(
                      fontSize: Tipografia.titulo,
                      fontWeight: FontWeight.bold,
                      color: CoresApp.textPrimary,
                    ),
                  ),
                  if (perfil != null)
                    TextButton.icon(
                      onPressed: () async {
                        final alterado = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TelaEditarPerfil(perfilInicial: perfil),
                          ),
                        );
                        if (alterado == true) {
                          _recarregarPerfil();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Perfil atualizado',
                                style: GoogleFonts.outfit(),
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: CoresApp.primary,
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: Text(
                        'Editar perfil',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: CoresApp.dark,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      perfil?.nome.isNotEmpty == true
                          ? perfil!.nome[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.outfit(
                        fontSize: Tipografia.numero,
                        fontWeight: FontWeight.bold,
                        color: CoresApp.primary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (perfil != null) ...[
                Center(
                  child: Text(
                    perfil.nome,
                    style: GoogleFonts.outfit(
                      fontSize: Tipografia.tituloSecao,
                      fontWeight: FontWeight.bold,
                      color: CoresApp.textPrimary,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    perfil.email,
                    style: GoogleFonts.outfit(
                      fontSize: Tipografia.corpo,
                      color: CoresApp.textSecondary,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              _CartaoInfo(
                itens: [
                  if (perfil != null) ...[
                    _LinhaInfo(rotulo: 'CPF', valor: perfil.cpf),
                    _LinhaInfo(
                      rotulo: 'Telefone',
                      valor: perfil.telefone.isNotEmpty ? perfil.telefone : '-',
                    ),
                    _LinhaInfo(
                      rotulo: 'Limite de CO2',
                      valor: '${perfil.limiteCo2Kg.toStringAsFixed(0)} kg/mês',
                    ),
                  ],
                ],
              ),
              if (perfil != null && _sugestao != null) ...[
                const SizedBox(height: 16),
                CartaoSugestaoLimite(
                  sugestao: _sugestao!,
                  limiteAtualKg: perfil.limiteCo2Kg,
                ),
              ],
              const SizedBox(height: 16),
              _CartaoOpcao(
                icone: Icons.notifications_active_outlined,
                titulo: 'Notificações de alerta',
                descricao: 'Avisa no celular quando o limite do mês passar de 80%',
                ativa: _notificacoesAtivas,
                alterando: _alterandoNotificacoes,
                aoAlternar: _alternarNotificacoes,
              ),
              if (_biometriaDisponivel && perfil != null) ...[
                const SizedBox(height: 12),
                _CartaoOpcao(
                  icone: Icons.fingerprint_rounded,
                  titulo: 'Entrar com biometria',
                  descricao: 'Use a digital, o rosto ou o PIN do celular para entrar',
                  ativa: _biometriaAtiva,
                  alterando: _alterandoBiometria,
                  aoAlternar: (ligar) => _alternarBiometria(ligar, perfil.email),
                ),
              ],
              const SizedBox(height: 32),
              GestureDetector(
                onTap: _sair,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CoresApp.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.logout_rounded,
                          size: 20, color: Colors.red),
                      const SizedBox(width: 12),
                      Text(
                        'Sair da conta',
                        style: GoogleFonts.outfit(
                          fontSize: Tipografia.destaque,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CartaoInfo extends StatelessWidget {
  final List<Widget> itens;

  const _CartaoInfo({required this.itens});

  @override
  Widget build(BuildContext context) {
    if (itens.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: CoresApp.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: itens),
    );
  }
}

class _LinhaInfo extends StatelessWidget {
  final String rotulo;
  final String valor;

  const _LinhaInfo({required this.rotulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            rotulo,
            style: GoogleFonts.outfit(
              fontSize: Tipografia.corpo,
              color: CoresApp.textSecondary,
            ),
          ),
          Text(
            valor,
            style: GoogleFonts.outfit(
              fontSize: Tipografia.corpo,
              fontWeight: FontWeight.w600,
              color: CoresApp.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Linha de opção do Perfil com um switch (notificações, biometria).
class _CartaoOpcao extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String descricao;
  final bool ativa;
  final bool alterando;
  final ValueChanged<bool> aoAlternar;

  const _CartaoOpcao({
    required this.icone,
    required this.titulo,
    required this.descricao,
    required this.ativa,
    required this.alterando,
    required this.aoAlternar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: CoresApp.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icone, size: 22, color: CoresApp.textPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: GoogleFonts.outfit(
                    fontSize: Tipografia.destaque,
                    fontWeight: FontWeight.w600,
                    color: CoresApp.textPrimary,
                  ),
                ),
                Text(
                  descricao,
                  style: GoogleFonts.outfit(
                    fontSize: Tipografia.legenda,
                    color: CoresApp.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (alterando)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: CoresApp.primary,
                ),
              ),
            )
          else
            Switch(
              value: ativa,
              onChanged: aoAlternar,
              activeThumbColor: Colors.white,
              activeTrackColor: CoresApp.primary,
            ),
        ],
      ),
    );
  }
}