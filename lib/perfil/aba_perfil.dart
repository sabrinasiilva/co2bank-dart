import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../nucleo/cores_app.dart';
import '../nucleo/armazenamento_token.dart';
import '../perfil/servico/servico_usuario.dart';
import '../nucleo/notificacoes.dart';
import '../transacoes/servico/servico_transacao.dart';
import 'sugestao_limite.dart';
import '../autenticacao/telas/tela_login.dart';

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

  @override
  void initState() {
    super.initState();
    _dados = _carregar();
    _carregarSugestao();
    _carregarNotificacoes();
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
        // Se o mês já está perto do limite, o aviso aparece na hora.
        final servico = await ServicoTransacao.autenticado();
        await servico.avisarSeLimiteAlto();
      }
    } else {
      await Notificacoes.desativar();
    }
    if (!mounted) return;
    setState(() {
      _notificacoesAtivas = ativas;
      _alterandoNotificacoes = false;
    });
    if (ligar && !ativas) {
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

  Future<void> _carregarSugestao() async {
    final sugestao = await calcularSugestaoLimite();
    if (mounted) setState(() => _sugestao = sugestao);
  }

  Future<ResultadoPerfil> _carregar() async {
    final servico = await ServicoUsuario.autenticado();
    return servico.obterPerfil();
  }

  Future<void> _sair() async {
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
              Text(
                'Perfil',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: CoresApp.textPrimary,
                ),
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
                        fontSize: 28,
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
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: CoresApp.textPrimary,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    perfil.email,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
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
                    _LinhaInfo(rotulo: 'Telefone', valor: perfil.telefone),
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
              _CartaoNotificacoes(
                ativas: _notificacoesAtivas,
                alterando: _alterandoNotificacoes,
                aoAlternar: _alternarNotificacoes,
              ),
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
                          fontSize: 15,
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
              fontSize: 14,
              color: CoresApp.textSecondary,
            ),
          ),
          Text(
            valor,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CoresApp.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CartaoNotificacoes extends StatelessWidget {
  final bool ativas;
  final bool alterando;
  final ValueChanged<bool> aoAlternar;

  const _CartaoNotificacoes({
    required this.ativas,
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
          const Icon(Icons.notifications_active_outlined,
              size: 22, color: CoresApp.textPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notificações de alerta',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: CoresApp.textPrimary,
                  ),
                ),
                Text(
                  'Avisa no celular quando o limite do mês passar de 80%',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
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
              value: ativas,
              onChanged: aoAlternar,
              activeThumbColor: Colors.white,
              activeTrackColor: CoresApp.primary,
            ),
        ],
      ),
    );
  }
}
