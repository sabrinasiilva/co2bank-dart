import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../nucleo/cores_app.dart';
import '../presentation/rewards/reward_service.dart';
import '../transacoes/servico/servico_transacao.dart';
import 'cartao_impacto.dart';
import 'grafico_evolucao_mensal.dart';

class AbaCo2 extends StatefulWidget {
  const AbaCo2({super.key});

  @override
  State<AbaCo2> createState() => _AbaCo2State();
}

class _AbaCo2State extends State<AbaCo2> {
  late int _mes;
  late int _ano;
  ResultadoResumoMensal? _resultado;
  bool _carregando = true;
  List<ResumoDoMes>? _historico;
  int? _coinsDoMes;

  @override
  void initState() {
    super.initState();
    final agora = DateTime.now();
    _mes = agora.month;
    _ano = agora.year;
    _carregarTudo();
  }

  Future<void> _carregarTudo() async {
    await Future.wait([
      _carregarResumo(),
      _carregarHistorico(),
      _carregarCoins(),
    ]);
  }

  Future<void> _carregarResumo() async {
    final mes = _mes;
    final ano = _ano;
    // Na primeira carga o _carregando já começa verdadeiro.
    if (_resultado != null) setState(() => _carregando = true);
    final servico = await ServicoTransacao.autenticado();
    final resultado = await servico.resumoMensal(mes: mes, ano: ano);
    // Se a pessoa trocou de mês enquanto carregava, ignora a resposta antiga.
    if (!mounted || mes != _mes || ano != _ano) return;
    setState(() {
      _resultado = resultado;
      _carregando = false;
    });
  }

  Future<void> _carregarHistorico() async {
    final agora = DateTime.now();
    final servico = await ServicoTransacao.autenticado();
    final historico = await servico.resumosDosUltimosMeses(
      mes: agora.month,
      ano: agora.year,
    );
    if (mounted) setState(() => _historico = historico);
  }

  Future<void> _carregarCoins() async {
    final servico = await RewardService.authenticated();
    final resultado = await servico.loadTokens();
    if (!mounted) return;
    if (resultado case TokensLoaded(:final summary)) {
      setState(() => _coinsDoMes = summary.earned);
    }
  }

  void _selecionarMes(int mes, int ano) {
    final agora = DateTime.now();
    if (DateTime(ano, mes).isAfter(DateTime(agora.year, agora.month))) return;
    if (mes == _mes && ano == _ano) return;
    setState(() {
      _mes = mes;
      _ano = ano;
    });
    _carregarResumo();
  }

  void _alterarMes(int delta) {
    final candidato = DateTime(_ano, _mes + delta);
    _selecionarMes(candidato.month, candidato.year);
  }

  @override
  Widget build(BuildContext context) {
    const meses = [
      '',
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];

    final agora = DateTime.now();
    final mesAtual = _mes == agora.month && _ano == agora.year;

    if (_resultado == null && _carregando) {
      return const SafeArea(
        child: Center(
          child: CircularProgressIndicator(color: CoresApp.primary),
        ),
      );
    }

    final ResumoMensal? resumo = switch (_resultado) {
      ResumoCarregado(:final resumo) => resumo,
      _ => null,
    };

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _carregarTudo,
        color: CoresApp.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Text(
                      'Relatório de CO2',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: CoresApp.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    _SeletorMes(
                      rotulo: '${meses[_mes]} $_ano',
                      aoAnterior: () => _alterarMes(-1),
                      aoProximo: mesAtual ? null : () => _alterarMes(1),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverToBoxAdapter(
                child: AnimatedOpacity(
                  opacity: _carregando ? 0.5 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: _CartaoResumo(resumo: resumo),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(
                child: CartaoEvolucaoMensal(
                  meses: _historico,
                  mesSelecionado: _mes,
                  anoSelecionado: _ano,
                  aoSelecionarMes: _selecionarMes,
                ),
              ),
            ),
            if (resumo != null && resumo.quantidadeTransacoes > 0)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: CartaoImpacto(
                    resumo: resumo,
                    coinsDoMes: mesAtual ? _coinsDoMes : null,
                  ),
                ),
              ),
            if (resumo != null && resumo.principaisCategorias.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Por categoria',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: CoresApp.textPrimary,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _FileiraCategorias(
                      categoria: resumo.principaisCategorias[i],
                      maxCo2: resumo.principaisCategorias.first.co2Kg,
                      posicao: i,
                    ),
                    childCount: resumo.principaisCategorias.length,
                  ),
                ),
              ),
            ] else
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _SeletorMes extends StatelessWidget {
  final String rotulo;
  final VoidCallback aoAnterior;
  final VoidCallback? aoProximo;

  const _SeletorMes({
    required this.rotulo,
    required this.aoAnterior,
    required this.aoProximo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CoresApp.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CoresApp.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 20),
            onPressed: aoAnterior,
            color: CoresApp.textSecondary,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
          Text(
            rotulo,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CoresApp.textPrimary,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: aoProximo != null
                  ? CoresApp.textSecondary
                  : CoresApp.border,
            ),
            onPressed: aoProximo,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class _CartaoResumo extends StatelessWidget {
  final ResumoMensal? resumo;

  const _CartaoResumo({required this.resumo});

  @override
  Widget build(BuildContext context) {
    final total = resumo?.totalCo2Kg ?? 0.0;
    final limite = resumo?.limiteKg ?? 200.0;
    final pct = resumo?.percentualUsado ?? 0.0;

    final Color corStatus;
    final String rotuloStatus;
    // O card é preto: as cores precisam aparecer bem sobre ele.
    if (pct < 50) {
      corStatus = CoresApp.primary;
      rotuloStatus = 'Ótimo';
    } else if (pct < 80) {
      corStatus = CoresApp.accent;
      rotuloStatus = 'Atenção';
    } else if (pct < 100) {
      corStatus = CoresApp.accentWarm;
      rotuloStatus = 'Limite alto';
    } else {
      corStatus = Colors.red.shade400;
      rotuloStatus = 'Ultrapassado';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: CoresApp.dark,
        borderRadius: BorderRadius.circular(20),
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
                    '${total.toStringAsFixed(1)} kg CO2',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'de ${limite.toStringAsFixed(0)} kg de limite',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: corStatus.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  rotuloStatus,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: corStatus,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (pct / 100).clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(corStatus),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (pct > 100)
                Row(
                  children: [
                    Icon(Icons.warning_rounded, size: 13, color: corStatus),
                    const SizedBox(width: 4),
                    Text(
                      'Limite ultrapassado!',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: corStatus,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )
              else
                const SizedBox(),
              Text(
                '${pct.toStringAsFixed(1)}% utilizado',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: corStatus,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FileiraCategorias extends StatelessWidget {
  final ResumoPorCategoria categoria;
  final double maxCo2;
  final int posicao;

  const _FileiraCategorias({
    required this.categoria,
    required this.maxCo2,
    required this.posicao,
  });

  @override
  Widget build(BuildContext context) {
    final pct = maxCo2 > 0 ? categoria.co2Kg / maxCo2 : 0.0;

    final Color corBarra;
    if (posicao == 0) {
      corBarra = CoresApp.orange;
    } else if (posicao == 1) {
      corBarra = CoresApp.mintGreen;
    } else {
      corBarra = CoresApp.dark;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                categoria.categoria,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: CoresApp.textPrimary,
                ),
              ),
              Text(
                '${categoria.co2Kg.toStringAsFixed(1)} kg',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: corBarra,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: CoresApp.background,
              valueColor: AlwaysStoppedAnimation<Color>(corBarra),
            ),
          ),
        ],
      ),
    );
  }
}
