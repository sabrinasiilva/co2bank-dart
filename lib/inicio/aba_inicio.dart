import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../compartilhado/widgets/aviso_erro_carregamento.dart';
import '../nucleo/aviso_dados_alterados.dart';
import '../nucleo/cores_app.dart';
import '../transacoes/servico/servico_transacao.dart';
import '../nucleo/notificacoes.dart';
import '../transacoes/icone_categoria.dart';
import '../transacoes/telas/tela_detalhe_transacao.dart';
import '../perfil/servico/servico_usuario.dart';
import 'estado_vazio_inicio.dart';
import '../nucleo/tipografia.dart';

class AbaInicio extends StatefulWidget {
  final VoidCallback? aoVerTransacoes;

  const AbaInicio({super.key, this.aoVerTransacoes});

  @override
  State<AbaInicio> createState() => _AbaInicioState();
}

class _AbaInicioState extends State<AbaInicio> {
  late Future<_DadosInicio> _dados;
  Future<_DadosInicio>? _cargaEmSegundoPlano;

  @override
  void initState() {
    super.initState();
    _dados = _carregarDados();
    AvisoDadosAlterados.instancia.addListener(_recarregarEmSegundoPlano);
  }

  @override
  void dispose() {
    AvisoDadosAlterados.instancia.removeListener(_recarregarEmSegundoPlano);
    super.dispose();
  }

  /// Busca de novo sem trocar a tela pelo carregando: o que já está visível
  /// fica no lugar (com o mesmo scroll) até os dados novos chegarem.
  Future<void> _recarregarEmSegundoPlano() async {
    final carga = _carregarDados();
    _cargaEmSegundoPlano = carga;
    final _DadosInicio dados;
    try {
      dados = await carga;
    } catch (_) {
      return; // Mantém os dados que já estavam na tela.
    }
    // Se outro aviso chegou nesse meio-tempo, a carga mais nova é que vale.
    if (!mounted || carga != _cargaEmSegundoPlano) return;
    setState(() => _dados = SynchronousFuture(dados));
  }

  Future<_DadosInicio> _carregarDados() async {
    final now = DateTime.now();
    final servicoUsuario = await ServicoUsuario.autenticado();
    final servicoTransacao = await ServicoTransacao.autenticado();

    final resultadoPerfil = await servicoUsuario.obterPerfil();
    final PerfilUsuario? usuario = switch (resultadoPerfil) {
      PerfilCarregado(:final perfil) => perfil,
      PerfilIndisponivel() => null,
    };

    final resultadoResumo =
        await servicoTransacao.resumoMensal(mes: now.month, ano: now.year);
    final ResumoMensal? resumo = switch (resultadoResumo) {
      ResumoCarregado(:final resumo) => resumo,
      ResumoIndisponivel() => null,
    };

    final recentes = await servicoTransacao.listarTransacoes(
        mes: now.month, ano: now.year);

    final resultadoAlerta = await servicoTransacao.verificarLimite();
    final AlertaLimite? alertaLimite = switch (resultadoAlerta) {
      AlertaCarregado(:final alerta) => alerta,
      AlertaIndisponivel() => null,
    };
    if (alertaLimite != null &&
        alertaLimite.ativo &&
        alertaLimite.mensagem != null) {
      unawaited(Notificacoes.avisarLimite(alertaLimite.mensagem!));
    }

    return _DadosInicio(
      usuario: usuario,
      resumo: resumo,
      recentes: recentes.take(4).toList(),
      alertaLimite: alertaLimite,
    );
  }

