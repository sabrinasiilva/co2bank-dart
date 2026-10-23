import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../nucleo/cores_app.dart';
import '../nucleo/tipografia.dart';
import 'servico/atualizacao_app.dart';
import 'servico/servico_notificacoes.dart';

/// Central do sininho: versão nova do app (quando houver) e as notificações
/// do backend (alertas da IA, conquistas, cupons e o resumo da semana).
class TelaNotificacoes extends StatefulWidget {
  final AtualizacaoDisponivel? atualizacao;

  const TelaNotificacoes({super.key, this.atualizacao});

  @override
  State<TelaNotificacoes> createState() => _TelaNotificacoesState();
}

class _TelaNotificacoesState extends State<TelaNotificacoes> {
  late Future<CentralNotificacoes> _central;

  @override
  void initState() {
    super.initState();
    _central = _carregar();
  }

  /// Carrega e já marca tudo como lido. Na tela, as que chegaram sem ler
  /// continuam com o ponto verde até a pessoa sair.
  Future<CentralNotificacoes> _carregar() async {
    final servico = await ServicoNotificacoes.autenticado();
    final central = await servico.carregar();
    if (central.naoLidas > 0) await servico.marcarTodasComoLidas();
    return central;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoresApp.background,
      appBar: AppBar(
        backgroundColor: CoresApp.background,
        foregroundColor: CoresApp.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Notificações',
          style: GoogleFonts.outfit(
            fontSize: Tipografia.tituloSecao,
            fontWeight: FontWeight.bold,
            color: CoresApp.textPrimary,
          ),
        ),
      ),
      body: FutureBuilder<CentralNotificacoes>(
        future: _central,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: CoresApp.primary),
            );
          }
          final itens = snapshot.data?.itens ?? const <ItemNotificacao>[];
          final atualizacao = widget.atualizacao;
          return RefreshIndicator(
            color: CoresApp.primary,
            onRefresh: () async => setState(() => _central = _carregar()),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                if (atualizacao != null) _CartaoAtualizacao(atualizacao: atualizacao),
                for (final item in itens) _CartaoNotificacao(item: item),
                if (itens.isEmpty && atualizacao == null) const _SemNotificacoes(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CartaoAtualizacao extends StatelessWidget {
  final AtualizacaoDisponivel atualizacao;

  const _CartaoAtualizacao({required this.atualizacao});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: CoresApp.brandGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.system_update_rounded, size: 28, color: CoresApp.brandText),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nova versão do app',
                  style: GoogleFonts.outfit(
                    fontSize: Tipografia.destaque,
                    fontWeight: FontWeight.bold,
                    color: CoresApp.brandText,
                  ),
                ),
                Text(
                  'Baixe e instale por cima: seus dados continuam.',
                  style: GoogleFonts.outfit(
                    fontSize: Tipografia.legenda,
                    color: CoresApp.brandText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => launchUrl(
              atualizacao.linkApk,
              mode: LaunchMode.externalApplication,
            ),
            style: FilledButton.styleFrom(
              backgroundColor: CoresApp.dark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Baixar',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartaoNotificacao extends StatelessWidget {
  final ItemNotificacao item;

  const _CartaoNotificacao({required this.item});

  (IconData, Color) get _visual => switch (item.tipo) {
        'limit_alert' => (Icons.warning_amber_rounded, CoresApp.accentWarm),
        'achievement' => (Icons.emoji_events_rounded, CoresApp.primary),
        'redemption' => (Icons.local_offer_rounded, CoresApp.brandText),
        'weekly_summary' => (Icons.insights_rounded, CoresApp.dark),
        _ => (Icons.notifications_rounded, CoresApp.gray),
      };

  @override
  Widget build(BuildContext context) {
    final (icone, cor) = _visual;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CoresApp.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.lida ? CoresApp.border : CoresApp.primary.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icone, size: 22, color: cor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.titulo,
                        style: GoogleFonts.outfit(
                          fontSize: Tipografia.corpo,
                          fontWeight: FontWeight.w700,
                          color: CoresApp.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      quandoChegou(item.criadaEm),
                      style: GoogleFonts.outfit(
                        fontSize: Tipografia.legenda,
                        color: CoresApp.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.corpo,
                  style: GoogleFonts.outfit(
                    fontSize: Tipografia.corpo,
                    color: CoresApp.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SemNotificacoes extends StatelessWidget {
  const _SemNotificacoes();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 120),
      child: Column(
        children: [
          const Icon(Icons.notifications_none_rounded, size: 48, color: CoresApp.border),
          const SizedBox(height: 12),
          Text(
            'Nenhuma notificação por enquanto',
            style: GoogleFonts.outfit(
              fontSize: Tipografia.corpo,
              color: CoresApp.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// "agora", "há 5 min", "há 2 h", "ontem" ou "12 de out".
String quandoChegou(DateTime quando, {DateTime? agora}) {
  final referencia = agora ?? DateTime.now();
  final diferenca = referencia.difference(quando);
  if (diferenca.inMinutes < 1) return 'agora';
  if (diferenca.inHours < 1) return 'há ${diferenca.inMinutes} min';
  if (diferenca.inDays < 1 && referencia.day == quando.day) return 'há ${diferenca.inHours} h';
  final ontem = DateTime(referencia.year, referencia.month, referencia.day - 1);
  if (quando.year == ontem.year && quando.month == ontem.month && quando.day == ontem.day) {
    return 'ontem';
  }
  return DateFormat("d 'de' MMM", 'pt_BR').format(quando).replaceAll('.', '');
}