  void _atualizar() => setState(() => _dados = _carregarDados());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DadosInicio>(
      future: _dados,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
              child: CircularProgressIndicator(color: CoresApp.primary));
        }

        if (snapshot.hasError) {
          return Center(
            child: AvisoErroCarregamento(
              titulo: 'Não foi possível carregar o início',
              aoTentarNovamente: _atualizar,
            ),
          );
        }

        final dados = snapshot.data!;
        final resumo = dados.resumo;
        final pct = (resumo?.percentualUsado ?? 0) / 100;
        final corArco = pct < 0.5
            ? CoresApp.primary
            : pct < 0.8
                ? CoresApp.accent
                : CoresApp.accentWarm;

        final meses = [
          '',
          'Janeiro',
          'Fevereiro',
          'Março',
          'Abril',
          'Maio',
          'Junho',
          'Julho',
          'Agosto',
          'Setembro',
          'Outubro',
          'Novembro',
          'Dezembro'
        ];
        final now = DateTime.now();
        final rotuloMes = '${meses[now.month]} ${now.year}';

        return RefreshIndicator(
          onRefresh: () async => _atualizar(),
          color: CoresApp.primary,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _CartaoHero(
                  nomeUsuario:
                      dados.usuario?.nome.split(' ').first ?? '',
                  rotuloMes: rotuloMes,
                  pct: pct,
                  corArco: corArco,
                  totalCo2: resumo?.totalCo2Kg ?? 0,
                  limiteKg: resumo?.limiteKg ?? 200,
                  percentualUsado: resumo?.percentualUsado ?? 0,
                ),
              ),
              if (dados.alertaLimite?.ativo == true &&
                  dados.alertaLimite?.mensagem != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _BannerAlertaIA(
                        mensagem: dados.alertaLimite!.mensagem!),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _FileiraStat(resumo: resumo),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Últimas movimentações',
                    style: GoogleFonts.outfit(
                      fontSize: Tipografia.destaque,
                      fontWeight: FontWeight.w700,
                      color: CoresApp.textPrimary,
                    ),
                  ),
                ),
              ),
              if (dados.recentes.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
                  sliver: SliverToBoxAdapter(
                    child: EstadoVazioInicio(aoAtualizar: _atualizar),
                  ),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) =>
                          _ItemTransacao(transacao: dados.recentes[i]),
                      childCount: dados.recentes.length,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
                  sliver: SliverToBoxAdapter(
                    child: TextButton(
                      onPressed: widget.aoVerTransacoes,
                      style: TextButton.styleFrom(
                          foregroundColor: CoresApp.primary),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Ver todas as movimentações',
                            style: GoogleFonts.outfit(
                              fontSize: Tipografia.corpo,
                              fontWeight: FontWeight.w600,
                              color: CoresApp.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded,
                              size: 16, color: CoresApp.primary),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DadosInicio {
  final PerfilUsuario? usuario;
  final ResumoMensal? resumo;
  final List<ItemTransacao> recentes;
  final AlertaLimite? alertaLimite;

  _DadosInicio({
    required this.usuario,
    required this.resumo,
    required this.recentes,
    this.alertaLimite,
  });
}

class _CartaoHero extends StatelessWidget {
  final String nomeUsuario;
  final String rotuloMes;
  final double pct;
  final Color corArco;
  final double totalCo2;
  final double limiteKg;
  final double percentualUsado;

  const _CartaoHero({
    required this.nomeUsuario,
    required this.rotuloMes,
    required this.pct,
    required this.corArco,
    required this.totalCo2,
    required this.limiteKg,
    required this.percentualUsado,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: CoresApp.dark,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 24,
        left: 28,
        right: 28,
        bottom: 36,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nomeUsuario.isEmpty ? 'Olá' : 'Olá, $nomeUsuario',
                    style: GoogleFonts.outfit(
                      fontSize: Tipografia.tituloSecao,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    rotuloMes,
                    style: GoogleFonts.outfit(
                      fontSize: Tipografia.corpo,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
              Builder(
                builder: (ctx) => GestureDetector(
                  onTap: () => Scaffold.of(ctx).openDrawer(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.menu_rounded,
                        size: 22, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(180, 180),
                  painter: _PintorArco(
                      progresso: pct.clamp(0.0, 1.0), cor: corArco),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${percentualUsado.toStringAsFixed(1)}%',
                      style: GoogleFonts.outfit(
                        fontSize: Tipografia.numeroGrande,
                        fontWeight: FontWeight.bold,
                        color: corArco,
                      ),
                    ),
                    Text(
                      'do limite',
                      style: GoogleFonts.outfit(
                        fontSize: Tipografia.legenda,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '${totalCo2.toStringAsFixed(1)} kg CO2 usados',
            style: GoogleFonts.outfit(
              fontSize: Tipografia.destaque,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'de ${limiteKg.toStringAsFixed(0)} kg de limite mensal',
            style: GoogleFonts.outfit(
                fontSize: Tipografia.legenda, color: Colors.white54),
          ),
          if (percentualUsado > 100) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: CoresApp.accentWarm.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: CoresApp.accentWarm.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_rounded,
                      size: 14, color: CoresApp.accentWarm),
                  const SizedBox(width: 6),
                  Text(
                    'Limite ultrapassado!',
                    style: GoogleFonts.outfit(
                      fontSize: Tipografia.legenda,
                      fontWeight: FontWeight.w700,
                      color: CoresApp.accentWarm,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PintorArco extends CustomPainter {
  final double progresso;
  final Color cor;

  const _PintorArco({required this.progresso, required this.cor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;
    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..color = cor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    if (progresso > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle * progresso,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_PintorArco old) =>
      old.progresso != progresso || old.cor != cor;
}

class _FileiraStat extends StatelessWidget {
  final ResumoMensal? resumo;

  const _FileiraStat({required this.resumo});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Row(
      children: [
        Expanded(
          child: _CartaoStat(
            rotulo: 'Gastos no mês',
            valor: fmt.format(resumo?.totalGastoReais ?? 0),
            icone: Icons.payments_rounded,
            corIcone: CoresApp.accentWarm,
            corFundo: const Color(0xFFFFF8EC),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _CartaoStat(
            rotulo: 'Movimentações',
            valor: '${resumo?.quantidadeTransacoes ?? 0}',
            icone: Icons.swap_horiz_rounded,
            corIcone: CoresApp.primary,
            corFundo: CoresApp.primaryMuted.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }
}

class _CartaoStat extends StatelessWidget {
  final String rotulo;
  final String valor;
  final IconData icone;
  final Color corIcone;
  final Color corFundo;

  const _CartaoStat({
    required this.rotulo,
    required this.valor,
    required this.icone,
    required this.corIcone,
    required this.corFundo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CoresApp.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: corFundo,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icone, size: 20, color: corIcone),
          ),
          const SizedBox(height: 12),
          Text(
            valor,
            style: GoogleFonts.outfit(
              fontSize: Tipografia.subtitulo,
              fontWeight: FontWeight.bold,
              color: CoresApp.textPrimary,
            ),
          ),
          Text(
            rotulo,
            style: GoogleFonts.outfit(
              fontSize: Tipografia.legenda,
              color: CoresApp.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemTransacao extends StatelessWidget {
  final ItemTransacao transacao;

  const _ItemTransacao({required this.transacao});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TelaDetalheTransacao(
              transacao: transacao, tagIcone: 'inicio-${transacao.id}'),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: CoresApp.surface,
          borderRadius: BorderRadius.circular(14),
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
            Hero(
              tag: 'inicio-${transacao.id}',
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: CoresApp.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                    iconePorCategoria(transacao.rotuloCategoria),
                    size: 20,
                    color: CoresApp.gray),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transacao.nomeEstabelecimento.isEmpty
                        ? transacao.rotuloCategoria
                        : transacao.nomeEstabelecimento,
                    style: GoogleFonts.outfit(
                      fontSize: Tipografia.corpo,
                      fontWeight: FontWeight.w600,
                      color: CoresApp.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    transacao.rotuloCategoria,
                    style: GoogleFonts.outfit(
                      fontSize: Tipografia.legenda,
                      color: CoresApp.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  fmt.format(transacao.valor),
                  style: GoogleFonts.outfit(
                    fontSize: Tipografia.corpo,
                    fontWeight: FontWeight.w700,
                    color: CoresApp.textPrimary,
                  ),
                ),
                Text(
                  '${transacao.co2Kg.toStringAsFixed(1)} kg CO2',
                  style: GoogleFonts.outfit(
                    fontSize: Tipografia.minimo,
                    color: CoresApp.gray,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerAlertaIA extends StatelessWidget {
  final String mensagem;

  const _BannerAlertaIA({required this.mensagem});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CoresApp.accentWarm.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: CoresApp.accentWarm.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.eco_rounded,
              size: 22, color: CoresApp.accentWarm),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alerta de CO2 da IA',
                  style: GoogleFonts.outfit(
                    fontSize: Tipografia.corpo,
                    fontWeight: FontWeight.w700,
                    color: CoresApp.accentWarm,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mensagem,
                  style: GoogleFonts.outfit(
                    fontSize: Tipografia.corpo,
                    color: CoresApp.textPrimary,
                    height: 1.45,
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
